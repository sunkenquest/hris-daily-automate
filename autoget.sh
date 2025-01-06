#!/bin/bash

# Service account credentials
if [[ -f .env ]]; then
    source .env
else
    echo ".env file not found!"
    exit 1
fi

JWT_HEADER=$(echo -n '{"alg":"RS256","typ":"JWT"}' | openssl base64 | tr -d '\n=' | tr '/+' '_-')

NOW=$(date +%s)
EXP=$(($NOW + 3600))
JWT_CLAIM=$(echo -n "{\"iss\":\"$CLIENT_EMAIL\",\"scope\":\"https://www.googleapis.com/auth/spreadsheets.readonly\",\"aud\":\"https://oauth2.googleapis.com/token\",\"exp\":$EXP,\"iat\":$NOW}" | openssl base64 | tr -d '\n=' | tr '/+' '_-')

PRIVATE_KEY_FILE=$(mktemp)
echo -e "$PRIVATE_KEY" > "$PRIVATE_KEY_FILE"

SIGNATURE=$(echo -n "$JWT_HEADER.$JWT_CLAIM" | openssl dgst -sha256 -sign "$PRIVATE_KEY_FILE" | openssl base64 | tr -d '\n=' | tr '/+' '_-')

rm "$PRIVATE_KEY_FILE"

JWT="$JWT_HEADER.$JWT_CLAIM.$SIGNATURE"

ACCESS_TOKEN=$(curl -s --request POST \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --data "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=$JWT" \
    https://oauth2.googleapis.com/token | jq -r .access_token)

RESPONSE=$(curl -s --request GET \
    "https://sheets.googleapis.com/v4/spreadsheets/$SHEET_ID/values/$RANGE?access_token=$ACCESS_TOKEN")

if [[ $(echo "$RESPONSE" | jq -r .error) != "null" ]]; then
    echo "Error in API response: $RESPONSE"
    exit 1
fi

VALUES=$(echo "$RESPONSE" | jq -r .values)

if [[ "$VALUES" == "null" || -z "$VALUES" ]]; then
    echo "No values found in the specified range."
    exit 1
else
    echo "Generated Summary:"
    
    BULLET_POINTS=$(echo "$VALUES" | jq -r '.[] | .[]' | sed '/^\s*$/d')

    echo "$BULLET_POINTS"
fi

if [[ ! -f ./data.txt ]]; then
    touch ./data.txt
fi

echo "$BULLET_POINTS" >> ./data.txt
echo "" >> ./data.txt 
echo "Values saved to data.txt."
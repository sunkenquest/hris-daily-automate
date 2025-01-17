import os
import time
from dotenv import load_dotenv
from selenium import webdriver
from selenium.webdriver.common.by import By

load_dotenv()

options = webdriver.ChromeOptions()
options.add_argument('--no-sandbox')  
options.add_argument('--disable-dev-shm-usage')  

driver = webdriver.Chrome(options=options)

driver.maximize_window()

driver.get("https://hris.hipe.asia")

time.sleep(2) 

email_field = driver.find_element(By.ID, "email")
email_field.send_keys(os.getenv("EMAIL"))

password_field = driver.find_element(By.ID, "password")
password_field.send_keys(os.getenv("PASSWORD"))

button = driver.find_element(By.TAG_NAME, "button")
button.click()

time.sleep(2) 

driver.get("https://hris.hipe.asia/daily/create")

time.sleep(2) 

with open('data.txt', 'r') as file:
    lines = file.readlines()

data_values = {str(i+10 if i > 2 else i+9): line.strip() for i, line in enumerate(lines) if line.strip()}

for textarea_id, value in data_values.items():
    try:
        textarea = driver.find_element(By.ID, textarea_id)
        textarea.clear() 
        textarea.send_keys(value)
    except Exception as e:
        print(f"Could not populate textarea with id '{textarea_id}': {e}")

time.sleep(600)

driver.quit()
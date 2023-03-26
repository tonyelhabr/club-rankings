#%%
import time
import pandas as pd
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from pathlib import Path
from datetime import datetime
from helpers import create_or_update_club_rankings_release

## TODO: Figure out a way to auto-detect this from the HTML text 
##   between the last 2 buttons on the page
MAX_PAGE_NUM = 3 # 137

#%%
chromedriver_path = 'chromedriver.exe'
chrome_options = Options()
chrome_options.add_argument('--headless')
#%%
driver = webdriver.Chrome(executable_path=chromedriver_path, options=chrome_options)

url = 'https://dataviz.theanalyst.com/opta-power-rankings/'
driver.get(url)
time.sleep(3)

#%%
soup = BeautifulSoup(driver.page_source, 'html.parser')
table = soup.find('table')
headers = [th.text.strip() for th in table.find_all('th')]

#%%
rows = []
page_num = 1

while page_num <= MAX_PAGE_NUM:
  print(f'Scraping page {page_num}')
  
  soup = BeautifulSoup(driver.page_source, 'html.parser')
  table = soup.find('table')

  for tr in table.find_all('tr'):
    row = [td.text.strip() for td in tr.find_all('td')]
    if row:
      rows.append(row)
  
  if page_num < MAX_PAGE_NUM:
    buttons = driver.find_elements(by = By.CSS_SELECTOR, value='button')
    last_button = buttons[-1]
    last_button.click()
      
  time.sleep(2)
  page_num += 1


#%%
driver.quit()

#%%
current_time = datetime.now()
formatted_timestamp = current_time.strftime('%Y-%m-%d %H:%M:%S')
today = current_time.strftime('%Y-%m-%d')

df = pd.DataFrame(rows, columns=headers)
df['date'] = today
df['updated_at'] = formatted_timestamp

#%%
data_dir = Path('data')
data_dir.mkdir(exist_ok=True)

file_path = data_dir / 'opta-club-rankings.csv'

#%%
df.to_csv(file_path, index=False)

#%%
df
#%%
create_or_update_club_rankings_release(file_path)


#%%

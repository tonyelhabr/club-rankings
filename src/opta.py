import time
import pandas as pd
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.common.by import By
import chromedriver_autoinstaller

## TODO: Figure out a way to auto-detect this from the HTML text 
##   between the last 2 buttons on the page
MAX_OPTA_PAGE_NUM = 137
OPTA_URL = 'https://dataviz.theanalyst.com/opta-power-rankings/'
  
def scrape_opta_club_rankings():
  chromedriver_autoinstaller.install()
  chrome_options = webdriver.ChromeOptions()    
  options = [
    '--headless',
  ]

  for option in options:
    chrome_options.add_argument(option)

  driver = webdriver.Chrome(options = chrome_options)

  driver.get(OPTA_URL)
  time.sleep(3)

  soup = BeautifulSoup(driver.page_source, 'html.parser')
  table = soup.find('table')
  headers = [th.text.strip() for th in table.find_all('th')]
  headers = headers + ['id']

  rows = []
  page_num = 1

  while page_num <= MAX_OPTA_PAGE_NUM:
    print(f'Scraping page {page_num}')
    
    soup = BeautifulSoup(driver.page_source, 'html.parser')
    table = soup.find('table')

    for tr in table.find_all('tr'):
      row = [td.text.strip() for td in tr.find_all('td')]
      img = tr.select_one('img')
      if img is None:
        img_id = ''
      else:
        img_id = img['src'].split('&id=')[-1]
      row.append(img_id)
      if row:
        rows.append(row)
    
    if page_num < MAX_OPTA_PAGE_NUM:
      buttons = driver.find_elements(by = By.CSS_SELECTOR, value='button')
      last_button = buttons[-1]
      last_button.click()
        
    time.sleep(2)
    page_num += 1

  #%%
  print('Done scraping Opta club rankings.')
  driver.quit()
  time.sleep(1)
  
  df = pd.DataFrame(rows, columns=headers)
  df.dropna(subset=['team'], inplace=True) ## Not really sure why, but the first row on the first page is empty
  return(df)
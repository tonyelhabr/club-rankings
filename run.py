#%%
import time
import pandas as pd
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from pathlib import Path
from datetime import date

#%%
chromedriver_path = "chromedriver.exe"
chrome_options = Options()
chrome_options.add_argument("--headless")
#%%
driver = webdriver.Chrome(executable_path=chromedriver_path, options=chrome_options)

url = "https://dataviz.theanalyst.com/opta-power-rankings/"
driver.get(url)
time.sleep(3)

#%%
soup = BeautifulSoup(driver.page_source, "html.parser")
table = soup.find("table")
headers = [th.text.strip() for th in table.find_all("th")]

#%%
rows = []
page_num = 1
MAX_PAGE_NUM = 137

while page_num <= MAX_PAGE_NUM:
  print(f"Scraping page {page_num}")
  
  soup = BeautifulSoup(driver.page_source, "html.parser")
  table = soup.find("table")

  for tr in table.find_all("tr"):
    row = [td.text.strip() for td in tr.find_all("td")]
    if row:
      rows.append(row)
  
  pd.DataFrame(rows, columns=headers).to_csv(f"data/{page_num}.csv", index=False)
  if page_num < MAX_PAGE_NUM:
    buttons = driver.find_elements(by = By.CSS_SELECTOR, value="button")
    last_button = buttons[-1]
    last_button.click()
      
  time.sleep(2)
  page_num += 1


#%%
driver.quit()

#%%
df = pd.DataFrame(rows, columns=headers)

today = date.today().strftime("%Y-%m-%d")
data_dir = Path("data")
data_dir.mkdir(exist_ok=True)
subdir = data_dir / today
subdir.mkdir(exist_ok=True)
csv_path = subdir / "rankings.csv"
df.to_csv(csv_path, index=False)
df.to_csv(data_dir / "rankings.csv", index=False)


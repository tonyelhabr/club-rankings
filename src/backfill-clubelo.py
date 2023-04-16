#%%
import pandas as pd
from utils import create_or_update_club_rankings_release, add_timestamp_cols
from datetime import date, datetime, timedelta

start_date = date(2023, 3, 27)
end_date = date(2023, 4, 16)
delta = timedelta(days=1)

dfs = []

#%%
while start_date <= end_date:
  date_str = datetime.strftime(start_date, "%Y-%m-%d")
  print(f'Scraping {date_str}')
  url = f'http://api.clubelo.com/{date_str}'
  df = pd.read_csv(url)
  df = add_timestamp_cols(df, current_time)
  # today = timestamp.strftime('%Y-%m-%d')
  current_time = datetime.now()
  formatted_timestamp = current_time.strftime('%Y-%m-%d %H:%M:%S')
  df['date'] = date_str
  df['updated_at'] = formatted_timestamp
  start_date += delta
  dfs.append(df)

dfs = pd.concat(dfs)

#%% 
create_or_update_club_rankings_release(
  df=dfs,
  file_name='clubelo-club-rankings.csv'
)

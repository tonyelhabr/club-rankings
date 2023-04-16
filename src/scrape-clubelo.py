#%%
import pandas as pd
from utils import create_or_update_club_rankings_release, add_timestamp_cols
from datetime import date, datetime, timedelta

start_date = date(2023, 3, 27)
end_date = date(2023, 3, 28) #  date(2023, 4, 16)
delta = timedelta(days=1)

#%%
url = f'http://api.clubelo.com/2023-03-27'
df = pd.read_csv(url)
current_time = datetime.now()
df = add_timestamp_cols(df, current_time)
create_or_update_club_rankings_release(
  df=df,
  file_name='clubelo-club-rankings.csv'
)

#%%
url = f'http://api.clubelo.com/2023-03-29'
df = pd.read_csv(url)
current_time = datetime.now()
df = add_timestamp_cols(df, current_time)

#%%
df = pd.read_csv('https://projects.fivethirtyeight.com/soccer-api/club/spi_global_rankings.csv')
current_time = datetime.now()
df = add_timestamp_cols(df, current_time)
# create_or_update_club_rankings_release(
#   df=df,
#   file_name='foo-club-rankings.csv'
# )

#%%
while start_date <= end_date:
    date_str = datetime.strftime(start_date, "%Y-%m-%d")
    print(f'Scraping {date_str}')
    current_time = datetime.now()
    clubelo_url = f'http://api.clubelo.com/{date_str}'
    clubelo_df = pd.read_csv(clubelo_url)
    clubelo_df = add_timestamp_cols(clubelo_df, current_time)
    # today = timestamp.strftime('%Y-%m-%d')
    formatted_timestamp = current_time.strftime('%Y-%m-%d %H:%M:%S')
    clubelo_df['date'] = date_str
    clubelo_df['updated_at'] = formatted_timestamp
    create_or_update_club_rankings_release(
      df=clubelo_df,
      file_name='clubelo-club-rankings.csv'
    )
    start_date += delta
#%%
import os
from github import Github
from github.GithubException import GithubException
import pandas as pd
import requests
from io import StringIO

repo_name = 'club-rankings'
tag = 'club-rankings'
description = 'Opta and 538 club rankings'
env_var_name = 'CLUB_RANKINGS_TOKEN'
file_name='foo-club-rankings.csv'

#%%
access_token = os.getenv(env_var_name)
gh = Github(access_token)
repo = gh.get_user().get_repo(repo_name)

release = None
for r in repo.get_releases():
  if r.tag_name == tag:
    release = r
    break
  
#%%
existing_data_file = None
for asset in release.get_assets():
  if asset.name == os.path.basename(file_name):
    existing_data_file = asset
    break
print(existing_data_file.browser_download_url)

#%%
response = requests.get(existing_data_file.browser_download_url)
existing_data = pd.read_csv(StringIO(response.text))
existing_data
#%%
combined_data = pd.concat([existing_data, df], ignore_index=True)
# combined_data = pd.concat([existing_data])
#%%
combined_data.drop_duplicates(inplace=True)

csv_file = StringIO()
combined_data.to_csv(csv_file, index=False)
file_content = csv_file.getvalue().encode()
#%%
file_content

#%%
# combined_data.to_csv(file_name, index=False)
# asset = release.upload_asset(
#   path=file_name,
#   label=file_name,
#   name=file_name
# )

#%%
try:
  asset = release.upload_asset_from_memory(
    file_like=file_content,
    file_size=len(file_content),
    name=file_name
  )
  print(f'File uploaded: {asset.name}')
except GithubException as e:
  print(f'Error uploading file: {e}')
#%%

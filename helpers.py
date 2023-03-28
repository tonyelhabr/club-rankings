#%%
import os
from github import Github
from github.GithubException import GithubException
import pandas as pd
import requests
from io import StringIO

REPO_NAME = 'club-rankings'
RELEASE_TAG = 'club-rankings'
RELEASE_DESCRIPTION = 'Opta and 538 club rankings'
GITHUB_ACCESS_TOKEN_ENV_VAR_NAME = 'CLUB_RANKINGS_TOKEN'

#%%
def create_or_update_release(df, file_name, repo_name, tag='v1.0.0', description='Description of release'):
  
  if not isinstance(df, pd.DataFrame):
    raise Exception('`df` should be a `DataFrame`')
  
  access_token = os.getenv(GITHUB_ACCESS_TOKEN_ENV_VAR_NAME)
  gh = Github(access_token)
  repo = gh.get_user().get_repo(repo_name)
  
  release = None
  for r in repo.get_releases():
    if r.tag_name == tag:
      release = r
      break

  if release is None:
    try:
      release = repo.create_git_release(
        tag=tag, 
        name=tag, 
        message=description
      )
      print(f'New release created: {release.tag_name}')
    except GithubException as e:
      print(f'Error creating release: {e}')
      return
  else:
    try:      
      existing_data_file = None
      for asset in release.get_assets():
        if asset.name == os.path.basename(file_name):
          existing_data_file = asset
          break
        
      if existing_data_file:
        print('Combining new data with data existing in release.')
        response = requests.get(existing_data_file.browser_download_url)
        existing_data = pd.read_csv(StringIO(response.text))
        combined_data = pd.concat([existing_data, df], ignore_index=True)
        existing_data_file.delete_asset()
      else:
        print('No existing data in release. Uploading new data.')
        combined_data = df
      
      combined_data.drop_duplicates(inplace=True)
      
      csv_file = StringIO()
      combined_data.to_csv(csv_file, index=False)
      file_content = csv_file.getvalue().encode()
      
    except GithubException as e:
      print(f'Error updating release: {e}')
      return
    
  try:
    asset = release.upload_asset_from_memory(
      file_like=file_content,
      file_size=len(file_content),
      name=file_name,
    )
    print(f'File uploaded: {asset.name}')
  except GithubException as e:
    print(f'Error uploading file: {e}')

def create_or_update_club_rankings_release(df, file_name, repo_name=REPO_NAME, tag=RELEASE_TAG, description=RELEASE_DESCRIPTION):
  create_or_update_release(
    df=df,
    file_name=file_name,
    repo_name=repo_name,
    tag=tag,
    description=description
  )
#%%

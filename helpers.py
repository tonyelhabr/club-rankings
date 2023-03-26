#%%
import os
from github import Github
from github.GithubException import GithubException
import pandas as pd
import requests
from io import StringIO

REPO_NAME = "club-rankings"
RELEASE_TAG = "club-rankings"
RELEASE_DESCRIPTION = "Opta and 538 club rankings"
GITHUB_ACCESS_TOKEN_ENV_VAR_NAME = "GITHUB_ACCESS_TOKEN"

#%%
def create_or_update_release(file_path, tag=RELEASE_TAG, description=RELEASE_DESCRIPTION):
  access_token = os.getenv(GITHUB_ACCESS_TOKEN_ENV_VAR_NAME)
  gh = Github(access_token)
  repo = gh.get_user().get_repo(REPO_NAME)
  
  # Check if a release with the incremented tag exists
  release = None
  for r in repo.get_releases():
    if r.tag_name == tag:
      release = r
      break

  if release is None:
    try:
      # Create a new release
      release = repo.create_git_release(
        tag=tag, 
        name=file_path.stem, 
        message=description
      )
      print(f"New release created: {release.tag_name}")
    except GithubException as e:
      print(f"Error creating release: {e}")
      return
  else:
    try:
      release.update_release(
        name=file_path.stem,
        message=description
      )
      print(f"Existing release updated: {release.tag_name}")
      
      # Download the existing data file from the release assets
      existing_data_file = None
      for asset in release.get_assets():
        if asset.name == os.path.basename(file_path):
          existing_data_file = asset
          break
        
      if existing_data_file:
        response = requests.get(existing_data_file.browser_download_url)
        existing_data = pd.read_csv(StringIO(response.text))
        new_data = pd.read_csv(file_path)
        combined_data = existing_data.append(new_data, ignore_index=True)
        combined_data.to_csv(file_path, index=False)
        existing_data_file.delete_asset()
      
    except GithubException as e:
      print(f"Error updating release: {e}")
      return
    
  try:
    with open(file_path, "rb") as file:
      asset = release.upload_asset(
        content_type="text/csv",
        name=file_path.stem,
        path=file_path
      )
      print(f"File uploaded: {asset.name}")
  except GithubException as e:
    print(f"Error uploading file: {e}")


#%%

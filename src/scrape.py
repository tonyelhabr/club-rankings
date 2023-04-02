import pandas as pd
from datetime import datetime
from utils import create_or_update_club_rankings_release, add_timestamp_cols
from opta import scrape_opta_club_rankings

current_time = datetime.now()
opta_df = scrape_opta_club_rankings()
opta_df = add_timestamp_cols(opta_df, current_time)

create_or_update_club_rankings_release(
  df=opta_df,
  file_name='opta-club-rankings.csv'
)

ft8_df = pd.read_csv('https://projects.fivethirtyeight.com/soccer-api/club/spi_global_rankings.csv')
ft8_df = add_timestamp_cols(ft8_df, current_time)
create_or_update_club_rankings_release(
  df=ft8_df,
  file_name='fivethirtyeight-club-rankings.csv'
)

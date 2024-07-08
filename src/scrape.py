import pandas as pd
from datetime import datetime
from utils import create_or_update_club_rankings_release, add_timestamp_cols
from opta import scrape_opta_club_rankings

current_time = datetime.now()
opta_df = scrape_opta_club_rankings()
opta_df = add_timestamp_cols(opta_df, current_time)

create_or_update_club_rankings_release(df=opta_df, file_name="opta-club-rankings.csv")

clubelo_date_str = datetime.strftime(datetime.today(), "%Y-%m-%d")
clubelo_url = f"http://api.clubelo.com/{clubelo_date_str}"
clubelo_df = pd.read_csv(clubelo_url)
clubelo_df = add_timestamp_cols(clubelo_df, current_time)
create_or_update_club_rankings_release(
    df=clubelo_df, file_name="clubelo-club-rankings.csv"
)

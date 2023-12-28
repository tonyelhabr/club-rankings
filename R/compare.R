library(rlang)
library(purrr)
library(readr)
library(dplyr)
library(tidyr)
library(piggyback)

read_rankings_release <- function(x) {
  read_csv(
    sprintf('https://github.com/tonyelhabr/club-rankings/releases/download/club-rankings/%s-club-rankings.csv', x),
    show_col_types = FALSE
  )
}

select_ranking_cols <- function(df, ...) {
  df |> 
    select(
      ...,
      date,
      updated_at
    )
}

slice_latest_rankings_on_date <- function(df) {
  df |> 
    group_by(date) |> 
    slice_max(updated_at, n = 1, with_ties = TRUE) |> 
    ungroup() |> 
    select(-updated_at)
}

opta_rankings <- read_rankings_release('opta') |> 
  select_ranking_cols(
    id_opta = id,
    team_opta = team,
    rating_opta = rating,
    rank_opta = rank
  ) |> 
  slice_latest_rankings_on_date()

clubelo_rankings <- read_rankings_release('clubelo') |> 
  select_ranking_cols(
    team_clubelo = Club,
    rating_clubelo = Elo,
    rank_clubelo = Rank
  ) |> 
  group_by(date, updated_at) |> 
  mutate(
    rank_clubelo = row_number(desc(rating_clubelo)),
    .before = 1
  ) |> 
  ungroup() |> 
  slice_latest_rankings_on_date()

mapping <- read_csv('team-mapping.csv') |> 
  filter(n_opta == 1) |> ## TODO: fix some amibuous teams with n_opta > 1L
  select(
    country,
    id_opta,
    team_opta,
    team_clubelo
  )

compared_rankings <- mapping |> 
  left_join(
    opta_rankings |> 
      select(
        date,
        id_opta,
        rank_opta,
        rating_opta
      ),
    by = join_by(id_opta),
    relationship = 'many-to-many'
  ) |> 
  left_join(
    clubelo_rankings,
    by = join_by(team_clubelo, date)
  ) |> 
  select(
    date,
    country,
    id_opta,
    team_opta,
    team_clubelo,
    rating_opta,
    rating_clubelo,
    rank_opta,
    rank_clubelo
  )

## Upload
temp_dir <- tempdir(check = TRUE)
temp_path <- file.path(temp_dir, 'compared-rankings.csv')
write_csv(compared_rankings, temp_path, na = '')
pb_upload(
  temp_path,
  repo = 'tonyelhabr/club-rankings',
  tag = 'club-rankings'
)

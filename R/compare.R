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
    rank_opta = rank,
    team_opta = team,
    rating_opta = rating,
    id_opta = id
  ) |> 
  slice_latest_rankings_on_date()

fivethirtyeight_rankings <- read_rankings_release('fivethirtyeight') |> 
  select_ranking_cols(
    rank_538 = rank,
    team_538 = name,
    rating_538 = spi,
    league_538 = league
  ) |> 
  slice_latest_rankings_on_date()

clubelo_rankings <- read_rankings_release('clubelo') |> 
  select_ranking_cols(
    rank_clubelo = Rank,
    team_clubelo = Club,
    country_clubelo = Country,
    level_clubelo = Level,
    rating_clubelo = Elo
  ) |> 
  group_by(date, updated_at) |> 
  mutate(
    rank_clubelo = row_number(desc(rating_clubelo)),
    .before = 1
  ) |> 
  ungroup() |> 
  mutate(
    league_clubelo = sprintf('%s-%s', country_clubelo, level_clubelo),
    .keep = 'unused',
    .before = team_clubelo
  ) |> 
  slice_latest_rankings_on_date()

mapping <- read_csv('team-mapping.csv') |> 
  filter(!is.na(id_opta)) |> ## NAs for id_opta only for Chinese Super League
  # filter(league_538 != 'Chinese Super League') |> 
  select(
    league_538, ## don't technically need this for joining since team_538 is unique
    league_538_alternative,
    league_clubelo,
    team_538,
    id_opta,
    team_clubelo
  )

compared_rankings <- mapping |> 
  left_join(
    fivethirtyeight_rankings,
    by = join_by(league_538, team_538)
  ) |> 
  left_join(
    opta_rankings,
    by = join_by(id_opta, date)
  ) |> 
  left_join(
    clubelo_rankings,
    by = join_by(league_clubelo, team_clubelo, date)
  )

write_club_rankings_release <- function(x, name) {
  temp_dir <- tempdir(check = TRUE)
  basename <- sprintf('%s.csv', name)
  temp_path <- file.path(temp_dir, basename)
  write_csv(x, temp_path, na = '')
  pb_upload(
    temp_path,
    repo = 'tonyelhabr/club-rankings',
    tag = 'club-rankings'
  )
}

write_club_rankings_release(
  compared_rankings,
  name = 'compared-rankings'
)

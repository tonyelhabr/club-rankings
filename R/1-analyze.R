library(rlang)
library(purrr)
library(readr)
library(glue)
library(dplyr)
library(openssl)

club_rankings <- c(
  'opta',
  'fivethirtyeight'
) |> 
  set_names() |> 
  imap_dfr(
    ~{
      constant_cols <- c('rank', 'date', 'updated_at')
      cols <- switch(
        .x,
        'opta' = c(
          'team',
          'rating',
          'id'
        ),
        'fivethirtyeight' = c(
          'team' = 'name',
          'rating' = 'spi',
          'league'
        )
      )
      
      read_csv(
        glue('https://github.com/tonyelhabr/club-rankings/releases/download/club-rankings/{.x}-club-rankings.csv'),
        show_col_types = FALSE
      ) |> 
        select(!!!c(constant_cols, cols))
    },
    .id = 'source'
  ) |> 
  group_by(source, date) |> 
  slice_max(updated_at, n = 1, with_ties = TRUE) |> 
  ungroup() |> 
  select(
    source,
    date,
    league,
    team,
    id,
    rank,
    rating
  ) |> 
  arrange(
    source,
    date,
    rank
  )

club_rankings$id <- ifelse(
  is.na(club_rankings$id),
  openssl::md5(club_rankings$team),
  club_rankings$id
)

mapping <- read_csv('team-mapping.csv', na = '') |> 
  # filter(!is.na(id_opta)) |> ## NAs for id_opta only for Chinese Super League
  filter(league_538 != 'Chinese Super League') |> 
  select(
    league_538, ## don't technically need this for joining since team_538 is unique
    team_538,
    id_opta
  )

latest_club_rankings <- all_club_rankings |> 
  filter(date == '2023-04-01') |> 
  group_by(source) |> 
  slice_max(updated_at, n = 1, with_ties = TRUE) |> 
  ungroup()

rankings_538 <- latest_club_rankings |> 
  filter(source == 'fivethirtyeight') |> 
  select(
    date,
    rank,
    league,
    team,
    id,
    rating
  ) |> 
  rename_with(~sprintf('%s_538', .x), -c(date)) |> 
  inner_join(
    mapping,
    by = join_by(team_538, league_538)
  )

rankings_opta <- latest_club_rankings |> 
  filter(source == 'opta') |> 
  select(
    date,
    rank,
    team,
    id,
    rank,
    rating
  ) |> 
  rename_with(~sprintf('%s_opta', .x), -c(date))

inner_join(
  rankings_538,
  rankings_opta,
  by = join_by(date, id_opta)
) |> 
  select(
    date,
    rank_538,
    rank_opta,
    league_538,
    team_538,
    team_opta
  )

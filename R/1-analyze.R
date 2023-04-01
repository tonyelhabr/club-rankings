library(rlang)
library(purrr)
library(readr)
library(dplyr)
library(tidyr)

rankings <- c(
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
        sprintf('https://github.com/tonyelhabr/club-rankings/releases/download/club-rankings/%s-club-rankings.csv', .x),
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

mapping <- read_csv('team-mapping.csv', na = '') |> 
  # filter(!is.na(id_opta)) |> ## NAs for id_opta only for Chinese Super League
  filter(league_538 != 'Chinese Super League') |> 
  select(
    league_538, ## don't technically need this for joining since team_538 is unique
    team_538,
    id_opta
  )

latest_rankings <- rankings |> filter(date == '2023-04-01')

reformatted_latest_rankings <- bind_rows(
  latest_rankings |> 
    filter(source == 'fivethirtyeight') |> 
    inner_join(
      mapping,
      by = join_by(league == league_538, team == team_538)
    ) |> 
    mutate(
      id = id_opta,
      .keep = 'unused'
    ),
  latest_rankings |> 
    filter(source == 'opta') |> 
    inner_join(
      mapping,
      by = join_by(id == id_opta)
    ) |> 
    mutate(
      league = league_538,
      team = team_538,
      .keep = 'unused'
    )
) |> 
  transmute(
    team, ## 538
    league, ## 538
    # id, ## opta
    across(source, ~ifelse(.x == 'fivethirtyeight', '538', .x)),
    rank
  )

compared_latest_rankings <- reformatted_latest_rankings |> 
  pivot_wider(
    names_from = source,
    values_from = rank,
    names_prefix = 'rank_'
  ) |> 
  arrange(rank_538)

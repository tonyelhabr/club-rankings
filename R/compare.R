library(rlang)
library(purrr)
library(readr)
library(dplyr)
library(tidyr)
library(piggyback)

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
  filter(!is.na(id_opta)) |> ## NAs for id_opta only for Chinese Super League
  # filter(league_538 != 'Chinese Super League') |> 
  select(
    league_538, ## don't technically need this for joining since team_538 is unique
    team_538,
    id_opta
  )

reformatted_rankings <- bind_rows(
  rankings |> 
    filter(source == 'fivethirtyeight') |> 
    inner_join(
      mapping,
      by = join_by(league == league_538, team == team_538)
    ) |> 
    mutate(
      id = id_opta,
      .keep = 'unused'
    ),
  rankings |> 
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
    date,
    team_538 = team,
    league_538 = league,
    id_opta = id,
    across(source, ~ifelse(.x == 'fivethirtyeight', '538', .x)),
    rank,
    rating
  )

compared_rankings <- reformatted_rankings |> 
  pivot_wider(
    names_from = source,
    values_from = c(rank, rating)
  ) |> 
  arrange(date, league_538, team_538)

write_club_rankings <- function(x, name, tag = 'club-rankings') {
  temp_dir <- tempdir(check = TRUE)
  basename <- sprintf('%s.csv', name)
  temp_path <- file.path(temp_dir, basename)
  f <- function(x, path) {
    write_csv(x, path, na = '')
  }
  write_csv(compared_rankings, temp_path, na = '')
  pb_upload(
    temp_path,
    repo = 'tonyelhabr/club-rankings',
    tag = 'club-rankings'
  )
}

write_club_rankings(
  compared_rankings,
  name = 'compared-rankings'
)

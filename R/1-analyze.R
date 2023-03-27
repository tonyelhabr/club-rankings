library(rlang)
library(purrr)
library(readr)
library(glue)
library(dplyr)

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
          'rating'
        ),
        'fivethirtyeight' = c(
          'team' = 'name',
          'rating' = 'spi'
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
    rank,
    team,
    rating
  ) |> 
  arrange(
    source,
    date,
    rank
  )

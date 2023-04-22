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
      constant_cols <- c('date', 'updated_at')
      cols <- switch(
        .x,
        'opta' = c(
          'rank',
          'team',
          'rating',
          'id'
        ),
        'fivethirtyeight' = c(
          'rank',
          'team' = 'name',
          'rating' = 'spi',
          'league'
        ),
        'clubelo' = c(
          'rank' = 'Rank',
          'team' = 'Club',
          'country' = 'Country',
          'level' = 'Level',
          'rating' = 'Elo'
        )
      )
      
      res <- read_csv(
        sprintf('https://github.com/tonyelhabr/club-rankings/releases/download/club-rankings/%s-club-rankings.csv', .x),
        show_col_types = FALSE
      ) |> 
        select(!!!c(constant_cols, cols))
      
      if (.x != 'clubelo') {
        return(res)
      }
      
      res |> 
        group_by(date, updated_at) |> 
        mutate(
          rank = row_number(desc(rating))
        ) |> 
        ungroup() |> 
        mutate(
          league = sprintf('%s-%s', country, level),
          .keep = 'unused'
        )
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

library(readr)
res <- read_csv(
  'https://github.com/tonyelhabr/club-rankings/releases/download/club-rankings/clubelo-club-rankings.csv',
  show_col_types = FALSE
) |> 
  select(
    c(
      c(
        'rank' = 'Rank',
        'team' = 'Club',
        'country' = 'Country',
        'level' = 'Level',
        'rating' = 'Elo'
      ),
      c('date', 'updated_at')
    )
  )



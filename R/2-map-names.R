library(rlang)
library(purrr)
library(readr)
library(glue)
library(dplyr)
library(tidytext)
library(stringr)
library(tidyr)

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
  filter(date == '2023-03-30') |> 
  group_by(source, team) |> 
  slice_max(updated_at, n = 1, with_ties = TRUE) |> 
  ungroup() |> 
  select(
    date,
    updated_at,
    source,
    league,
    team,
    rating,
    rank
  )
club_rankings |> count(source)

indistinguishable_team_names <- clean_team_names |> 
  count(source, team) |> 
  filter(n > 1L)

clean_team_names |> 
  inner_join(
    indistinguishable_team_names,
    by = join_by(source, team)
  ) |> 
  group_by(source, team, n) |> 
  summarize(
    across(
      rating,
      list(min = min, max = max),
      .names = '{fn}_rating'
    )
  ) |> 
  ungroup() |> 
  arrange(source, desc(max_rating))


data('stop_words', package = 'tidytext')
snowball_stop_words <- stop_words |> 
  filter(lexicon == 'snowball') |> 
  pull(word)

clean_team_names <- club_rankings |> 
  mutate(
    rn = row_number(),
    new_team = team |> 
      tolower() |> 
      str_replace_all('-', ' ') |> 
      str_remove_all("'") |> 
      str_remove_all('^[0-9]+[.]\\s') |> 
      iconv( to = 'ASCII//TRANSLIT')
  ) |> 
  unnest_tokens('token', new_team, drop = FALSE) |> 
  filter(!(token %in% snowball_stop_words)) |> 
  group_by(source, team, rating, rn) |> 
  summarize(
    new_team = paste(token, collapse = ' ')
  ) |> 
  ungroup() |> 
  group_by(source) |> 
  mutate(
    # rating = (rating - min(rating)) / (max(rating) - min(rating))
    rating = percent_rank(rating)
  ) |> 
  ungroup() |> 
  arrange(source, desc(rating))
clean_team_names


anti_join(
  club_rankings |> select(source, team),
  clean_team_names |> select(source, team),
  by = join_by(source, team)
)

filt_team_names <- clean_team_names |> 
  filter(
    source == 'fivethirtyeight' |
    (source == 'opta' & rating > 0.55)
  )
filt_team_names |> count(source, new_team) |> filter(n > 1L)

exact_matches <- inner_join(
  filt_team_names |> filter(source == 'fivethirtyeight') |> select(new_team),
  filt_team_names |> filter(source == 'opta') |> select(new_team),
  by = join_by(new_team)
)


filt_team_names |> 
  select(source, new_team) |> 
  pivot_wider(
    names_from = source,
    values_from = new_team
  )

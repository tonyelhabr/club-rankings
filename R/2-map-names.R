library(rlang)
library(purrr)
library(readr)
library(glue)
library(dplyr)
library(tidytext)
library(stringr)
library(tidyr)
library(openssl)
library(tibble)
library(tidystringdist)

all_club_rankings <- c(
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
        filter(!is.na(rank)) |> 
        select(!!!c(constant_cols, cols))
    },
    .id = 'source'
  )
## this is just needed for fivethirtyeight
all_club_rankings$id <- ifelse(
  is.na(all_club_rankings$id),
  openssl::md5(all_club_rankings$team),
  all_club_rankings$id
)

latest_club_rankings <- all_club_rankings |> 
  group_by(source) |> 
  slice_max(updated_at, n = 1, with_ties = TRUE) |> 
  ungroup()

data('stop_words', package = 'tidytext')
snowball_stop_words <- stop_words |> 
  filter(lexicon == 'snowball') |> 
  pull(word)

clean_team_names <- latest_club_rankings |> 
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
  group_by(across(-all_of('token'))) |> 
  summarize(
    new_team = paste(token, collapse = ' ')
  ) |> 
  ungroup() |> 
  group_by(source) |> 
  mutate(
    # rating = (rating - min(rating)) / (max(rating) - min(rating))
    prank = percent_rank(desc(rank))
  ) |> 
  ungroup() |> 
  arrange(source, desc(prank))
clean_team_names

filt_team_names <- clean_team_names |> 
  filter(
    source == 'fivethirtyeight' |
      (source == 'opta' & prank > 0.55)
  )
filt_team_names |> count(source, new_team) |> filter(n > 1L)

exact_matches <- filt_team_names |> 
  group_by(source, new_team) |> 
  filter(n() == 1L) |> 
  ungroup() |> 
  select(source, new_team) |> 
  count(new_team) |> 
  filter(n == 2L)
exact_matches

filt_team_names |> filter(new_team == 'aab')
clean_fivethirtyeight_team_names <- filt_team_names |> 
  filter(source == 'fivethirtyeight') |> 
  transmute(
    new_team,
    fivethirtyeight_rank = rank,
    fivethirtyeight_league = league,
    fivethirtyeight_new_team = new_team,
    fivethirtyeight_id = id
  )

clean_opta_team_names <- filt_team_names |> 
  filter(source == 'opta') |> 
  transmute(
    new_team,
    opta_rank = rank,
    opta_new_team = new_team,
    opta_id = id
  )

init_matches <- clean_fivethirtyeight_team_names |> 
  left_join(
    clean_opta_team_names |> 
      semi_join(
        exact_matches,
        by = join_by(new_team)
      ) |> 
      mutate(
        is_exact = TRUE
      ),
    by = join_by(new_team)
  ) |> 
  mutate(
    across(is_exact, \(x) replace_na(x, FALSE))
  )
init_matches |> write_csv('matches.csv', na = '')

fivethirtyeight_names_to_matches <- init_matches |> 
  filter(is.na(opta_id))

opta_candidates <- clean_opta_team_names |> 
  anti_join(
    exact_matches |> select(new_team),
    by = join_by(new_team)
  ) |> 
  select(opta_id, opta_new_team) |> 
  inner_join(
    latest_club_rankings |> 
      filter(source == 'opta') |> 
      select(opta_id = id, opta_rank = rank),
    by = join_by(opta_id)
  ) |> 
  cross_join(
    fivethirtyeight_names_to_matches |> 
      select(
        fivethirtyeight_id,
        fivethirtyeight_new_team
      )
  ) |> 
  inner_join(
    latest_club_rankings |> 
      filter(source == 'fivethirtyeight') |> 
      select(fivethirtyeight_id = id, fivethirtyeight_rank = rank),
    by = join_by(fivethirtyeight_id)
  )

string_dists <- opta_candidates |> 
  tidystringdist::tidy_stringdist(
    opta_new_team, 
    fivethirtyeight_new_team,
    method = c('cosine', 'jaccard')
  ) |> 
  remove_rownames() |> 
  group_by(fivethirtyeight_new_team) |> 
  mutate(
    dstring = cosine + jaccard,
    drank = opta_rank - fivethirtyeight_rank,
    drank_prank = (drank - min(drank)) / (max(drank) - min(drank))
  ) |> 
  ungroup()

# team <- ''
# abbrv <- str_remove(team, '[a-z]{2,3}\\s+|\\s+[a-z]{2,3}') |> str_squish() |> str_sub(1, 5)
# closest_strings |> filter(fivethirtyeight_new_team == .env$team)
# string_dists |> filter(fivethirtyeight_new_team == .env$team) |> filter((0.9 * opta_rank) > fivethirtyeight_rank) |> arrange(dstring)
# string_dists |> distinct(opta_id, opta_rank, opta_new_team) |> filter(opta_new_team |> str_detect(abbrv))
# string_dists |> distinct(opta_id, opta_rank, opta_new_team) |> filter(opta_new_team |> str_detect('san antonio'))

closest_strings <- string_dists |> 
  group_by(fivethirtyeight_new_team) |> 
  slice_min(dstring, n = 1) |> 
  slice_min(drank, n = 1, with_ties = FALSE) |> 
  ungroup()

inverse_closest_strings <- string_dists |> 
  group_by(opta_new_team) |> 
  slice_min(dstring, n = 1) |> 
  slice_min(drank, n = 1, with_ties = FALSE) |> 
  ungroup()

agreeing_closest_strings <- inner_join(
  closest_strings |> select(-c(cosine, jaccard)),
  inverse_closest_strings |> select(opta_id, fivethirtyeight_id),
  by = join_by(opta_id, fivethirtyeight_id)
) |> 
  arrange(fivethirtyeight_rank)

closest_ranks <- string_dists |> 
  group_by(fivethirtyeight_new_team) |> 
  slice_min(dstring, n = 10) |> 
  slice_min(drank, n = 1, with_ties = FALSE) |> 
  ungroup()
closest_ranks


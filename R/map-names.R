library(rlang)
library(purrr)
library(readr)
library(glue)
library(dplyr)
library(tidytext)
library(stringr)
library(tidyr)
library(tibble)
library(tidystringdist)

latest_rankings_clubelo <- read_csv(
 'https://github.com/tonyelhabr/club-rankings/releases/download/club-rankings/clubelo-club-rankings.csv',
) |> 
  slice_max(updated_at, n = 1, with_ties = TRUE) |> 
  transmute(
    team_clubelo = Club,
    league_clubelo = sprintf('%s-%s', Country, Level),
    rank_clubelo = row_number(desc(Elo))
  )
latest_rankings_clubelo |> distinct(league_clubelo) |> arrange(league_clubelo) |> write_csv('leagues-clubelo.csv')

latest_rankings_opta <- read_csv(
  'https://github.com/tonyelhabr/club-rankings/releases/download/club-rankings/opta-club-rankings.csv'
) |> 
  slice_max(updated_at, n = 1, with_ties = TRUE)

latest_compared_rankings <- read_csv(
  'https://github.com/tonyelhabr/club-rankings/releases/download/club-rankings/compared-rankings.csv'
) |> 
  slice_max(date, n = 1, with_ties = TRUE)

league_mapping <- read_csv('league-mapping.csv')

team_mapping <- read_csv('team-mapping.csv')
base <- latest_compared_rankings |> 
  select(
    team_538,
    league_538,
    id_opta,
    rank_538,
    rank_opta
  ) |> 
  inner_join(
    latest_rankings_opta |> select(team_opta = team, id_opta = id),
    by = join_by(id_opta)
  ) |> 
  select(
    team_538,
    team_opta,
    league_538,
    rank_538,
    rank_opta
  )

latest_club_rankings <- bind_rows(
  base |> 
    pivot_longer(
      -c(league_538, starts_with('rank')), 
      names_to = 'source1',
      values_to = 'team'
    ) |> 
    pivot_longer(
      -c(league_538, source1, team), 
      names_to = 'source2',
      values_to = 'rank'
    ) |> 
    mutate(
      across(source1, \(x) str_remove(x, 'team_')),
      across(source2, \(x) str_remove(x, 'rank_'))
    ) |> 
    filter(source1 == source2) |> 
    select(-source2) |> 
    rename(
      source = source1
    ),
  latest_rankings_clubelo |> 
    inner_join(
      league_mapping
    ) |> 
    transmute(
      league = league_clubelo,
      league_538,
      source = 'clubelo',
      team = team_clubelo,
      rank = rank_clubelo
    )
)

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
  mutate(
    token = SnowballC::wordStem(token)
  ) |> 
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

## beware of arsenal if comparing to opta data set
clean_team_names |> count(source, new_team) |> filter(n > 1L)

exact_matches <- clean_team_names |> 
  group_by(source, new_team) |> 
  filter(n() == 1L) |> 
  ungroup() |> 
  select(source, new_team) |> 
  count(new_team) |> 
  filter(n == 2L)
exact_matches

clean_team_names_538 <- clean_team_names |> 
  filter(source == '538') |> 
  transmute(
    new_team,
    rank_538 = rank,
    league_538 = league,
    team_538 = team,
    new_team_538 = new_team
  )

clean_team_names_clubelo <- clean_team_names |> 
  filter(source == 'clubelo') |> 
  transmute(
    new_team,
    rank_clubelo = rank,
    team_clubelo = team,
    new_team_clubelo = new_team
  )

init_matches_538 <- clean_team_names_538 |> 
  left_join(
    clean_team_names_clubelo |> 
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

init_matches_538 |> write_csv('matches.csv', na = '')

names_to_matches_538 <- init_matches_538 |> 
  filter(is.na(new_team_clubelo))

candidates_clubelo <- clean_team_names_clubelo |> 
  anti_join(
    exact_matches |> select(new_team),
    by = join_by(new_team)
  ) |> 
  select(team_clubelo, new_team_clubelo) |> 
  inner_join(
    latest_club_rankings |> 
      filter(source == 'clubelo') |> 
      select(team_clubelo = team, rank_clubelo = rank),
    by = join_by(team_clubelo)
  ) |> 
  cross_join(
    names_to_matches_538 |> 
      select(
        team_538,
        new_team_538
      )
  ) |> 
  inner_join(
    latest_club_rankings |> 
      filter(source == '538') |> 
      select(team_538 = team, rank_538 = rank),
    by = join_by(team_538)
  ) |> 
  select(-c(team_clubelo, team_538))

string_dists <- candidates_clubelo |> 
  tidystringdist::tidy_stringdist(
    new_team_clubelo, 
    new_team_538,
    method = c('cosine', 'jaccard')
  ) |> 
  remove_rownames() |> 
  group_by(new_team_538) |> 
  mutate(
    dstring = cosine + jaccard,
    drank = rank_clubelo - rank_538,
    drank_prank = (drank - min(drank)) / (max(drank) - min(drank))
  ) |> 
  ungroup()

closest_strings <- string_dists |> 
  group_by(new_team_538) |> 
  slice_min(dstring, n = 1) |> 
  slice_min(drank, n = 1, with_ties = FALSE) |> 
  ungroup()

inverse_closest_strings <- string_dists |> 
  group_by(new_team_clubelo) |> 
  slice_min(dstring, n = 1) |> 
  slice_min(drank, n = 1, with_ties = FALSE) |> 
  ungroup()

agreeing_closest_strings <- inner_join(
  closest_strings |> select(-c(cosine, jaccard)),
  inverse_closest_strings |> select(new_team_clubelo, new_team_538),
  by = join_by(new_team_clubelo , new_team_538)
) |> 
  arrange(rank_538)

closest_ranks <- string_dists |> 
  group_by(new_team_538) |> 
  slice_min(dstring, n = 10) |> 
  slice_min(drank, n = 1, with_ties = FALSE) |> 
  ungroup()
closest_ranks


team <- 'Paris Saint Germain'
abbrv <- str_remove(team, '[a-z]{2,3}\\s+|\\s+[a-z]{2,3}') |> str_squish() |> str_sub(1, 5)
closest_strings |> filter(new_team_538 == .env$team)
string_dists |> filter(new_team_538 == .env$team) |> filter((0.9 * rank_clubelo) > rank_538) |> arrange(dstring)
string_dists |> distinct(rank_clubelo, new_team_clubelo) |> filter(new_team_clubelo |> str_detect(abbrv))
string_dists |> distinct(rank_clubelo, new_team_clubelo) |> filter(new_team_clubelo |> str_detect('san antonio'))

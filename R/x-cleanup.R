library(readr)
library(dplyr)

opta_rankings <- read_csv(
  'https://github.com/tonyelhabr/club-rankings/releases/download/club-rankings/opta-club-rankings.csv',
  show_col_types = FALSE
) |> 
  filter(!is.na(rank)) |>
  group_by(updated_at) |> 
  mutate(
    n = n()
  ) |> 
  ungroup() |> 
  mutate(
    max_n = max(n)
  ) |> 
  filter(n == max_n) |> 
  select(-c(n, max_n))

opta_rankings |> count(!is.na(id))
latest_opta_rankings <- opta_rankings |> 
  slice_max(updated_at, n = 1, with_ties = TRUE)

n_opta_team_names <- latest_opta_rankings |> count(team)
distinguishable <- n_opta_team_names |> filter(n == 1L)
indistinguishable <- n_opta_team_names |> filter(n > 1L)

uniquified <- indistinguishable |> 
  inner_join(
    latest_opta_rankings
  ) |> 
  group_by(team) |> 
  mutate(rn = row_number(rank)) |> 
  ungroup() |> 
  select(team, id, rn)

older_opta_club_rankings <- opta_rankings |> 
  filter(is.na(id))

uniquified_older <- older_opta_club_rankings |> 
  semi_join(
    indistinguishable |> distinct(team)
  ) |> 
  # select(rank, team, updated_at) |> 
  group_by(updated_at, team) |> 
  mutate(
    rn = row_number(rank)
  ) |> 
  ungroup() |> 
  select(-id) |> 
  inner_join(
    uniquified |> select(team, id, rn)
  ) |> 
  bind_rows(
    older_opta_club_rankings |> 
      anti_join(
        indistinguishable |> distinct(team)
      ) |> 
      select(-id) |> 
      inner_join(
        latest_opta_rankings |> distinct(team, id)
      )
  ) |> 
  select(-rn) |> 
  arrange(updated_at, rank)

res <- bind_rows(
  latest_opta_rankings,
  uniquified_older
) |> 
  arrange(updated_at, rank)
library(piggyback)
write_csv(res, "opta-club-rankings.csv")
pb_upload(
  "opta-club-rankings.csv",
  repo = "tonyelhabr/club-rankings",
  tag = "club-rankings"
)

# good_club_rankings <- all_club_rankings |>
#   group_by( updated_at) |> 
#   mutate(
#     n = n()
#   ) |> 
#   ungroup() |> 
#   group_by(source) |> 
#   mutate(
#     max_n = max(n)
#   ) |> 
#   ungroup() |> 
#   filter(n == max_n) |> 
#   select(-c(n, max_n))

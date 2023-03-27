## Introduction
This repo scrapes and stores the club rankings published by [Opta Analyst](https://theanalyst.com/na/2023/03/who-are-the-best-football-team-in-the-world-opta-power-rankings/) and [FiveThirtyEight](https://projects.fivethirtyeight.com/soccer-predictions/global-club-rankings/). The data is automatically pushed to [Github releases](https://github.com/tonyelhabr/club-rankings/releases).

| Source | Download |
|:-----|:-------------|
| Opta Analyst | [Download](https://github.com/tonyelhabr/club-rankings/releases/download/club-rankings/opta-club-rankings.csv) |
| FiveThirtyEight | [Download](https://github.com/tonyelhabr/club-rankings/releases/download/club-rankings/fivethirtyeight-club-rankings.csv) |

## Data Dictionary

Each file has the columns from the raw source, plus two additional ones

- `date`: The date on which the data was retrived, in `%Y-%m-%d` format.
- `updated_at`: The exact time at which the data was retrieved, in `%Y-%m-%d %H:%M:%S` format.

In cases where the Github action is manually triggered, there may be multiple entries per day for a given team.

Opta Analyst source fields:

- `rank`
- `team`
- `rating`
- `ranking change 7 days`

FiveThirtyEight source fields:

- `rank`
- `prev_rank`
- `name`
- `league`
- `off`
- `def`
- `spi`

## TODO

- Create a mapping of team names.
## Introduction
This repo scrapes and stores the club rankings published by [Opta Analyst](https://theanalyst.com/na/2023/03/who-are-the-best-football-team-in-the-world-opta-power-rankings/) and [FiveThirtyEight](https://projects.fivethirtyeight.com/soccer-predictions/global-club-rankings/). The data is automatically pushed to [Github releases](https://github.com/tonyelhabr/club-rankings/releases).

| Source | Download |
|:-----|:-------------|
| Opta Analyst | [Download](https://github.com/tonyelhabr/club-rankings/releases/download/club-rankings/opta-club-rankings.csv) |
| FiveThirtyEight | [Download](https://github.com/tonyelhabr/club-rankings/releases/download/club-rankings/fivethirtyeight-club-rankings.csv) |

In addition, I've added [a release file](https://github.com/tonyelhabr/club-rankings/releases/download/club-rankings/compared-rankings.csv) that compares the two table (using [a mapping file](https://github.com/tonyelhabr/club-rankings/blob/main/team-mapping.csv) that I manually created).

## Data Dictionary

### Club Rankings

Each file has the columns from the raw source, plus two additional ones

- `date`: The date on which the data was retrieved, in `%Y-%m-%d` format.
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

### Comparison

Comparison file fields:

- `date`
- `league_538`
- `team_538`
- `id_opta`
- `rank_538`
- `rank_opta`
- `rating_538`
- `rating_opta`

Note that the only Opta teams (over 13k) that can be mapped to FiveThirtyEight teams (around 650) are included in the comparison file.

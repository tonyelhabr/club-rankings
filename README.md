<!-- badges: start -->

[![scrape](https://github.com/tonyelhabr/club-rankings/actions/workflows/scrape.yml/badge.svg)](https://github.com/tonyelhabr/club-rankings/actions/workflows/scrape.yml) [![compare](https://github.com/tonyelhabr/club-rankings/actions/workflows/compare.yml/badge.svg)](https://github.com/tonyelhabr/club-rankings/actions/workflows/compare.yml) ![club-rankings downloads](https://img.shields.io/github/downloads/tonyelhabr/club-rankings/total)

<!-- badges: end -->

## Introduction

This repo scrapes and stores the club rankings published by [Opta Analyst](https://theanalyst.com/na/2023/03/who-are-the-best-football-team-in-the-world-opta-power-rankings/) and [Club Elo](http://clubelo.com/). ([FiveThirtyEight](https://projects.fivethirtyeight.com/soccer-predictions/global-club-rankings) is no longer scraped since it was FiveThirtyEight is effectively defunct.)

The data is automatically pushed to [Github releases](https://github.com/tonyelhabr/releases).

## Data

| Source       | Download                                                                                                          |
|:-------------|:------------------------------------------------------------------------------------------------------------------|
| Opta Analyst | [Download](https://github.com/tonyelhabr/club-rankings/releases/download/club-rankings/opta-club-rankings.csv)    |
| Club Elo     | [Download](https://github.com/tonyelhabr/club-rankings/releases/download/club-rankings/clubelo-club-rankings.csv) |

In addition, there is a [a release file](https://github.com/tonyelhabr/club-rankings/releases/download/club-rankings/compared-rankings.csv) that compares the rankings from each source (using [a team mapping file](https://github.com/tonyelhabr/club-rankings/blob/main/team-mapping.csv) that I manually created).

### Dictionary

#### Club Rankings

Each file has the columns from the raw source, plus two additional ones

-   `date`: The date on which the data was retrieved, in `%Y-%m-%d` format.
-   `updated_at`: The exact time at which the data was retrieved, in `%Y-%m-%d %H:%M:%S` format.

In cases where the Github action is manually triggered, there may be multiple entries per day for a given team.

Opta Analyst source fields:

-   `rank`
-   `team`
-   `rating`
-   `ranking change 7 days`

Club Elo source fields:

-   `Rank`
-   `Club`
-   `Country`
-   `Level`: league tier, i.e. 1 for top league in country
-   `Elo`
-   `From`: starting date from which elo is constant, presumably the day after a match
-   `To`: end data to which elo is constant, presumably the current date or the last day prior to a match day

#### Comparison

Comparison file fields:

-   `date`
-   `country`
-   `id_opta`
-   `team_opta`
-   `team_clubelo`
-   `rank_opta`
-   `rank_clubelo`
-   `rating_opta`
-   `rating_clubelo`

Note that Opta teams are used as the "base" for the comparisons. Only Club Elo teams that match Opta's are included.

## Example usage

```r
library(readr)
library(dplyr)
compared_rankings <- read_csv('https://github.com/tonyelhabr/club-rankings/releases/download/club-rankings/compared-rankings.csv')

compared_rankings |> 
  filter(country == 'ENG', date == '2023-09-05') |> 
  select(
    team_opta,
    rank_opta,
    rank_clubelo,
    rating_opta,
    rating_clubelo
  ) |> 
  slice_min(rank_opta, n = 20) |> 
  arrange(rank_opta) |> 
  knitr::kable(digits = 1)
```

| team_opta               | rank_opta | rank_clubelo | rating_opta | rating_clubelo |
|:------------------------|----------:|-------------:|------------:|---------------:|
| Manchester City         |         1 |            1 |       100.0 |         2087.4 |
| Liverpool               |         2 |            2 |        94.8 |         1961.3 |
| Arsenal                 |         4 |            4 |        93.6 |         1928.8 |
| Manchester United       |        10 |           10 |        91.0 |         1860.9 |
| Newcastle United        |        12 |            9 |        90.4 |         1865.7 |
| Tottenham Hotspur       |        14 |           13 |        90.1 |         1846.9 |
| Brighton & Hove Albion  |        16 |           14 |        89.9 |         1839.8 |
| Aston Villa             |        20 |           17 |        89.2 |         1828.6 |
| West Ham United         |        21 |           22 |        89.0 |         1807.5 |
| Brentford               |        23 |           18 |        88.9 |         1826.3 |
| Crystal Palace          |        32 |           28 |        86.5 |         1768.2 |
| Chelsea                 |        35 |           27 |        86.3 |         1774.2 |
| Fulham                  |        36 |           38 |        85.5 |         1736.5 |
| Wolverhampton Wanderers |        56 |           48 |        83.8 |         1708.2 |
| Nottingham Forest       |        60 |           59 |        83.5 |         1687.4 |
| Burnley                 |        75 |           50 |        82.0 |         1703.0 |
| AFC Bournemouth         |        76 |           70 |        82.0 |         1659.0 |
| Everton                 |        77 |           60 |        82.0 |         1682.1 |
| Leicester City          |        83 |           44 |        81.8 |         1722.5 |
| Sheffield United        |        91 |           89 |        81.2 |         1630.8 |


<!-- badges: start -->
[![scrape](https://github.com/tonyelhabr/club-rankings/actions/workflows/scrape.yml/badge.svg)](https://github.com/tonyelhabr/club-rankings/actions/workflows/scrape.yml)
[![compare](https://github.com/tonyelhabr/club-rankings/actions/workflows/compare.yml/badge.svg)](https://github.com/tonyelhabr/club-rankings/actions/workflows/compare.yml)
![club-rankings downloads](https://img.shields.io/github/downloads/tonyelhabr/club-rankings/total)
<!-- badges: end -->
## Introduction

This repo scrapes and stores the club rankings published by [Opta Analyst](https://theanalyst.com/na/2023/03/who-are-the-best-football-team-in-the-world-opta-power-rankings/), [FiveThirtyEight](https://projects.fivethirtyeight.com/soccer-predictions/global-), and [Club Elo](http://clubelo.com/). The data is automatically pushed to [Github releases](https://github.com/tonyelhabr/releases).

## Data

| Source | Download |
| :----- | :------- |
| Opta Analyst | [Download](https://github.com/tonyelhabr/club-rankings/releases/download/club-rankings/opta-club-rankings.csv) |
| FiveThirtyEight | [Download](https://github.com/tonyelhabr/club-rankings/releases/download/club-rankings/fivethirtyeight-club-rankings.csv) |
| Club Elo | [Download](https://github.com/tonyelhabr/club-rankings/releases/download/club-rankings/clubelo-club-rankings.csv) |

In addition, there is a [a release file](https://github.com/tonyelhabr/club-rankings/releases/download/club-rankings/compared-rankings.csv) that compares the rankings from each source (using [a team mapping file](https://github.com/tonyelhabr/club-rankings/blob/main/team-mapping.csv) that I manually created).

### Dictionary

#### Club Rankings

Each file has the columns from the raw source, plus two additional ones

* `date`: The date on which the data was retrieved, in `%Y-%m-%d` format.
* `updated_at`: The exact time at which the data was retrieved, in `%Y-%m-%d %H:%M:%S` format.

In cases where the Github action is manually triggered, there may be multiple entries per day for a given team.

Opta Analyst source fields:

* `rank`
* `team`
* `rating`
* `ranking change 7 days`

FiveThirtyEight source fields:

* `rank`
* `prev_rank`
* `name`
* `league`
* `off`
* `def`
* `spi`

Club Elo source fields:

* `Rank`
* `Club`
* `Country`
* `Level`: league tier, i.e. 1 for top league in country
* `Elo`
* `From`: starting date from which elo is constant, presumably the day after a match
* `To`: end data to which elo is constant, presumably the current date or the last day prior to a match day

#### Comparison

Comparison file fields:

* `date`
* `league_538`
* `league_538_alternative`: manually defined league name where 538 lists "UEFA Champions League", "UEFA Europa Conference League", or "UEFA Europa League"
* `league_clubelo`
* `team_538`
* `id_opta`
* `team_clubelo`
* `rank_538`
* `rank_opta`
* `rank_clubelo`
* `rating_538`
* `rating_opta`
* `rating_clubelo`

Note that FiveThirtyEight's teams are used as the base for the comparison file (around 650 teams). Only Opta teams that match FiveThirtyEights's are included, and only Club Elo's teams that match FiveThirtyEight's are included.

## Example usage

```r
library(readr)
library(dplyr)
compared_rankings <- read_csv('https://github.com/tonyelhabr/club-rankings/releases/download/club-rankings/compared-rankings.csv')

compared_rankings |> 
  filter(league_538 == 'Barclays Premier League', date == '2023-04-20') |> 
  select(
    team_538,
    rank_538,
    rank_opta,
    rank_clubelo,
    rating_538,
    rating_opta,
    rating_clubelo
  ) |> 
  arrange(rank_538)
#> # A tibble: 20 × 7
#>    team_538                 rank_538 rank_opta rank_clubelo rating_538 rating_opta rating_clubelo
#>    <chr>                       <dbl>     <dbl>        <dbl>      <dbl>       <dbl>          <dbl>
#>  1 Manchester City                 1         1            1       92.3       100            2066.
#>  2 Liverpool                       5         7            5       84.5        94            1936.
#>  3 Arsenal                         6         5            3       83.8        94.5          1952.
#>  4 Brighton and Hove Albion        7        18           13       82.5        90.4          1838.
#>  5 Newcastle                      11        17            9       80.5        90.7          1863.
#>  6 Manchester United              12         8            8       79.3        93.4          1886.
#>  7 Chelsea                        14        33           20       78.4        88.1          1813.
#>  8 Aston Villa                    22        32           19       76.6        88.2          1818.
#>  9 Tottenham Hotspur              32        25           12       74.3        89.1          1840.
#> 10 Brentford                      35        54           28       73.5        85.9          1772.
#> 11 Crystal Palace                 39        51           29       72.7        86            1765.
#> 12 West Ham United                45        50           30       71.2        86.1          1757.
#> 13 Leicester City                 56        76           49       67.6        83.6          1722.
#> 14 Fulham                         67        73           47       66.0        83.9          1725.
#> 15 Wolverhampton                  77        62           41       64.9        84.5          1732.
#> 16 Leeds United                   90       100           60       61.8        81.8          1689.
#> 17 Southampton                    97       132           77       61.0        80.6          1644.
#> 18 AFC Bournemouth               101        99           62       59.8        81.9          1681.
#> 19 Everton                       102       119           64       59.6        81.1          1677.
#> 20 Nottingham Forest             145       140           86       53.2        80.2          1632
```
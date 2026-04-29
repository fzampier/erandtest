# e-RTwr Pilot, 1,000-Rep Run

Command:

```sh
Rscript R/simulations/ertwr_pilot.R 1000
```

Output:

```text
results/ertwr_pilot_1000.csv
```

Seed:

```r
set.seed(20260429)
```

## Status

This is a pilot result. The sample-size anchor used here was a temporary normal-endpoint shortcut. The next e-RTwr simulation pass should replace it with the `WRestimates`/Yu-Ganju win-ratio sample-size formula and should add WR at crossing plus final-study WR diagnostics.

## Setup

This first e-RTwr pilot uses disjoint treatment-control pairs and a continuous endpoint with normally distributed outcomes. Higher values are better.

Each pair contributes:

```text
D = +1  treatment wins
D = -1  control wins
D =  0  tie
```

The e-process is:

```math
W_j = W_{j-1}(1 + \lambda_j D_j).
```

For fixed/design wagers, the wager is parameterized by a design win ratio:

```math
\lambda = \frac{WR - 1}{WR + 1}.
```

For adaptive wagers, this run uses full Kelly based on prior pairwise wins/losses, with burn-in 10 and ramp 50:

```math
\lambda_j = c_j
\frac{W_{j-1}^{+} - W_{j-1}^{-}}{W_{j-1}^{+} + W_{j-1}^{-}}.
```

For this pilot only, sample sizes use the usual two-sample `power.t.test` default logic with 80% power and alpha 0.05. For a normal continuous endpoint, the WR maps to Cohen's d through:

```math
d = \sqrt{2}\Phi^{-1}\left(\frac{WR}{1 + WR}\right).
```

## Type I Error

| Design WR | Design d | Pairs | Adaptive full Kelly | Fixed design |
|---:|---:|---:|---:|---:|
| 1.10 | 0.084 | 2,202 | 4.4% | 1.6% |
| 1.20 | 0.161 | 603 | 3.3% | 3.7% |
| 1.30 | 0.232 | 293 | 2.1% | 2.7% |
| 1.50 | 0.358 | 124 | 1.0% | 2.3% |

Type I error was controlled in all tested scenarios. The adaptive full-Kelly policy is much less conservative than the earlier half-Kelly version, especially for the low-WR, high-pair-count setting.

## Power

| True WR | Cohen's d | Pairs | Adaptive full Kelly | Fixed under | Fixed matched | Fixed over |
|---:|---:|---:|---:|---:|---:|---:|
| 1.10 | 0.084 | 2,202 | 30.5% | 23.3% | 55.1% | 49.8% |
| 1.20 | 0.161 | 603 | 32.6% | 22.5% | 55.3% | 52.9% |
| 1.30 | 0.232 | 293 | 32.4% | 25.5% | 53.5% | 54.3% |
| 1.50 | 0.358 | 124 | 34.5% | 26.2% | 54.1% | 52.8% |

Median crossing times:

| True WR | Pairs | Adaptive full Kelly | Fixed matched |
|---:|---:|---:|---:|
| 1.10 | 2,202 | 1,065 | 1,294 |
| 1.20 | 603 | 313 | 345 |
| 1.30 | 293 | 168 | 181 |
| 1.50 | 124 | 86 | 70 |

## Interpretation

The fixed matched GROW-style wager consistently achieved about 54-55% early rejection probability at the sample size of an 80% fixed-sample t-test. This remains the most powerful option when the design WR is credible.

The adaptive full-Kelly version is now meaningfully competitive as an agnostic monitor: it reaches about 30-35% early rejection without specifying a design WR. This is still below the fixed matched wager, but it is a large gain over the earlier half-Kelly adaptive policy.

The concern that clinically realistic WRs imply small fixed lambda values is real, but not fatal. At WR 1.10, lambda is only 0.048 and still reaches 55.1% early rejection when the trial has 2,202 pairs. The cost is sample size: such a modest win-ratio edge requires many pairs.

Overestimating the design WR tends to cross earlier when it succeeds, but often lowers median final e-values and can reduce power. This mirrors the e-RTb/e-RTe wager-policy finding.

Next steps:

- Replace the temporary sample-size shortcut with `WRestimates`/Yu-Ganju WR sample sizes.
- Calculate WR at crossing and final-study WR, including an all-pairs `BuyseTest` comparator if feasible.
- Add trajectory and power figures.
- Extend from simple continuous wins to hierarchical Buyse/GPC-style wins.
- Consider mixture wagers over plausible WRs instead of a single fixed WR.

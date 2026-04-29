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

## Setup

This e-RTwr pilot uses disjoint treatment-control pairs and a continuous endpoint with normally distributed outcomes. Higher values are better.

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

Sample sizes now use the Yu-Ganju win-ratio formula, implemented directly with the same parameters used by `WRestimates::wr.ss()`: 1:1 allocation, no ties, two-sided alpha 0.05 as one-sided alpha 0.025, and 80% power. `WRestimates` is used automatically if installed; otherwise the local formula is used.

The run also records:

- sequential disjoint-pair WR at crossing and final N;
- all-pairs continuous WR at crossing and final N;
- WR exaggeration at crossing versus the true WR;
- WR exaggeration at crossing versus the final all-pairs WR.

## Type I Error

| Design WR | Pairs | Patients | Adaptive full Kelly | Fixed design |
|---:|---:|---:|---:|---:|
| 1.10 | 2,305 | 4,610 | 3.4% | 1.7% |
| 1.20 | 630 | 1,260 | 2.6% | 2.6% |
| 1.30 | 305 | 610 | 2.2% | 2.3% |
| 1.50 | 128 | 256 | 0.8% | 3.1% |

Type I error was controlled in all tested scenarios.

## Power

| True WR | Pairs | Adaptive full Kelly | Fixed under | Fixed matched | Fixed over |
|---:|---:|---:|---:|---:|---:|
| 1.10 | 2,305 | 31.1% | 24.9% | 56.2% | 54.6% |
| 1.20 | 630 | 35.6% | 27.9% | 57.0% | 51.4% |
| 1.30 | 305 | 37.1% | 27.2% | 57.2% | 52.9% |
| 1.50 | 128 | 33.6% | 29.6% | 54.7% | 54.2% |

Median crossing times:

| True WR | Pairs | Adaptive full Kelly | Fixed matched |
|---:|---:|---:|---:|
| 1.10 | 2,305 | 1,042 | 1,295 |
| 1.20 | 630 | 304 | 376 |
| 1.30 | 305 | 176 | 178 |
| 1.50 | 128 | 85 | 75 |

## WR At Crossing

Median all-pairs WR at crossing versus final all-pairs WR:

| True WR | Policy | WR at crossing | Final WR | Crossing / true | Crossing / final |
|---:|---|---:|---:|---:|---:|
| 1.10 | Adaptive | 1.18 | 1.10 | 1.07 | 1.04 |
| 1.10 | Fixed matched | 1.14 | 1.10 | 1.04 | 1.02 |
| 1.20 | Adaptive | 1.34 | 1.20 | 1.12 | 1.06 |
| 1.20 | Fixed matched | 1.28 | 1.20 | 1.07 | 1.03 |
| 1.30 | Adaptive | 1.49 | 1.31 | 1.15 | 1.05 |
| 1.30 | Fixed matched | 1.43 | 1.30 | 1.10 | 1.05 |
| 1.50 | Adaptive | 1.82 | 1.50 | 1.21 | 1.06 |
| 1.50 | Fixed matched | 1.75 | 1.50 | 1.17 | 1.05 |

The crossing WR is inflated relative to the true WR and also modestly inflated relative to the final all-pairs WR. The inflation is smaller than the binary Type M ratios because the all-pairs WR stabilizes many comparisons, but it still matters operationally.

## Interpretation

The fixed matched GROW-style wager consistently achieved about 55-57% early rejection probability at Yu-Ganju 80%-powered WR sample sizes. This remains the most powerful option when the design WR is credible.

Adaptive full-Kelly e-RTwr remains a credible agnostic monitor, reaching about 31-37% early rejection without specifying a design WR. It is less powerful than a correctly calibrated design wager, but it avoids committing to a design effect for validity or efficiency.

The switch from the temporary normal-theory sample-size shortcut to Yu-Ganju sizing changed sample sizes only modestly but gives the section a cleaner win-ratio foundation.

## BuyseTest Cross-Check

The internal all-pairs continuous WR estimator was checked against `BuyseTest` on 100 simulated trials per true WR value, with 80 treatment-control pairs per trial and seed 20260430. The maximum absolute WR difference was at floating-point precision:

| True WR | Max absolute WR difference | Max absolute log-ratio |
|---:|---:|---:|
| 1.00 | 2.22e-16 | 2.22e-16 |
| 1.10 | 2.22e-16 | 2.22e-16 |
| 1.20 | 2.22e-16 | 2.22e-16 |
| 1.30 | 2.22e-16 | 2.22e-16 |
| 1.50 | 4.44e-16 | 2.22e-16 |

The check lives in `R/simulations/ertwr_buysetest_check.R`. The main manuscript-scale simulations still use the internal estimator for speed.

Next steps:

- Add trajectory and power figures for e-RTwr.
- Extend from simple continuous wins to hierarchical Buyse/GPC-style wins.
- Consider mixture wagers over plausible WRs instead of a single fixed WR.

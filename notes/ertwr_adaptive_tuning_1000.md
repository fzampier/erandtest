# e-RTwr Adaptive Tuning, 1,000-Rep Runs

Commands:

```sh
Rscript R/simulations/ertwr_adaptive_tuning.R 1000
Rscript R/simulations/ertwr_adaptive_tuning.R 1000 fine
```

Outputs:

```text
results/ertwr_adaptive_tuning_1000.csv
results/ertwr_adaptive_tuning_fine_1000.csv
```

Seed:

```r
set.seed(20260430)
```

These runs use Yu-Ganju win-ratio sample sizes: 1:1 allocation, no ties, two-sided alpha 0.05 as one-sided alpha 0.025, and 80% power.

## Coarse Grid

The coarse grid compared half Kelly and full Kelly over burn-ins 0, 10, 30 and ramps 1, 20, 50.

Best average alternative power by tuning setting:

| Kelly fraction | Burn-in | Ramp | Max type I | Mean power |
|---:|---:|---:|---:|---:|
| 1.0 | 0 | 50 | 3.5% | 34.0% |
| 1.0 | 10 | 50 | 3.7% | 33.2% |
| 1.0 | 10 | 20 | 3.8% | 32.2% |
| 1.0 | 30 | 50 | 3.8% | 32.0% |
| 1.0 | 30 | 20 | 4.2% | 31.8% |
| 0.5 | 0 | 20 | 2.6% | 23.4% |

Full Kelly again dominated half Kelly for power. The only clearly poor full-Kelly setting remains burn-in 0 / ramp 1: type I was controlled, but mean power was only 4.9% because the wager can drive wealth down after the first few random pairs.

## Fine Full-Kelly Grid

The fine grid kept Kelly fraction at 1.0 and searched burn-ins 0, 10, 20, 30 with ramps 20, 35, 50, 75, 100.

Best average alternative power:

| Burn-in | Ramp | Max type I | Mean power |
|---:|---:|---:|---:|
| 0 | 100 | 3.6% | 34.0% |
| 10 | 75 | 3.4% | 33.9% |
| 30 | 50 | 3.7% | 33.6% |
| 10 | 50 | 2.7% | 33.2% |
| 0 | 50 | 3.7% | 33.2% |
| 20 | 75 | 3.3% | 33.0% |

The differences among the top settings are small. A slower ramp can replace a burn-in: burn-in 0 / ramp 100 was best on mean power, while burn-in 10 / ramp 50 was slightly more conservative and remains easier to explain as a default.

## Best Settings by Design WR

| Design WR | Best setting | Power | Max type I | Median crossing |
|---:|---|---:|---:|---:|
| 1.10 | burn-in 30, ramp 75 | 34.9% | 3.3% | 1,057 |
| 1.20 | burn-in 30, ramp 100 | 39.5% | 3.9% | 320 |
| 1.30 | burn-in 20, ramp 35 | 38.1% | 3.7% | 166 |
| 1.50 | burn-in 0, ramp 50 | 37.9% | 3.7% | 73 |

Low-WR designs benefit from a longer warm-up because the planned pair count is large and the true edge is subtle. High-WR designs have fewer pairs, so long burn-ins or very long ramps consume a substantial fraction of monitoring time.

## Recommendation

Use adaptive full Kelly for e-RTwr. A pragmatic default remains burn-in 10 and ramp 50: it had 33.2% mean power in the fine grid with the lowest max type I error among the top settings (2.7%).

For sensitivity analyses:

- report burn-in 0 / ramp 100 as the best-average-power policy;
- report burn-in 30 / ramp 75 or 30 / ramp 100 for low anticipated WRs around 1.10-1.20;
- report burn-in 0 / ramp 50 for short, higher-effect designs.

This tuning does not affect validity. Burn-in, ramp, and Kelly fraction only define predictable bounded wagers; the martingale property still follows from the null symmetry of future pairwise wins/losses conditional on the past.

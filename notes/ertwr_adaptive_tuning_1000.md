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

## Coarse Grid

These tuning runs still use the temporary e-RTwr pilot sample-size anchor. The recommended adaptive wager policy can carry forward, but the design-size calculations should be rerun after switching to `WRestimates`/Yu-Ganju sample sizes.

The coarse grid compared half Kelly and full Kelly over burn-ins 0, 10, 30 and ramps 1, 20, 50.

Best average alternative power by tuning setting:

| Kelly fraction | Burn-in | Ramp | Max type I | Mean power |
|---:|---:|---:|---:|---:|
| 1.0 | 0 | 50 | 3.3% | 33.5% |
| 1.0 | 30 | 50 | 2.6% | 31.6% |
| 1.0 | 10 | 20 | 3.7% | 31.5% |
| 1.0 | 10 | 50 | 3.3% | 31.2% |
| 1.0 | 30 | 20 | 3.7% | 31.2% |
| 0.5 | 0 | 20 | 2.1% | 21.9% |

Full Kelly dominated half Kelly for power. The only clearly bad full-Kelly setting was burn-in 0 / ramp 1: it remained type-I-safe but had only 4.0% mean power because it reacts too strongly to the first few pairs and can drive wealth close to zero early.

## Fine Full-Kelly Grid

The fine grid kept Kelly fraction at 1.0 and searched burn-ins 0, 10, 20, 30 with ramps 20, 35, 50, 75, 100.

Best average alternative power:

| Burn-in | Ramp | Max type I | Mean power |
|---:|---:|---:|---:|
| 10 | 50 | 4.2% | 33.2% |
| 0 | 75 | 3.4% | 32.6% |
| 0 | 100 | 3.5% | 32.5% |
| 10 | 35 | 4.6% | 32.4% |
| 20 | 75 | 3.5% | 31.5% |
| 30 | 50 | 3.7% | 31.5% |

One fine-grid setting, burn-in 20 / ramp 50, showed 5.4% maximum null rejection across the four design WRs. With 1,000 replicates this is compatible with Monte Carlo error around the Ville bound, but it is not a good default because nearby settings are cleaner.

## Best Settings by Design WR

| Design WR | Best setting | Power | Max type I | Median crossing |
|---:|---|---:|---:|---:|
| 1.10 | burn-in 30, ramp 75 | 33.4% | 2.5% | 1,108 |
| 1.20 | burn-in 30, ramp 100 | 36.0% | 3.7% | 360 |
| 1.30 | burn-in 10, ramp 50 | 36.9% | 4.2% | 159 |
| 1.50 | burn-in 0, ramp 50 | 34.6% | 4.1% | 76 |

Low-WR designs benefit from a longer warm-up because the planned pair count is large and the true edge is subtle. High-WR designs have fewer pairs, so long burn-ins waste a substantial fraction of monitoring time.

## Recommendation

Use adaptive full Kelly for e-RTwr. A pragmatic default is burn-in 10 and ramp 50: it had the best average power in the fine grid while keeping simulated type I error below 5%.

For low anticipated WRs, especially around 1.10-1.20, also report sensitivity analyses with a longer ramp or burn-in, such as burn-in 30 / ramp 75 or burn-in 30 / ramp 100. For short, higher-effect designs, avoid long burn-ins.

This tuning does not affect validity. Burn-in, ramp, and Kelly fraction only define predictable bounded wagers; the martingale property still follows from the null symmetry of future pairwise wins/losses conditional on the past.

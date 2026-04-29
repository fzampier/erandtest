# Wager Policy 1,000-Rep Run, Same Enrolled N

Command:

```sh
Rscript R/simulations/wager_policy_comparison.R 1000
```

Output:

```text
results/wager_policy_1000_same_n.csv
```

This supersedes the inflated e-RTe comparison for the V8 wager-policy table. Both e-RTb and e-RTe now use the same enrolled-patient sample size from `power.prop.test` with 80% power and alpha 0.05. No event-only inflation is applied.

The simulation uses a fixed seed:

```r
set.seed(20260428)
```

The figure generator also uses a fixed seed:

```r
set.seed(20260429)
```

## Type I Error

All policies remain near or below nominal alpha 0.05 in this 1,000-rep run. The largest observed Type I error is 5.1% for e-RTb with a 10pp fixed wager in the null scenario designed around a 5pp ARR, which is within Monte Carlo uncertainty for 1,000 simulations.

## Power, Same N

At true ARR 5pp and N = 2,942:

| Endpoint | Adaptive | Fixed under | Fixed matched | Fixed over |
|---|---:|---:|---:|---:|
| e-RTb | 49.9% | 50.1% | 72.3% | 56.7% |
| e-RTe | 31.0% | 14.5% | 53.5% | 46.8% |

At true ARR 10pp and N = 712:

| Endpoint | Adaptive | Fixed under | Fixed matched | Fixed over |
|---|---:|---:|---:|---:|
| e-RTb | 52.8% | 41.8% | 69.1% | 67.4% |
| e-RTe | 32.7% | 5.7% | 43.7% | 49.6% |

## Interpretation

Design-fixed wagers improve power when well calibrated, especially for e-RTb. With the same enrolled-patient N, e-RTe has fewer betting opportunities because it only updates on events, so it no longer has the high power observed in the prior 2.5x-inflated event-only comparison.

This is the fair head-to-head for power at the same trial size. The older inflated e-RTe simulation still answers a different question: how much extra enrollment is needed when only events are monitored.

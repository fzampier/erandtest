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

## Type M Error At Crossing

Type M was summarized among trials that crossed the e-value threshold. For e-RTb the effect scale is the apparent absolute risk reduction at crossing. For e-RTe the effect scale is the event-coin tilt, `0.5 - Pr(treatment | event)`, because e-RTe does not observe a denominator.

At true ARR 5pp:

| Endpoint | Policy | Crossing effect | Final effect | Median Type M | Q75 | Q90 |
|---|---|---:|---:|---:|---:|---:|
| e-RTb | Adaptive | 7.84pp | 5.04pp | 1.57 | 2.19 | 3.21 |
| e-RTb | Fixed matched | 6.86pp | 5.01pp | 1.37 | 1.76 | 2.22 |
| e-RTe | Adaptive | 6.48pp tilt | 3.26pp tilt | 1.95 | 2.65 | 3.55 |
| e-RTe | Fixed matched | 5.19pp tilt | 3.44pp tilt | 1.56 | 1.94 | 2.48 |

At true ARR 10pp:

| Endpoint | Policy | Crossing effect | Final effect | Median Type M | Q75 | Q90 |
|---|---|---:|---:|---:|---:|---:|
| e-RTb | Adaptive | 14.67pp | 10.17pp | 1.47 | 1.79 | 2.21 |
| e-RTb | Fixed matched | 12.62pp | 9.82pp | 1.26 | 1.56 | 1.85 |
| e-RTe | Adaptive | 11.78pp tilt | 7.20pp tilt | 1.65 | 1.94 | 2.30 |
| e-RTe | Fixed matched | 10.32pp tilt | 7.20pp tilt | 1.45 | 1.70 | 2.06 |

Crossings are enriched for favorable random fluctuation. This is expected for any early stopping rule, but it is important to report because the apparent effect at crossing can materially exceed both the true effect and the final-study estimate.

## Interpretation

Design-fixed wagers improve power when well calibrated, especially for e-RTb. With the same enrolled-patient N, e-RTe has fewer betting opportunities because it only updates on events, so it no longer has the high power observed in the prior 2.5x-inflated event-only comparison.

This is the fair head-to-head for power at the same trial size. The older inflated e-RTe simulation still answers a different question: how much extra enrollment is needed when only events are monitored.

# Wager Policy 5,000-Rep Run, Same Enrolled N

Command:

```sh
Rscript R/simulations/wager_policy_comparison.R 5000
```

Output:

```text
results/wager_policy_5000_same_n.csv
```

This supersedes the inflated e-RTe comparison for the V9 wager-policy table. Both e-RTb and e-RTe now use the same enrolled-patient sample size from `power.prop.test` with 80% power and alpha 0.05. No event-only inflation is applied.

The simulation uses a fixed seed:

```r
set.seed(20260428)
```

The figure generator also uses a fixed seed:

```r
set.seed(20260429)
```

## Type I Error

All policies remain below nominal alpha 0.05 in this 5,000-rep run. The largest observed Type I error is 4.8% for e-RTe with a 10pp fixed wager in the null scenario designed around a 5pp ARR. The adaptive e-RTb null estimate at the 10pp design sample size is now 2.0%, consistent with the separate 5,000-rep adaptive e-RTb baseline estimate of 2.1% at the same N.

## Power, Same N

At true ARR 5pp and N = 2,942:

| Endpoint | Adaptive | Fixed under | Fixed matched | Fixed over |
|---|---:|---:|---:|---:|
| e-RTb | 49.3% | 53.7% | 75.0% | 55.7% |
| e-RTe | 31.5% | 14.2% | 51.2% | 46.9% |

At true ARR 10pp and N = 712:

| Endpoint | Adaptive | Fixed under | Fixed matched | Fixed over |
|---|---:|---:|---:|---:|
| e-RTb | 50.5% | 41.9% | 71.3% | 67.1% |
| e-RTe | 33.8% | 5.7% | 43.2% | 50.6% |

## Type M Error At Crossing

Type M was summarized among trials that crossed the e-value threshold. For e-RTb the effect scale is the apparent absolute risk reduction at crossing. For e-RTe, the e-process still uses only event arm labels, but the Type M diagnostic now uses the full randomized-trial snapshot available at crossing to estimate absolute risk reduction on the same clinical scale as e-RTb. If a deployment truly lacks denominators, only the native event-coin tilt diagnostic can be reported.

At true ARR 5pp:

| Endpoint | Policy | Crossing effect | Final effect | Median Type M | Q75 | Q90 |
|---|---|---:|---:|---:|---:|---:|
| e-RTb | Adaptive | 7.92pp | 5.00pp | 1.58 | 2.12 | 2.95 |
| e-RTb | Fixed matched | 6.52pp | 5.01pp | 1.30 | 1.69 | 2.15 |
| e-RTe | Adaptive | 8.03pp | 4.99pp | 1.61 | 2.03 | 2.66 |
| e-RTe | Fixed matched | 6.73pp | 4.99pp | 1.35 | 1.64 | 2.00 |

At true ARR 10pp:

| Endpoint | Policy | Crossing effect | Final effect | Median Type M | Q75 | Q90 |
|---|---|---:|---:|---:|---:|---:|
| e-RTb | Adaptive | 14.68pp | 10.06pp | 1.47 | 1.79 | 2.20 |
| e-RTb | Fixed matched | 12.74pp | 10.03pp | 1.27 | 1.57 | 1.89 |
| e-RTe | Adaptive | 14.63pp | 10.09pp | 1.46 | 1.76 | 2.11 |
| e-RTe | Fixed matched | 13.15pp | 10.02pp | 1.32 | 1.58 | 1.83 |

Crossings are enriched for favorable random fluctuation. This is expected for any early stopping rule, but it is important to report because the apparent effect at crossing can materially exceed both the true effect and the final-study estimate.

## Interpretation

Design-fixed wagers improve power when well calibrated, especially for e-RTb. With the same enrolled-patient N, e-RTe has fewer betting opportunities because it only updates on events, so it no longer has the high power observed in the prior 2.5x-inflated event-only comparison.

This is the fair head-to-head for power at the same trial size. The older inflated e-RTe simulation still answers a different question: how much extra enrollment is needed when only events are monitored.

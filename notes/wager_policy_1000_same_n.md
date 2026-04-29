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

All policies remain near or below nominal alpha 0.05 in this 1,000-rep run. The largest observed Type I error is 5.1% for a 10pp fixed wager in the null scenario designed around a 5pp ARR, which is within Monte Carlo uncertainty for 1,000 simulations.

## Power, Same N

At true ARR 5pp and N = 2,942:

| Endpoint | Adaptive | Fixed under | Fixed matched | Fixed over |
|---|---:|---:|---:|---:|
| e-RTb | 49.1% | 53.2% | 75.3% | 57.1% |
| e-RTe | 34.7% | 15.2% | 50.6% | 44.7% |

At true ARR 10pp and N = 712:

| Endpoint | Adaptive | Fixed under | Fixed matched | Fixed over |
|---|---:|---:|---:|---:|
| e-RTb | 48.9% | 40.9% | 69.7% | 67.8% |
| e-RTe | 32.7% | 4.2% | 43.5% | 49.9% |

## Type M Error At Crossing

Type M was summarized among trials that crossed the e-value threshold. For e-RTb the effect scale is the apparent absolute risk reduction at crossing. For e-RTe, the e-process still uses only event arm labels, but the Type M diagnostic now uses the full randomized-trial snapshot available at crossing to estimate absolute risk reduction on the same clinical scale as e-RTb. If a deployment truly lacks denominators, only the native event-coin tilt diagnostic can be reported.

At true ARR 5pp:

| Endpoint | Policy | Crossing effect | Final effect | Median Type M | Q75 | Q90 |
|---|---|---:|---:|---:|---:|---:|
| e-RTb | Adaptive | 7.84pp | 4.92pp | 1.57 | 2.17 | 3.12 |
| e-RTb | Fixed matched | 6.49pp | 4.97pp | 1.30 | 1.67 | 2.09 |
| e-RTe | Adaptive | 8.23pp | 4.97pp | 1.65 | 2.13 | 2.74 |
| e-RTe | Fixed matched | 6.77pp | 4.88pp | 1.35 | 1.68 | 2.03 |

At true ARR 10pp:

| Endpoint | Policy | Crossing effect | Final effect | Median Type M | Q75 | Q90 |
|---|---|---:|---:|---:|---:|---:|
| e-RTb | Adaptive | 14.44pp | 10.07pp | 1.44 | 1.82 | 2.25 |
| e-RTb | Fixed matched | 12.83pp | 9.92pp | 1.28 | 1.58 | 1.90 |
| e-RTe | Adaptive | 14.74pp | 9.94pp | 1.47 | 1.76 | 2.11 |
| e-RTe | Fixed matched | 13.10pp | 9.94pp | 1.31 | 1.55 | 1.82 |

Crossings are enriched for favorable random fluctuation. This is expected for any early stopping rule, but it is important to report because the apparent effect at crossing can materially exceed both the true effect and the final-study estimate.

## Interpretation

Design-fixed wagers improve power when well calibrated, especially for e-RTb. With the same enrolled-patient N, e-RTe has fewer betting opportunities because it only updates on events, so it no longer has the high power observed in the prior 2.5x-inflated event-only comparison.

This is the fair head-to-head for power at the same trial size. The older inflated e-RTe simulation still answers a different question: how much extra enrollment is needed when only events are monitored.

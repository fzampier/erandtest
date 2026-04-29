# e-RTc Wager Policy 1,000-Rep Run

Command:

```sh
Rscript R/simulations/ertc_wager_policy.R 1000
```

Output:

```text
results/ertc_wager_policy_1000.csv
manuscript/ertc_wager_policy_table.tex
```

The simulation uses a fixed seed:

```r
set.seed(20260430)
```

The adaptive e-RTc policy preserves the standalone V7 script's sign-direction wager with burn-in 20, ramp 50, and `c_max = 0.6`. The design policy uses a parametric normal-shift working model to compute `Pr(T = 1 | Y)` from the prespecified means and common SD. This working model affects efficiency, not validity.

## Type I Error

All rows remained below nominal alpha 0.05 in this 1,000-rep run:

| Design d | Adaptive | Design |
|---:|---:|---:|
| 0.20 | 3.8% | 3.0% |
| 0.40 | 4.3% | 2.9% |
| 0.60 | 4.0% | 1.2% |

## Power And Type M

| True d | Adaptive | Design under | Design matched | Design over |
|---:|---:|---:|---:|---:|
| 0.20 | 9.8% | 52.1% | 73.4% | 59.2% |
| 0.40 | 31.6% | 34.4% | 66.6% | 61.1% |
| 0.60 | 53.8% | 5.7% | 44.7% | 55.5% |

Median Type M among crossing trials:

| True d | Adaptive | Design under | Design matched | Design over |
|---:|---:|---:|---:|---:|
| 0.20 | 2.98 | 1.33 | 1.28 | 1.58 |
| 0.40 | 1.66 | 1.39 | 1.29 | 1.37 |
| 0.60 | 1.28 | 1.60 | 1.29 | 1.25 |

## Interpretation

Adaptive e-RTc is conservative for small effects. At true `d = 0.20`, crossings were rare and enriched for very favorable early fluctuations, so Type M was high. A matched normal-shift design wager substantially improved power and reduced Type M in the `d = 0.20` and `d = 0.40` settings.

Design misspecification matters. Underestimating the effect can delay crossings and lose power, especially at `d = 0.60`. Overestimating the effect can produce earlier crossings and sometimes higher Type M, although in this run it remained competitive at larger true effects.

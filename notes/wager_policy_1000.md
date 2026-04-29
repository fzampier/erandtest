# Wager Policy 1,000-Rep Run

Note: this file records the earlier event-only comparison with 2.5x e-RTe enrollment inflation. The current V8 same-enrolled-N comparison is in `notes/wager_policy_1000_same_n.md` and `results/wager_policy_1000_same_n.csv`.

Command:

```sh
Rscript R/simulations/wager_policy_comparison.R 1000
```

Output:

```text
results/wager_policy_1000.csv
```

This run separates three quantities:

- `sample_size_arr`: ARR used to determine total N.
- `true_arr`: ARR used to simulate data.
- `wager_arr`: ARR used to set the fixed full-Kelly wager.

## Type I Error

All real policies were near or below nominal alpha 0.05 in this 1,000-rep run.

| Endpoint | Policy | N design ARR | Wager ARR | N | Events | Type I |
|---|---:|---:|---:|---:|---:|---:|
| e-RTb | adaptive half-Kelly | 0.05 | NA | 2942 | NA | 3.5% |
| e-RTb | fixed full-Kelly | 0.05 | 0.05 | 2942 | NA | 3.1% |
| e-RTb | fixed full-Kelly | 0.05 | 0.10 | 2942 | NA | 5.1% |
| e-RTe | adaptive full-Kelly | 0.05 | NA | 7355 | 2942 | 3.6% |
| e-RTe | fixed full-Kelly | 0.05 | 0.05 | 7355 | 2942 | 4.0% |
| e-RTe | fixed full-Kelly | 0.05 | 0.10 | 7355 | 2942 | 4.4% |
| e-RTb | adaptive half-Kelly | 0.10 | NA | 712 | NA | 2.8% |
| e-RTb | fixed full-Kelly | 0.10 | 0.05 | 712 | NA | 0.4% |
| e-RTb | fixed full-Kelly | 0.10 | 0.10 | 712 | NA | 3.0% |
| e-RTe | adaptive full-Kelly | 0.10 | NA | 1780 | 712 | 3.0% |
| e-RTe | fixed full-Kelly | 0.10 | 0.05 | 1780 | 712 | 0.8% |
| e-RTe | fixed full-Kelly | 0.10 | 0.10 | 1780 | 712 | 4.3% |

## Power

| Endpoint | Policy | True ARR | Wager ARR | Interpretation | N | Events | Power |
|---|---:|---:|---:|---|---:|---:|---:|
| e-RTb | adaptive half-Kelly | 0.05 | NA | adaptive | 2942 | NA | 49.1% |
| e-RTb | fixed full-Kelly | 0.05 | 0.025 | underestimated | 2942 | NA | 51.5% |
| e-RTb | fixed full-Kelly | 0.05 | 0.050 | matched | 2942 | NA | 74.4% |
| e-RTb | fixed full-Kelly | 0.05 | 0.100 | overestimated | 2942 | NA | 59.0% |
| e-RTe | adaptive full-Kelly | 0.05 | NA | adaptive | 7355 | 2759 | 72.2% |
| e-RTe | fixed full-Kelly | 0.05 | 0.025 | underestimated | 7355 | 2759 | 86.2% |
| e-RTe | fixed full-Kelly | 0.05 | 0.050 | matched | 7355 | 2759 | 90.4% |
| e-RTe | fixed full-Kelly | 0.05 | 0.100 | overestimated | 7355 | 2759 | 61.9% |
| e-RTb | adaptive half-Kelly | 0.10 | NA | adaptive | 712 | NA | 50.4% |
| e-RTb | fixed full-Kelly | 0.10 | 0.050 | underestimated | 712 | NA | 43.1% |
| e-RTb | fixed full-Kelly | 0.10 | 0.100 | matched | 712 | NA | 72.2% |
| e-RTb | fixed full-Kelly | 0.10 | 0.150 | overestimated | 712 | NA | 68.7% |
| e-RTe | adaptive full-Kelly | 0.10 | NA | adaptive | 1780 | 624 | 76.2% |
| e-RTe | fixed full-Kelly | 0.10 | 0.050 | underestimated | 1780 | 624 | 85.3% |
| e-RTe | fixed full-Kelly | 0.10 | 0.100 | matched | 1780 | 624 | 88.4% |
| e-RTe | fixed full-Kelly | 0.10 | 0.150 | overestimated | 1780 | 624 | 79.8% |

## Early Interpretation

Fixed full-Kelly wagers substantially improve power when the wager ARR is close to the truth.

Underestimating the wager is usually less damaging than overestimating it, especially for e-RTe at 5pp ARR, where overestimating the effect from 5pp to 10pp drops power from 90.4% to 61.9%.

Adaptive policies remain valid and effect-size agnostic, but pay a power cost. This is the central trade-off for V8: adaptive wagers are robust and require no hypothesized effect size; design-fixed wagers are more efficient when the design alternative is credible.

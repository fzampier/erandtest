# Wager Policy Pilot

Pilot run:

```sh
Rscript R/simulations/wager_policy_comparison.R 500
```

Output file:

```text
results/wager_policy_pilot.csv
```

The output file is generated and ignored by git; this note preserves the first-pass interpretation.

## Policies Compared

- e-RTb adaptive half-Kelly: original V7 adaptive wager.
- e-RTb design full-Kelly: fixed design-implied assignment probability after observing event/non-event.
- e-RTe adaptive full-Kelly: original V7 event-coin wager learned from observed events.
- e-RTe design full-Kelly: fixed design event-coin wager from `p_trt_design / (p_trt_design + p_ctrl_design)`.
- Oracle full-Kelly: simulation-only benchmark using true event rates.

## Type I Error

With `p_ctrl = p_trt = 0.40`, all real policies stayed below nominal alpha 0.05 in this 500-rep pilot:

| Endpoint | Policy | Design ARR | N | Events | Type I |
|---|---:|---:|---:|---:|---:|
| e-RTb | adaptive half-Kelly | 0.05 | 2942 | NA | 4.4% |
| e-RTb | design full-Kelly | 0.05 | 2942 | NA | 2.0% |
| e-RTe | adaptive full-Kelly | 0.05 | 7355 | 2942 | 3.4% |
| e-RTe | design full-Kelly | 0.05 | 7355 | 2942 | 4.2% |
| e-RTb | adaptive half-Kelly | 0.10 | 712 | NA | 2.6% |
| e-RTb | design full-Kelly | 0.10 | 712 | NA | 2.8% |
| e-RTe | adaptive full-Kelly | 0.10 | 1780 | 712 | 3.2% |
| e-RTe | design full-Kelly | 0.10 | 1780 | 712 | 4.0% |

Oracle under the null is neutral because the true event rates are equal, so it is not informative for Type I comparison.

## Power Signals

When the design ARR matched the true ARR, design full-Kelly improved power substantially:

| Endpoint | Policy | ARR | N | Events | Power |
|---|---:|---:|---:|---:|---:|
| e-RTb | adaptive half-Kelly | 0.05 | 2942 | NA | 48.2% |
| e-RTb | design full-Kelly | 0.05 | 2942 | NA | 74.0% |
| e-RTe | adaptive full-Kelly | 0.05 | 7355 | 2759 | 69.4% |
| e-RTe | design full-Kelly | 0.05 | 7355 | 2759 | 91.8% |
| e-RTb | adaptive half-Kelly | 0.10 | 712 | NA | 46.4% |
| e-RTb | design full-Kelly | 0.10 | 712 | NA | 73.2% |
| e-RTe | adaptive full-Kelly | 0.10 | 1780 | 624 | 73.2% |
| e-RTe | design full-Kelly | 0.10 | 1780 | 624 | 88.2% |

When the design was optimistic (`design ARR = 0.10`, true ARR `0.05`), design full-Kelly still increased threshold-crossing probability in this short-horizon pilot, but this needs deeper study because aggressive wagers may trade expected log-growth for higher variance and earlier crossings.

## Takeaway

The first pilot supports adding wager policy as a first-class design layer. Adaptive wagers preserve effect-size agnosticism; design full-Kelly wagers can recover substantial power when the design alternative is credible. Manuscript-grade simulations should use larger replication counts and include misspecification grids.


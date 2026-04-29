# e-RTs Wager-Policy Simulation, 1,000 Reps

Seed: `set.seed(20260501)`.

Script: `R/simulations/erts_wager_policy.R`.

Outputs:

- `results/erts_wager_policy_1000.csv`
- `manuscript/erts_wager_policy_table.tex`
- `manuscript/erts_wager_policy_power.pdf`
- `manuscript/erts_wager_policy_type_m.pdf`

## Design

Simulations used exponential survival times, 1:1 randomization, no censoring,
and event counts from the Schoenfeld log-rank event formula for 80% fixed-sample
power at two-sided `alpha = 0.05`.

Policies:

- fixed magnitude: adaptive direction, `lambda_max = 0.25`;
- adaptive half-Kelly: prior log-rank score estimates the hazard ratio;
- design under: prespecified HR closer to 1 than the truth;
- design matched: prespecified HR equals the truth;
- design over: prespecified HR more extreme than the truth;
- oracle: computed in the script but excluded from the manuscript table.

## Main Results

Type I error remained controlled in the simulated null scenarios. The largest
observed rate was 5.4% for the fixed-magnitude policy with planning HR 0.90,
consistent with Monte Carlo noise around the 5% threshold.

Matched design wagers were most powerful at the conventional log-rank event
counts:

| True HR | Fixed 0.25 | Adaptive half | Design matched |
| --- | ---: | ---: | ---: |
| 0.70 | 46.8% | 28.2% | 62.7% |
| 0.80 | 61.2% | 38.2% | 70.8% |
| 0.90 | 37.3% | 41.6% | 75.4% |

The design-matched e-process still did not generally reach 80% anytime crossing
power at the fixed-sample log-rank event count. This mirrors the e-RTwr lesson:
a trial powered for 80% final-analysis rejection does not automatically have
80% probability of crossing an anytime-valid e-process boundary before the
planned maximum.

## Crossing Diagnostics

Median Type M ratios on the `|log(HR)|` scale among crossing trials:

| True HR | Fixed 0.25 | Adaptive half | Design matched |
| --- | ---: | ---: | ---: |
| 0.70 | 1.35 | 1.56 | 1.27 |
| 0.80 | 1.42 | 1.57 | 1.32 |
| 0.90 | 2.08 | 1.56 | 1.30 |

Type S error was essentially absent. Only the two-sided fixed and adaptive
policies at true HR 0.90 had nonzero wrong-direction crossing rates, both below
1%.

## Interpretation

The fixed e-RTs policy remains useful as a robust baseline, especially for HR
around 0.80, but it is not uniquely optimal. A Sokolova-like design wager can be
substantially more efficient when the design hazard ratio is credible. Adaptive
half-Kelly is intentionally safer but conservative because early event data
estimate the hazard-ratio scale imprecisely.

Misspecification behaves in the expected direction: underestimating the
treatment effect delays crossings and loses power, while overestimating the
effect crosses earlier and may preserve power at the cost of more Type M
exaggeration.

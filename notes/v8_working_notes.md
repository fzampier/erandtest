# V8 Working Notes

Version 8 should remain an evolution of the active arXiv Version 7, not a conceptual restart.

Initial priorities:

1. Clarify e-RT as an effect-size-agnostic randomization monitoring framework.
2. Distinguish the validity engine from the wager policy.
3. Introduce optional design-fixed wager policies, especially for e-RTb and e-RTe.
4. Compare adaptive, design-fixed, and oracle wagers through simulation.
5. Keep a possible Clinical Trials journal version in mind, while preserving a fuller arXiv manuscript during development.

Current simulation priorities:

1. Add Type M error at crossing for e-RTb and e-RTe. The estimand should be the apparent effect at first threshold crossing, compared with the true simulated effect and summarized among crossing trials.
2. Move e-RTwr design sample sizes from the temporary normal-endpoint `power.t.test` shortcut to the `WRestimates`/Yu-Ganju win-ratio formula.
3. For e-RTwr, report the sequential disjoint-pair WR at crossing, the final sequential disjoint-pair WR, and the final all-pairs GPC WR using `BuyseTest` if feasible.
4. Keep the distinction explicit: e-RTwr monitoring validity follows from predictable disjoint/predictably formed pair updates; all-pairs GPC WR is a final descriptive comparator unless dependence is handled.

Current e-RTwr status:

- Prototype code lives in `R/ertwr.R`.
- Pilot simulations live in `R/simulations/ertwr_pilot.R`.
- Adaptive tuning lives in `R/simulations/ertwr_adaptive_tuning.R`.
- Adaptive e-RTwr currently uses full Kelly with burn-in 10 and ramp 50, based on the 1,000-rep tuning note.
- Fixed/design e-RTwr uses `lambda = (WR - 1) / (WR + 1)`, matching the GROW-style wager for a binary win/loss/tie pair contribution.

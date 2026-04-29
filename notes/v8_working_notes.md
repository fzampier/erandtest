# V8 Working Notes

Version 8 should remain an evolution of the active arXiv Version 7, not a conceptual restart.

Initial priorities:

1. Clarify e-RT as an effect-size-agnostic randomization monitoring framework.
2. Distinguish the validity engine from the wager policy.
3. Introduce optional design-fixed wager policies, especially for e-RTb and e-RTe.
4. Compare adaptive, design-fixed, and oracle wagers through simulation.
5. Keep a possible Clinical Trials journal version in mind, while preserving a fuller arXiv manuscript during development.

Current simulation priorities:

1. Integrate Type M error at crossing for e-RTb and e-RTe into the manuscript. The code now estimates the apparent effect at first threshold crossing, compares it with the true simulated effect, and summarizes the ratio among crossing trials.
2. Integrate e-RTwr Yu-Ganju sample sizing into the manuscript. The code now uses a `WRestimates`-compatible formula, with `WRestimates::wr.ss()` used automatically if installed.
3. Integrate e-RTwr WR diagnostics into the manuscript. The code now reports sequential disjoint-pair WR at crossing/final N and internal all-pairs continuous WR at crossing/final N.
4. Use the package-backed `BuyseTest` cross-check as validation for the internal all-pairs continuous WR estimator. Keep the distinction explicit: e-RTwr monitoring validity follows from predictable disjoint/predictably formed pair updates; all-pairs GPC WR is a final descriptive comparator unless dependence is handled.
5. Use the Sokolova-style comparison to clarify sample-size targets: same-N fixed/GROW e-RTwr is the paired GROW wager at the Yu-Ganju final-analysis N, while e-process-calibrated GROW design needs its own larger `Nmax` to achieve 80% anytime power.

Current e-RTwr status:

- Prototype code lives in `R/ertwr.R`.
- Pilot simulations live in `R/simulations/ertwr_pilot.R`.
- Adaptive tuning lives in `R/simulations/ertwr_adaptive_tuning.R`.
- `BuyseTest` validation lives in `R/simulations/ertwr_buysetest_check.R`.
- Sokolova-style GROW comparison lives in `R/simulations/ertwr_sokolova_comparison.R`.
- Composite endpoint simulation with `simBuyseTest()` and exported pair scores lives in `R/simulations/ertwr_composite_buysetest.R`.
- Adaptive e-RTwr currently uses full Kelly with burn-in 10 and ramp 50, based on the 1,000-rep tuning note.
- Fixed/design e-RTwr uses `lambda = (WR - 1) / (WR + 1)`, matching the GROW-style wager for a binary win/loss/tie pair contribution.

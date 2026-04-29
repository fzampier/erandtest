# V8 Working Notes

Version 8 should remain an evolution of the active arXiv Version 7, not a conceptual restart.

Initial priorities:

1. Clarify e-RT as an effect-size-agnostic randomization monitoring framework.
2. Distinguish the validity engine from the wager policy.
3. Introduce optional design-fixed wager policies, especially for e-RTb and e-RTe.
4. Compare adaptive, design-fixed, and oracle wagers through simulation.
5. Keep a possible Clinical Trials journal version in mind, while preserving a fuller arXiv manuscript during development.

Current simulation priorities:

1. Integrate Type M error at crossing for e-RTb and e-RTe into the manuscript. The code now estimates the apparent effect at first threshold crossing, compares it with the true simulated effect, and summarizes the ratio among crossing trials. For e-RTe, the e-process still uses only event arm labels, but the ARR Type M diagnostic uses the full trial snapshot at crossing when denominators are available.
2. Integrate e-RTc parametric design wagers into the manuscript. The code preserves the standalone V7 adaptive sign-direction wager and adds a normal-shift design wager with Type M error at crossing on the Cohen's `d` scale.
3. Integrate e-RTs fixed, adaptive, and design-calibrated log-rank risk-set wagers into the manuscript. The code now reports Type I error, power, Type M on the `|log(HR)|` scale, and Type S at crossing.
4. Integrate e-RTwr Yu-Ganju sample sizing into the manuscript. The code now uses a `WRestimates`-compatible formula, with `WRestimates::wr.ss()` used automatically if installed.
5. Integrate e-RTwr WR diagnostics into the manuscript. The code now reports sequential disjoint-pair WR at crossing/final N and internal all-pairs continuous WR at crossing/final N.
6. Use the package-backed `BuyseTest` cross-check as validation for the internal all-pairs continuous WR estimator. Keep the distinction explicit: e-RTwr monitoring validity follows from predictable disjoint/predictably formed pair updates; all-pairs GPC WR is a final descriptive comparator unless dependence is handled.
7. Use the Sokolova-style comparison to clarify sample-size targets: same-N fixed/GROW e-RTwr is the paired GROW wager at the Yu-Ganju final-analysis N, while e-process-calibrated GROW design needs its own larger `Nmax` to achieve 80% anytime power.

Current e-RTwr status:

- Prototype code lives in `R/ertwr.R`.
- Pilot simulations live in `R/simulations/ertwr_pilot.R`.
- Adaptive tuning lives in `R/simulations/ertwr_adaptive_tuning.R`.
- `BuyseTest` validation lives in `R/simulations/ertwr_buysetest_check.R`.
- Sokolova-style GROW comparison lives in `R/simulations/ertwr_sokolova_comparison.R`.
- Composite endpoint simulation with `simBuyseTest()` and exported pair scores lives in `R/simulations/ertwr_composite_buysetest.R`.
- Adaptive e-RTwr currently uses full Kelly with burn-in 10 and ramp 50, based on the 1,000-rep tuning note.
- Fixed/design e-RTwr uses `lambda = (WR - 1) / (WR + 1)`, matching the GROW-style wager for a binary win/loss/tie pair contribution.

Current e-RTc status:

- Reusable code lives in `R/ertc.R`.
- Wager-policy simulation lives in `R/simulations/ertc_wager_policy.R`.
- The adaptive default follows the standalone V7 script `ertc_20251215.R`: sign of the past mean difference, robust residual score, burn-in 20, ramp 50, `c_max = 0.6`.
- The design wager is parametric by default: a normal-shift working model maps each continuous outcome to `Pr(T = 1 | Y)`.

Current e-RTs status:

- Reusable code lives in `R/erts.R`.
- Wager-policy simulation lives in `R/simulations/erts_wager_policy.R`.
- Simulation seed is `set.seed(20260501)`.
- The fixed-magnitude policy uses adaptive direction and `lambda_max = 0.25`.
- The adaptive policy estimates the prior log hazard ratio from the cumulative
  log-rank score and uses half-Kelly by default.
- The design policy maps a prespecified hazard ratio to a risk-set-specific
  GROW-style wager. HR below 1 implies a negative wager on the `U_j = X_j - p_j`
  increment scale.

Current manuscript scope:

- Active V8 variants: e-RTb, e-RTe, e-RTwr, e-RTc, and e-RTs.
- e-RTms and e-RTu have been removed from the active manuscript and are framed
  as future extensions.
- Next logical technical target: polish the combined V8 manuscript narrative,
  then decide whether the Clinical Trials target should use the full methods
  catalog or a compressed binary/event/survival-focused subset.

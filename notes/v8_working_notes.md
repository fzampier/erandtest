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
2. Use the new e-RTe/e-RTb tuning sensitivity grid to discuss burn-in, ramp, and Kelly intensity as design-stage choices. The current script compares default settings with fixed event-count schedules, proportional-to-planned-events schedules, and 25% to 100% Kelly intensity settings.
3. Integrate e-RTc parametric design wagers into the manuscript. The code preserves the standalone V7 adaptive sign-direction wager and adds a normal-shift design wager with Type M error at crossing on the Cohen's `d` scale.
4. Integrate e-RTs fixed, adaptive, and design-calibrated log-rank risk-set wagers into the manuscript. The code now reports Type I error, power, Type M on the `|log(HR)|` scale, and Type S at crossing.
5. Keep pairwise/GPC endpoint ideas as future work unless they are reformulated as true randomization tests.

Current pairwise status:

- Former e-RTwr code, results, generated tables, and notes live in
  `explorations/ertwr/`.
- This parked prototype is a sequential pairwise win/loss e-process, not an
  active e-RT variant, because it bets on pairwise outcome direction after
  treatment assignment is known.
- A future pairwise/GPC e-RT should form pairs predictably, observe pair
  outcomes, determine the clinically preferred member, and then bet whether
  that member was randomized to treatment.

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

- Active V8 variants: e-RTb, e-RTe, e-RTc, and e-RTs.
- e-RTms, e-RTu, and pairwise/GPC monitoring have been removed from the active
  manuscript and are framed as future extensions.
- Next logical technical target: polish the combined V8 manuscript narrative,
  then decide whether the Clinical Trials target should use the full methods
  catalog or a compressed binary/event/survival-focused subset.

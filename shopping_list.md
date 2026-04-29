# V8 Shopping List

This is the working add/remove/change list for Version 8.

## Add

- Add Sokolova and Sokolov as a central comparison point.
- Add `evalinger` as a software/context comparison.
- Add a new conceptual distinction: validity engine versus wager policy.
- Add design-calibrated wager policies for e-RTb and e-RTe.
- Add simulations comparing adaptive, fixed, design-calibrated, and oracle wagers.
- Add design-effect misspecification simulations.
- Include Type I error simulations for every real wager policy.
- Add Type M error at crossing for e-RTb and e-RTe simulations.
- Add a pairwise win/loss e-process concept connected to generalized pairwise comparisons and win-ratio methods.
- Add citations for Buyse generalized pairwise comparisons and Pocock win ratio if the pairwise section survives.
- Use `WRestimates`/Yu-Ganju win-ratio sample-size formula for e-RTwr design sizes.
- Calculate final-study WR and WR at crossing for e-RTwr, likely using `BuyseTest` as the GPC reference implementation.

## Remove Or Deprecate

- Deprecate or remove e-RTu as currently written.
- Replace e-RTu with a more grounded pairwise method if simulations and theory look sensible.
- Reduce language implying that adaptive wagers are the only natural e-RT implementation.
- Reduce any overstatement that e-RT is fully tuning-free. Use "effect-size agnostic" rather than "parameter-free."

## Rewrite

- Rewrite the introduction to include design-calibrated e-value monitoring as the main external contrast.
- Rewrite methods to separate:
  - randomization-based martingale validity;
  - endpoint-specific signal construction;
  - wager policy.
- Rewrite the wager asymmetry section after adding design-calibrated modes.
- Rewrite limitations to name tuning choices, burn-in/ramp, design wager misspecification, and nonstationarity.
- Rewrite discussion to position e-RT as a complement to group sequential, Bayesian, and design-calibrated e-value approaches.

## Simulations

- e-RTb:
  - adaptive half-Kelly wager;
  - design-fixed full-Kelly wager;
  - design-calibrated wager;
  - oracle wager benchmark.
- e-RTe:
  - adaptive full-Kelly event-coin wager;
  - design-fixed full-Kelly event-coin wager;
  - design event-coin wager from `p_trt_design / (p_trt_design + p_ctrl_design)`;
  - oracle event-coin benchmark.
- Misspecification grids:
  - design effect equals true effect;
  - design effect larger than true effect;
  - design effect smaller than true effect;
  - wrong direction, if worth stress-testing.
- Type M error at crossing:
  - estimate the apparent effect at the first threshold crossing;
  - compare it with the true simulated effect;
  - report exaggeration ratios among crossing trials;
  - include e-RTb and e-RTe adaptive and fixed wager policies.
- Pairwise win/loss:
  - disjoint or predictably matched treatment-control pairs only at first;
  - avoid all-pairs products until dependence is handled;
  - compare power and estimand behavior against ordinary e-RTc and classical win-ratio summaries.
- e-RTwr WR diagnostics:
  - use `WRestimates::wr.ss()` or the same Yu-Ganju formula for design sample size;
  - calculate full-study WR at final N;
  - calculate WR using only data accrued up to first e-process crossing;
  - report crossing-WR exaggeration relative to the true/design WR and relative to the final-study WR;
  - distinguish disjoint-pair sequential WR from all-pairs GPC/BuyseTest WR.

## Open Questions

- Should V8 use "e-RT" as family name and "e-RTb/e-RTe/e-RTc/e-RTs/e-RTms/e-RTpw" as variants?
- Should the pairwise method be called `e-RTpw`, `e-RTwr`, or `e-RTgpc`?
- Is the pairwise estimand a classical win ratio, a net benefit, or a matching-rule-specific sequential win tendency?
- Should Type M at crossing be reported as median exaggeration, mean exaggeration, or quantiles because the ratio may be unstable when the true effect is small?
- Should e-RTwr use the disjoint-pair WR as the primary monitoring estimand, with `BuyseTest` all-pairs WR as the final-trial descriptive estimand?
- Should design-calibrated e-RT be presented as optional efficiency mode or as a separate named variant?
- Should the Clinical Trials journal version be a later compressed derivative rather than the main V8 manuscript?

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
- Add parametric design-calibrated e-RTc wagers based on prespecified mean, SD, and effect.
- Add a pairwise win/loss e-process concept connected to generalized pairwise comparisons and win-ratio methods.
- Add citations for Buyse generalized pairwise comparisons and Pocock win ratio if the pairwise section survives.

## Added In Code, Needs Manuscript Integration

- Type M error at crossing for e-RTb and e-RTe simulations, with e-RTe ARR estimated from the full trial snapshot at crossing when denominators are available.
- Type M error at crossing for e-RTc simulations on the Cohen's `d` scale.
- e-RTs fixed-magnitude, adaptive half-Kelly, design-calibrated, misspecified
  design, and oracle simulation framework, with Type I error, power, Type M, and
  Type S diagnostics.
- Yu-Ganju/`WRestimates`-compatible win-ratio sample-size formula for e-RTwr design sizes.
- Final-study WR and WR at crossing for e-RTwr using internal sequential and all-pairs continuous WR estimators.
- Package-backed `BuyseTest` validation for simple continuous all-pairs WR estimates, kept as a reference check rather than the main simulation engine.
- Sokolova-style GROW comparison showing same-N fixed/GROW e-RTwr versus e-process-calibrated GROW `Nmax`.
- Composite endpoint simulation using `BuyseTest::simBuyseTest()`, final all-pairs GPC, and disjoint-pair e-RTwr on exported pair scores.

## Remove Or Deprecate

- Defer e-RTu from the active V8 manuscript.
- Defer e-RTms from the active V8 manuscript.
- Replace the old e-RTu emphasis with the more grounded e-RTwr pairwise method.
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
- e-RTc:
  - V7 adaptive sign-direction wager;
  - parametric normal-shift design wager;
  - underestimated, matched, and overestimated design effects;
  - Type M error at crossing on the Cohen's `d` scale.
- Misspecification grids:
  - design effect equals true effect;
  - design effect larger than true effect;
  - design effect smaller than true effect;
  - wrong direction, if worth stress-testing.
- Type M error at crossing:
  - estimate the apparent effect at the first threshold crossing;
  - compare it with the true simulated effect;
  - report exaggeration ratios among crossing trials;
  - report Type S sign error among crossing trials when the effect direction is meaningful;
  - include e-RTb and e-RTe adaptive and fixed wager policies;
  - for e-RTe, distinguish the native event-coin monitoring scale from the full-data ARR diagnostic at crossing.
- e-RTs:
  - compare current fixed-magnitude wager, adaptive log-rank-score wager, design/Sokolova-like wager from prespecified HR, misspecified design HRs, and oracle benchmark; **implemented**
  - report Type I error, power, median crossing event, HR at crossing, final HR, Type M on the `|log(HR)|` scale, and Type S sign error at crossing; **implemented**
- Pairwise win/loss:
  - disjoint or predictably matched treatment-control pairs only at first;
  - avoid all-pairs products until dependence is handled;
  - compare power and estimand behavior against ordinary e-RTc and classical win-ratio summaries.
- e-RTwr WR diagnostics:
  - use the package-backed `BuyseTest` all-pairs GPC check as a validation/reference estimator;
  - keep the internal all-pairs continuous WR as the fast simulation estimator after confirming agreement with `BuyseTest` on simple continuous examples;
  - distinguish disjoint-pair sequential WR from all-pairs GPC/BuyseTest WR in the manuscript.
- Sokolova/GROW comparison:
  - present fixed/design e-RTwr as the same paired GROW wager applied to continuous pairwise signs;
  - distinguish Yu-Ganju final-analysis N from e-process-calibrated `Nmax`;
  - report the observed 1.6-1.7x pair-count increase needed to recover about 80% anytime power in the simple WR-sign simulation.

## Open Questions

- Should V8 use "e-RT" as family name and "e-RTb/e-RTe/e-RTwr/e-RTc/e-RTs" as the active variants?
- Should the pairwise method be called `e-RTpw`, `e-RTwr`, or `e-RTgpc`?
- Is the pairwise estimand a classical win ratio, a net benefit, or a matching-rule-specific sequential win tendency?
- Should Type M at crossing be reported as median exaggeration, mean exaggeration, or quantiles because the ratio may be unstable when the true effect is small?
- Should Type S be reported for all endpoints, or emphasized mainly for directional e-RTs and e-RTwr simulations?
- Should e-RTwr use the disjoint-pair WR as the primary monitoring estimand, with `BuyseTest` all-pairs WR as the final-trial descriptive estimand?
- Should design-calibrated e-RT be presented as optional efficiency mode or as a separate named variant?
- Should the Clinical Trials journal version be a later compressed derivative rather than the main V8 manuscript?

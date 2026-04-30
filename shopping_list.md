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
- Add a future-work note on pairwise/GPC endpoints, making clear that a future
  version should preserve the assignment-prediction randomization-test
  structure.

## Added In Code, Needs Manuscript Integration

- Type M error at crossing for e-RTb and e-RTe simulations, with e-RTe ARR estimated from the full trial snapshot at crossing when denominators are available. **implemented and integrated**
- e-RTe/e-RTb burn-in/ramp and Kelly-intensity sensitivity grid, comparing
  fixed event-count schedules, proportional planned-event schedules, and 25% to
  100% Kelly intensity settings. **implemented and integrated**
- Type M error at crossing for e-RTc simulations on the Cohen's `d` scale. **implemented and integrated**
- e-RTs fixed-magnitude, adaptive half-Kelly, design-calibrated, misspecified
  design, and oracle simulation framework, with Type I error, power, Type M, and
  Type S diagnostics.
- e-RTs staggered-entry check comparing paired complete-follow-up
  time-on-study identity with calendar-event-order monitoring.
- Curated fixed-seed trajectory examples for e-RTb, e-RTe, e-RTc, and e-RTs.
- Full active-manuscript reproducibility chain with `Makefile`, dependency
  check, inventory check, generated table inputs, and cleanup of obsolete
  pilot outputs. **implemented**
- Former e-RTwr scripts, generated tables, and results parked under
  `explorations/ertwr/`. **implemented**

## Remove Or Deprecate

- Defer e-RTu from the active V8 manuscript.
- Defer e-RTms from the active V8 manuscript.
- Defer the current e-RTwr/pairwise prototype from the active V8 manuscript
  because it is not an assignment-prediction randomization test.
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
  - burn-in/ramp and Kelly-intensity sensitivity grid comparing default,
    fixed-event, and proportional-to-planned-events schedules; **implemented**
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
  - include a standalone staggered-entry check for complete-follow-up
    time-on-study analyses and a separate calendar-event-order stream;
    **implemented**
- Manuscript figures:
  - regenerate didactic trajectory examples from a standalone fixed-seed script
    rather than inherited interactive artifacts; **implemented**
- Pairwise/GPC future work:
  - form pairs predictably;
  - observe pair outcomes and determine the clinically preferred member;
  - bet on whether the preferred member was randomized to treatment;
  - keep the parked disjoint-pair sign process in `explorations/ertwr/` as
    background, not as an active e-RT method.

## Open Questions

- Do we want a compressed journal-specific derivative after V8 stabilizes, or
  should this full repository manuscript remain the primary working draft until
  submission targeting is decided?
- Should V8 use "e-RT" as family name and "e-RTb/e-RTe/e-RTc/e-RTs" as the active variants?
- What should a future true randomization-test pairwise method be called?
- Should Type M at crossing be reported as median exaggeration, mean exaggeration, or quantiles because the ratio may be unstable when the true effect is small?
- Should Type S be reported for all endpoints, or emphasized mainly for directional e-RTs simulations?

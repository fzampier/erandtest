# V9 Shopping List

This is the working add/remove/change list for Version 9.

## Active Priorities

- Keep Sokolova and Sokolov as the central comparison point for
  design-calibrated e-processes and GROW-style wagers.
- Keep the validity-engine versus wager-policy distinction prominent.
- Keep the active manuscript focused on e-RTb, e-RTe, and e-RTc.
- Keep event-only monitoring language tied to conditional exchangeability of
  observed event labels.
- Keep e-RTc design-calibrated wagers framed as parametric efficiency tools.
- Keep Type M at crossing as a descriptive diagnostic, not as the inferential
  claim.

## Simulations

- e-RTb:
  - adaptive half-Kelly wager;
  - design-fixed full-Kelly wager;
  - design-calibrated wager;
  - oracle benchmark.
- e-RTe:
  - adaptive full-Kelly event-coin wager;
  - design-fixed full-Kelly event-coin wager;
  - design event-coin wager from `p_trt_design / (p_trt_design + p_ctrl_design)`;
  - oracle event-coin benchmark;
  - burn-in/ramp and Kelly-intensity sensitivity grid.
- e-RTc:
  - V7 adaptive sign-direction wager;
  - parametric normal-shift design wager;
  - underestimated, matched, and overestimated design effects;
  - Type M error at crossing on the Cohen's `d` scale.

## Parked Work

- Pairwise/GPC future work:
  - form pairs predictably;
  - observe pair outcomes and determine the clinically preferred member;
  - bet on whether the preferred member was randomized to treatment;
  - keep the parked disjoint-pair sign process in `explorations/ertwr/` as
    background, not as an active e-RT method.
- e-RTb futility future work:
  - decide whether the clinically relevant futility null should be `ARR >= MCID`
    or a softer boundary;
  - prove the reciprocal process carefully, separating baseline-specific design
    calibration from nuisance-robust guarantees;
  - investigate whether a less conservative nuisance-robust construction is
    possible without assuming the baseline event risk;
  - consider whether futility should be offered as a separate monitoring layer
    rather than a core V9 manuscript claim.

## Candidate Cuts For A Shorter Journal Version

- Move the e-RTe burn-in/ramp/Kelly-intensity sensitivity subsection and table
  to a supplement.
- Move didactic trajectory figures to a supplement, retaining only one
  representative figure or the wager-policy comparison figures.
- Compress the design-wager misspecification narrative after the main tables.
- Move pairwise/GPC future-work discussion to a shorter paragraph.
- Keep the unified validity argument, endpoint-selection table, Type M/crossing
  reporting material, prespecification checklist, and "when not to use e-RT";
  those are high-value reviewer-facing material.
- Defer software/API examples until the R package interface stabilizes.

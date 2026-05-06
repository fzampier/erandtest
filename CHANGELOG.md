# Changelog

## Version 9 In Preparation

This repository is the clean V9-forward workspace for e-RT. It preserves the
randomization-based monitoring lineage from earlier drafts while focusing the
active manuscript and reproducibility chain on e-RTb, e-RTe, and e-RTc.

### Scope

- Kept the active manuscript focused on binary, event-only, and continuous
  endpoint monitoring.
- Reframed e-RT around a separation between the randomization-based validity
  engine and the endpoint-specific wager policy.
- Deferred e-RTms, e-RTu, and pairwise win-ratio/GPC prototypes from the main
  manuscript to avoid overextending the paper before their dependence and
  randomization-test questions are settled.

### Manuscript

- Added Sokolova and Sokolov as a central external comparison for
  design-calibrated e-processes and GROW-style wagers.
- Settled the main framing: e-RT is effect-size agnostic by default, with
  design-calibrated and GROW-style wagers treated as optional efficiency tools.
- Added a unified validity argument making predictability, conditional expected
  multiplier 1, and the validity/power separation explicit for all active
  variants.
- Reorganized the binary and event-only sections around adaptive versus
  design-fixed wager policies.
- Clarified the event-only null as conditional exchangeability of observed event
  labels under the event-monitoring history.
- Added e-RTc design-wager material using a parametric normal-shift working
  model.
- Added Type M error at crossing as a recurring diagnostic.
- Added a DSMB-facing crossing-report subsection, a protocol prespecification
  checklist, and a "when not to use e-RT" scope subsection.
- Removed the embedded R-code appendix from the manuscript and refer readers to
  the repository as the computational source of truth.

### Code And Simulations

- Added reusable modules for e-RTb, e-RTe, and e-RTc.
- Added a top-level `Makefile` with dependency checking, result regeneration,
  figure/table regeneration, manuscript build, and inventory validation targets.
- Added `R/check_dependencies.R` and `R/check_inventory.R` for lightweight
  standalone reproducibility checks.
- Added generated baseline-table scripts for e-RTb and e-RTe so inherited
  static manuscript tables are no longer hand-maintained.
- Added fixed-seed simulation scripts for e-RTb/e-RTe wager-policy comparisons.
- Added e-RTe diagnostics that compute ARR at crossing from the full randomized
  trial snapshot while keeping the e-process itself event-only.
- Added e-RTe/e-RTb tuning sensitivity simulations over fixed and proportional
  burn-in/ramp schedules and 25%, 50%, 75%, and 100% Kelly intensity settings.
- Added e-RTc simulations comparing adaptive, underestimated design, matched
  design, overestimated design, and oracle policies.
- Added a standalone fixed-seed trajectory-example generator and rebuilt the
  manuscript e-RTb, e-RTe, and e-RTc didactic trajectory figures.
- Parked the former e-RTwr pilot, tuning, Sokolova-style GROW comparison,
  WRestimates sample-size checks, BuyseTest validation, composite endpoint
  simulations, and generated tables under `explorations/ertwr/`.
- Added an exploratory e-RTb reciprocal-futility module under
  `explorations/ertb_futility/`. This module compares design-calibrated and
  nuisance-robust reciprocal e-processes for the futility null `ARR >= MCID`
  and is not part of the active V9 manuscript reproducibility chain.
- Added a generated binary over-betting stress table for the wager-asymmetry
  discussion.
- Committed active generated CSV result tables under `results/` so manuscript
  numbers can be audited directly from the repository.

### Documentation

- Added a public-facing README with project scope, repository layout,
  reproducibility commands, package notes, build instructions, and current
  caveats.
- Added `notes/reproducibility_inventory.md` mapping active manuscript tables,
  figures, CSVs, and support artifacts to their generators.
- Added `AGENTS.md` and `shopping_list.md` to preserve working context for
  future research-agent sessions.

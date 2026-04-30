# Changelog

## Version 8 In Preparation

This repository is the clean V8-forward workspace for e-RT. It starts from the
active arXiv Version 7 material, while leaving the local V7 archive untouched.

### Scope

- Kept the active manuscript focused on e-RTb, e-RTe, e-RTc, and e-RTs.
- Deferred e-RTms, e-RTu, and pairwise win-ratio/GPC prototypes from the main
  V8 manuscript to avoid overextending the paper before their dependence and
  randomization-test questions are settled.
- Reframed e-RT around a separation between the randomization-based validity
  engine and the endpoint-specific wager policy.

### Manuscript

- Added Sokolova and Sokolov as a central external comparison for
  design-calibrated e-processes and GROW-style wagers.
- Clarified in the relationship-to-existing-work section that the first e-RT
  draft predated the Sokolova/Sokolov manuscript while acknowledging their work
  as a central influence on the V8 design-calibrated framing.
- Settled the main V8 framing: e-RT is effect-size agnostic by default, with
  design-calibrated and GROW-style wagers treated as optional efficiency tools.
- Added a unified validity argument making predictability, conditional expected
  multiplier 1, and the validity/power separation explicit for all variants.
- Replaced the inherited e-RTs staggered-entry paragraph with a standalone V8
  check, distinguishing exact complete-follow-up time-on-study identity from a
  separate calendar-event-order monitoring simulation.
- Reorganized the binary and event-only sections around adaptive versus
  design-fixed wager policies.
- Moved the former e-RTwr material out of the active manuscript and reframed
  pairwise/GPC endpoints as future work requiring an assignment-prediction
  randomization-test formulation.
- Added e-RTc design-wager material using a parametric normal-shift working
  model.
- Added e-RTs wager-policy material comparing fixed-magnitude, adaptive
  half-Kelly, and design-calibrated log-rank risk-set wagers.
- Added Type M error at crossing as a recurring diagnostic.
- Added Gelman and Carlin's Type S/Type M design-analysis citation and e-RTs
  Type S diagnostics.
- Updated the Version Control section to describe the V8 changes.
- Removed the embedded R-code appendix from the manuscript and refer readers to
  the repository as the computational source of truth.

### Code And Simulations

- Added reusable modules for e-RTb, e-RTe, e-RTc, and e-RTs.
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
  burn-in/ramp schedules and 25%, 50%, 75%, and 100% Kelly intensity settings;
  removed the older inflated-sample-size e-RTe operating table from the active
  manuscript.
- Added e-RTc simulations comparing adaptive, underestimated design, matched
  design, overestimated design, and oracle policies.
- Added e-RTs simulations comparing fixed, adaptive, underestimated design,
  matched design, overestimated design, and oracle policies.
- Added e-RTs manuscript figures for wager-policy power and Type M error at
  crossing.
- Added a standalone e-RTs staggered-entry script with 1,000-replicate results,
  summary notes, and a refreshed supplement figure.
- Added a standalone fixed-seed trajectory-example generator and rebuilt the
  manuscript e-RTb, e-RTe, e-RTc, and e-RTs didactic trajectory figures.
- Parked the former e-RTwr pilot, tuning, Sokolova-style GROW comparison,
  WRestimates sample-size checks, BuyseTest validation, composite endpoint
  simulations, and generated tables under `explorations/ertwr/`.
- Added a generated binary over-betting stress table for the wager-asymmetry
  discussion.
- Committed active generated CSV result tables under `results/` because the
  repository is private and the intermediate outputs help audit manuscript
  numbers.
- Removed old e-RTms figure PDFs and low-replicate/pilot CSV outputs from the
  active repo.

### Documentation

- Added a robust README with project scope, repository layout, reproducibility
  commands, package notes, build instructions, and current caveats.
- Added `notes/reproducibility_inventory.md` mapping active manuscript tables,
  figures, CSVs, and support artifacts to their generators.
- Added `AGENTS.md` and `shopping_list.md` to preserve working context for
  future research-agent sessions.

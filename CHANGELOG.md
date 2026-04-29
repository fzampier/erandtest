# Changelog

## Version 8 In Preparation

This repository is the clean V8-forward workspace for e-RT. It starts from the
active arXiv Version 7 material, while leaving the local V7 archive untouched.

### Scope

- Kept the active manuscript focused on e-RTb, e-RTe, e-RTwr, e-RTc, and e-RTs.
- Deferred e-RTms and e-RTu from the main V8 manuscript to avoid overextending
  the paper before their dependence and simulation questions are settled.
- Reframed e-RT around a separation between the randomization-based validity
  engine and the endpoint-specific wager policy.

### Manuscript

- Added Sokolova and Sokolov as a central external comparison for
  design-calibrated e-processes and GROW-style wagers.
- Reorganized the binary and event-only sections around adaptive versus
  design-fixed wager policies.
- Added e-RTwr as a pairwise win-ratio/GPC-inspired monitoring prototype.
- Added e-RTc design-wager material using a parametric normal-shift working
  model.
- Added Type M error at crossing as a recurring diagnostic.
- Updated the Version Control section to describe the V8 changes.

### Code And Simulations

- Added reusable modules for e-RTb, e-RTe, e-RTc, and e-RTwr.
- Added fixed-seed simulation scripts for e-RTb/e-RTe wager-policy comparisons.
- Added e-RTe diagnostics that compute ARR at crossing from the full randomized
  trial snapshot while keeping the e-process itself event-only.
- Added e-RTc simulations comparing adaptive, underestimated design, matched
  design, overestimated design, and oracle policies.
- Added e-RTwr pilot, tuning, Sokolova-style GROW comparison, WRestimates
  sample-size checks, BuyseTest validation, and composite endpoint simulations.
- Committed generated CSV result tables under `results/` because the repository
  is private and the intermediate outputs help audit manuscript numbers.

### Documentation

- Added a robust README with project scope, repository layout, reproducibility
  commands, package notes, build instructions, and current caveats.
- Added `AGENTS.md` and `shopping_list.md` to preserve working context for
  future research-agent sessions.

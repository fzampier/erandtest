# erandtest

Working repository for version 8 onward of the e-RT manuscript and code.

This repository starts from the active arXiv Version 7 materials, copied from the local archive at `/Users/fgz5335/Desktop/e-RT`. The archive is intentionally left untouched.

## Working Layout

- `manuscript/`: V8 manuscript source and copied baseline figures.
- `R/`: active R code for e-RT variants and simulations.
- `R/simulations/`: planned simulation scripts for V8 additions.
- `notes/`: working notes, design decisions, and manuscript planning.
- `figures/`: future regenerated figures.
- `results/`: generated simulation outputs, ignored by git by default.

## Initial V8 Focus

- Preserve continuity with arXiv Version 7.
- Separate the randomization-based validity engine from endpoint-specific wager policies.
- Add design-fixed wager policies for binary/event-only e-RT comparisons.
- Compare adaptive, design-fixed, and oracle wagers under correct and misspecified design effects.


# erandtest

Working repository for version 8 onward of the e-RT manuscript and code.

This repository starts from the active arXiv Version 7 materials, copied from the local archive at `/Users/fgz5335/Desktop/e-RT`. The archive is intentionally left untouched.

## Working Layout

- `manuscript/`: V8 manuscript source and copied baseline figures.
- `R/`: active R code for e-RT variants and simulations.
- `R/simulations/`: simulation scripts for V8 additions.
- `notes/`: working notes, design decisions, and manuscript planning.
- `figures/`: future regenerated figures.
- `results/`: generated simulation outputs, ignored by git by default.

## V8 Focus

- Preserve continuity with arXiv Version 7.
- Separate the randomization-based validity engine from endpoint-specific wager policies.
- Add design-fixed wager policies for binary/event-only e-RT comparisons.
- Compare adaptive, design-fixed, and oracle wagers under correct and misspecified design effects.
- Replace or deprecate the current e-RTu abstraction with a grounded pairwise win/loss method if the theory and simulations hold up.

## Current Working Threads

- e-RTb and e-RTe now have a same-enrolled-N wager-policy comparison covering adaptive, fixed under/matched/over, and oracle simulation benchmarks.
- Type I error and power are already summarized for e-RTb/e-RTe; the next diagnostic is Type M error at first e-process crossing.
- e-RTwr is the working name for the pairwise win-ratio/GPC prototype. The current prototype uses disjoint treatment-control pairs and updates wealth with `D = +1`, `-1`, or `0`.
- e-RTwr adaptive wagering currently defaults to full Kelly with burn-in 10 and ramp 50, based on 1,000-rep tuning runs.
- e-RTwr design sample sizes should use the `WRestimates`/Yu-Ganju win-ratio sample-size formula rather than the temporary normal-endpoint `power.t.test` shortcut.
- e-RTwr reporting should include final-study WR, WR at crossing, and WR exaggeration at crossing. `BuyseTest` is the likely reference implementation for all-pairs GPC/win-ratio estimates.

## R Package Notes

- `WRestimates`: win-ratio sample size, power, and confidence interval utilities. Use `wr.ss()` or an equivalent Yu-Ganju calculation for e-RTwr design sizes.
- `BuyseTest`: generalized pairwise comparisons and win-ratio estimates. Use as a reference final-study estimator when comparing sequential disjoint-pair monitoring with all-pairs GPC summaries.

## Generated Results

Simulation outputs under `results/` are intentionally ignored by git. Re-run the scripts in `R/simulations/` to regenerate them, and keep stable summaries in `notes/` or manuscript tables.

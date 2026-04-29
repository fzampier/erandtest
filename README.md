# erandtest

Version 8 working repository for the e-RT manuscript and simulation code.

e-RT, short for e-value Randomized Trial, is a family of randomization-based
sequential monitoring methods for randomized trials. The central idea is to
construct an e-process by betting on randomized assignments or predictably
formed treatment-control contrasts. Under the null hypothesis, randomization
makes the betting game fair, so the resulting wealth process controls Type I
error at arbitrary stopping times.

This repository starts from the active arXiv Version 7 materials copied from
the local archive at `/Users/fgz5335/Desktop/e-RT`. That archive is intentionally
left untouched. This repository is the clean V8-forward workspace.

## Current Scope

V8 separates two ideas that were partly blended in prior drafts:

- **Validity engine:** randomization makes treatment assignment unpredictable
  under the null.
- **Wager policy:** the rule used to choose the bet. This can be adaptive,
  fixed, design-calibrated, misspecified for stress testing, or oracle-only for
  simulation benchmarking.

The active manuscript variants are:

- `e-RTb`: binary event/no-event outcomes.
- `e-RTe`: event-only monitoring, using only event arm labels.
- `e-RTwr`: pairwise win-ratio or generalized pairwise-comparison endpoints.
- `e-RTc`: continuous outcomes.
- `e-RTs`: time-to-event outcomes.

The multi-state and universal abstractions from V7 (`e-RTms` and `e-RTu`) are
deferred from the main V8 manuscript so the paper can stay focused on the
wager-policy problem.

## Repository Layout

- `manuscript/`: canonical LaTeX source, Markdown mirror, compiled PDF,
  references, manuscript-ready figure PDFs, and generated LaTeX tables.
- `R/`: reusable endpoint modules for e-RTb, e-RTe, e-RTc, e-RTs, and e-RTwr.
- `R/simulations/`: fixed-seed simulation and manuscript-artifact generators.
- `results/`: active generated CSV outputs supporting manuscript tables,
  figures, and numerical claims.
- `notes/`: stable summaries and the reproducibility inventory.
- `AGENTS.md`, `shopping_list.md`, `CHANGELOG.md`: working context and project
  history.

Manuscript-ready PDFs intentionally live in `manuscript/` so LaTeX can include
them directly. The top-level `figures/` directory is not used.

## Reproducibility

The active manuscript is reproducible through the top-level `Makefile`:

```sh
make deps-check
make results
make figures
make manuscript
make inventory
```

For the full active build:

```sh
make all
```

The inventory in `notes/reproducibility_inventory.md` maps every active
manuscript table, figure, CSV result file, and support artifact to its generator.
Exploratory source scripts are kept in `R/simulations/`, but pilot CSV outputs
are not part of the active manuscript reproducibility chain.

## Dependencies

Run:

```sh
make deps-check
```

The lightweight checker verifies these R packages:

- `tidyverse`
- `ggplot2`
- `scales`
- `BuyseTest`
- `WRestimates`

It also verifies command-line tools:

- `pandoc`
- `latexmk`

No `renv` lockfile is used at this stage.

## Manuscript Build

The LaTeX source is canonical:

```sh
make manuscript
```

This regenerates `manuscript/e-RT_v8.md` with `pandoc` and compiles
`manuscript/e-RT_v8.pdf` with `latexmk`.

Current builds may show overfull-box warnings in wide result tables. These are
layout warnings, not build failures.

## Current Caveats

- The methods are under active development and should be read as a V8 research
  draft, not a locked software API.
- Design-calibrated wagers improve efficiency when the design alternative is
  credible, but misspecification can reduce power or inflate the apparent
  effect at crossing.
- Type M error at crossing is tracked for e-RTb, e-RTe, e-RTc, e-RTs, and
  e-RTwr because early stopping enriches for favorable random fluctuation.
  e-RTs also reports Type S sign error among crossing trials.
- e-RTwr currently uses predictable/disjoint pair updates for monitoring.
  All-pairs GPC/win-ratio summaries are final-trial descriptive comparators
  unless a dependence-safe all-pairs e-process is developed.

## GitHub

Remote:

```sh
git@github.com:fzampier/erandtest.git
```

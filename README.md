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

## Current Scientific Direction

V8 separates two ideas that were partly blended in prior drafts:

- **Validity engine:** randomization makes treatment assignment unpredictable
  under the null. This is what gives anytime-valid inference.
- **Wager policy:** the rule used to choose the bet. This can be adaptive,
  fixed, design-calibrated, misspecified for stress testing, or oracle-only
  for simulation benchmarking.

The V8 draft keeps the core e-RT family while sharpening scope:

- `e-RTb`: binary event/no-event outcomes.
- `e-RTe`: event-only monitoring, using only event arm labels.
- `e-RTc`: continuous outcomes.
- `e-RTs`: time-to-event outcomes.
- `e-RTwr`: pairwise win-ratio or generalized pairwise-comparison style
  endpoints.

The multi-state and universal abstractions from V7 (`e-RTms` and `e-RTu`) are
likely to be deprecated or moved out of the main V8 manuscript so the paper
does not become too diffuse.

## What Is New In V8 So Far

- e-RTb and e-RTe now have same-enrolled-N simulations comparing adaptive,
  design-fixed under/matched/over, and oracle benchmark wager policies.
- e-RTe Type M diagnostics now use the full randomized-trial snapshot at the
  crossing time when denominators are available, while the e-RTe e-process
  itself remains event-only.
- e-RTc now has a reusable R module. The adaptive policy preserves the
  standalone V7 sign-direction wager, and V8 adds a parametric normal-shift
  design wager based on prespecified means and SD.
- e-RTc simulations report Type I error, power, and Type M error at crossing
  on the Cohen's `d` scale.
- e-RTwr has a disjoint-pair prototype, Yu-Ganju/`WRestimates`-compatible
  design sample sizes, final-study win-ratio diagnostics, and a Sokolova-style
  GROW comparison.
- A first `BuyseTest::simBuyseTest()` composite endpoint scaffold compares
  final all-pairs GPC summaries with disjoint-pair e-RTwr monitoring.

## Repository Layout

- `manuscript/`
  - `e-RT_v8.tex`: canonical manuscript source.
  - `e-RT_v8.md`: readable Markdown mirror generated from the LaTeX source.
  - `e-RT_v8.pdf`: compiled manuscript.
  - `references.bib`: bibliography.
  - manuscript figures and generated LaTeX tables.
- `R/`
  - `ertb.R`: binary e-RTb implementation.
  - `erte.R`: event-only e-RTe implementation.
  - `ertc.R`: continuous e-RTc implementation.
  - `ertwr.R`: pairwise win-ratio/GPC prototype.
- `R/simulations/`
  - `wager_policy_comparison.R`: e-RTb/e-RTe adaptive versus design-fixed
    wager simulations.
  - `wager_policy_figures.R`: figures and manuscript tables for e-RTb/e-RTe.
  - `ertc_wager_policy.R`: e-RTc adaptive versus parametric design wager
    simulations.
  - `ertwr_pilot.R`, `ertwr_adaptive_tuning.R`, `ertwr_sokolova_comparison.R`,
    `ertwr_buysetest_check.R`, and `ertwr_composite_buysetest.R`: e-RTwr
    simulation and validation scripts.
- `notes/`
  - Stable summaries of simulation runs and design decisions.
- `results/`
  - Generated CSV outputs. This directory is ignored by git; rerun scripts to
    regenerate results.
- `AGENTS.md`
  - Working instructions and context for future Codex/research-agent sessions.
- `shopping_list.md`
  - Active add/remove/rewrite list for V8.

## Reproducibility

The main V8 simulation scripts use fixed seeds:

- e-RTb/e-RTe wager policy comparison: `set.seed(20260428)`.
- e-RTb/e-RTe figure generation: `set.seed(20260429)`.
- e-RTc wager policy comparison: `set.seed(20260430)`.

Regenerate the main V8 outputs from the repository root:

```sh
Rscript R/simulations/wager_policy_comparison.R 1000
Rscript R/simulations/wager_policy_figures.R
Rscript R/simulations/ertc_wager_policy.R 1000
Rscript R/simulations/ertwr_pilot.R 1000
Rscript R/simulations/ertwr_sokolova_comparison.R 1000
Rscript R/simulations/ertwr_composite_buysetest.R 300 250
```

The exact CSV files are not committed because `results/` is ignored. Stable
simulation summaries are committed under `notes/`, and manuscript-ready tables
and figures are committed under `manuscript/`.

## R Package Notes

Core scripts use base R plus packages already used by the V7 code, especially
`tidyverse` for older plotting/simulation helpers. Optional package-backed
checks use:

- `WRestimates`: win-ratio sample size, power, and confidence interval tools.
- `BuyseTest`: generalized pairwise comparisons, win-ratio estimates, and
  simulation helpers for composite endpoints.

The e-RTwr code has internal fallbacks for simple continuous win-ratio
calculations, with `BuyseTest` retained as an external reference/check.

## Build The Manuscript

The LaTeX source is canonical. From `manuscript/`:

```sh
latexmk -pdf -interaction=nonstopmode -halt-on-error e-RT_v8.tex
```

Regenerate the Markdown mirror:

```sh
cd manuscript
pandoc e-RT_v8.tex -f latex -t gfm --citeproc \
  --bibliography=references.bib --wrap=none -o e-RT_v8.md
```

Current builds may show a small pre-existing overfull-box warning in the
e-RTb/e-RTe wager-policy table. The PDF otherwise compiles successfully.

## Current Caveats

- The methods are under active development and should be read as a V8 research
  draft, not a locked software API.
- Design-calibrated wagers improve efficiency when the design alternative is
  credible, but misspecification can reduce power or inflate the apparent
  effect at crossing.
- Type M error at crossing is now tracked for e-RTb, e-RTe, e-RTc, and e-RTwr
  because early stopping enriches for favorable random fluctuation.
- e-RTwr currently uses predictable/disjoint pair updates for monitoring.
  All-pairs GPC/win-ratio summaries are used as final-trial descriptive
  comparators unless a dependence-safe all-pairs e-process is developed.

## GitHub

Planned remote:

```sh
git@github.com:fzampier/erandtest.git
```

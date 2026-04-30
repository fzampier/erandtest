# erandtest

Research repository for the Version 8 e-RT manuscript and simulation code. This
repo is the reproducibility companion for the V8 preprint submitted to arXiv and
the working base for a journal manuscript.

e-RT, short for e-value Randomized Trial, is a family of randomization-based
sequential monitoring methods for randomized trials. The central idea is to
construct an e-process by betting on randomized assignments or predictably
formed treatment-control contrasts. Under the null hypothesis, randomization
makes the betting game fair, so the resulting wealth process controls Type I
error at arbitrary stopping times.

This repository carries the V8-forward manuscript and code lineage. Earlier
draft material is retained only where needed for continuity; the active source
of truth is the V8 manuscript and the reproducibility chain described below.

## Start Here

- Manuscript source: `manuscript/e-RT_v8.tex`
- Compiled manuscript: `manuscript/e-RT_v8.pdf`
- Readable mirror: `manuscript/e-RT_v8.md`
- Bibliography: `manuscript/references.bib`
- Artifact map: `notes/reproducibility_inventory.md`
- Citation metadata: `CITATION.cff`

Run the active reproducibility chain from the repository root:

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

## Scientific Scope

V8 separates two ideas that were partly blended in prior drafts:

- **Validity engine:** randomization makes treatment assignment unpredictable
  under the null.
- **Wager policy:** the rule used to choose the bet. This can be adaptive,
  fixed, design-calibrated, misspecified for stress testing, or oracle-only for
  simulation benchmarking.

The default scientific position for V8 is that e-RT is effect-size agnostic:
continuous monitoring can begin without specifying a hypothesized treatment
effect. Design-calibrated wagers, including GROW-style wagers, are optional
efficiency tools when a credible clinical design alternative exists.

The active manuscript variants are:

- `e-RTb`: binary event/no-event outcomes.
- `e-RTe`: event-only monitoring, using only event arm labels.
- `e-RTc`: continuous outcomes.
- `e-RTs`: time-to-event outcomes.

The multi-state and universal abstractions from V7 (`e-RTms` and `e-RTu`) and
the pairwise win-ratio/GPC prototype are deferred from the main manuscript so
the paper can stay focused on randomization-based assignment-prediction tests.

## Repository Layout

- `manuscript/`: canonical LaTeX source, Markdown mirror, compiled PDF,
  bibliography, manuscript-ready figure PDFs, and generated LaTeX tables.
- `R/`: reusable endpoint modules for e-RTb, e-RTe, e-RTc, and e-RTs.
- `R/simulations/`: fixed-seed simulation and manuscript-artifact generators.
- `results/`: active generated CSV outputs supporting manuscript tables,
  figures, and numerical claims.
- `notes/`: stable summaries and the reproducibility inventory.
- `explorations/`: parked prototypes that are not part of the active
  manuscript reproducibility chain, including the former pairwise e-RTwr work
  and an e-RTb reciprocal-futility exploration.
- `AGENTS.md`: working instructions for future coding/research agents.
- `CHANGELOG.md`: project history.
- `shopping_list.md`: remaining research and manuscript tasks.

Manuscript-ready PDFs intentionally live in `manuscript/` so LaTeX can include
them directly. The top-level `figures/` directory is not used.

Local literature PDFs may be kept in `references/`, but that directory is
ignored by git and is not part of the public reproducibility bundle. Public
reference metadata belongs in `manuscript/references.bib` and
`notes/reference_key.md`.

## Citation

If you use this repository, please cite the manuscript:

> Zampieri FG. Sequential Randomization Tests Using e-values: Applications for
> trial monitoring. 2026.

Use `CITATION.cff` for repository/software citation metadata. Once the arXiv or
journal DOI is available, update the citation metadata and this section.

## Reproducibility

The inventory in `notes/reproducibility_inventory.md` maps every active
manuscript table, figure, CSV result file, and support artifact to its generator.
Exploratory source scripts and parked outputs live under `explorations/` and
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

The current manuscript build is expected to complete cleanly. If future table
edits introduce layout warnings, inspect the generated PDF before relying on the
artifact.

## License

Source code and scripts are released under the MIT License; see `LICENSE`.
Manuscript text, generated research artifacts, and local reference PDFs have
separate copyright and reuse considerations; see `COPYRIGHT.md`.

## Caveats

- The methods are under active development and should be read as a research
  manuscript plus reproducibility code, not a locked clinical software API.
- Design-calibrated wagers improve efficiency when the design alternative is
  credible, but they are optional modes rather than the default identity of
  e-RT. Misspecification can reduce power or inflate the apparent effect at
  crossing.
- Type M error at crossing is tracked for e-RTb, e-RTe, e-RTc, and e-RTs
  because early stopping enriches for favorable random fluctuation. e-RTs also
  reports Type S sign error among crossing trials.
- Pairwise win-ratio/GPC ideas are parked in `explorations/ertwr/`. The current
  prototype is not an active e-RT variant because it bets on pairwise outcome
  direction after treatment assignment is known, rather than betting on
  randomized assignment.
- Continuous futility monitoring for e-RTb is parked in
  `explorations/ertb_futility/` using reciprocal candidate processes for the
  null `ARR >= MCID`. These files are exploratory and not used in the active
  manuscript. The current design-calibrated candidate is baseline-specific;
  the nuisance-robust candidate is conservative but weak in the current
  simulations.

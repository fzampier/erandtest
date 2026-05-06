# erandtest

Bare-bones reproducibility repository for the Version 9 e-RT manuscript.

e-RT, short for e-value Randomized Trial, is a randomization-based continuous
monitoring framework for randomized trials. It builds e-processes by betting on
randomized assignments or observed event labels. Under the null hypothesis,
randomization makes the betting game fair, so the resulting wealth process
controls Type I error at arbitrary stopping times.

## Start Here

- Manuscript source: `manuscript/e-RT_v9.tex`
- Compiled manuscript: `manuscript/e-RT_v9.pdf`
- Readable mirror: `manuscript/e-RT_v9.md`
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

## Active Scope

The active manuscript contains three variants:

- `e-RTb`: binary event/no-event outcomes.
- `e-RTe`: event-only monitoring, using only event arm labels.
- `e-RTc`: continuous outcomes.

The manuscript separates two components:

- **Validity engine:** randomization makes treatment assignment unpredictable
  under the null.
- **Wager policy:** the rule used to choose the bet. The active code supports
  adaptive, fixed, design-calibrated, and oracle-for-simulation policies.

## Repository Layout

- `manuscript/`: canonical LaTeX source, Markdown mirror, compiled PDF,
  bibliography, manuscript-ready figure PDFs, and generated LaTeX tables.
- `R/`: reusable endpoint modules for e-RTb, e-RTe, and e-RTc.
- `R/simulations/`: fixed-seed simulation and manuscript-artifact generators.
- `results/`: generated CSV outputs supporting manuscript tables, figures, and
  numerical claims.
- `notes/`: stable summaries and the reproducibility inventory.
- `AGENTS.md`: working instructions for future coding/research agents.
- `CHANGELOG.md`: project history.

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

This regenerates `manuscript/e-RT_v9.md` with `pandoc` and compiles
`manuscript/e-RT_v9.pdf` with `latexmk`.

## License

Source code and scripts are released under the MIT License; see `LICENSE`.
Manuscript text, generated research artifacts, and local reference PDFs have
separate copyright and reuse considerations; see `COPYRIGHT.md`.

## Caveats

- The methods are under active development and should be read as a research
  manuscript plus reproducibility code, not a locked clinical software API.
- Design-calibrated wagers improve efficiency when the design alternative is
  credible, but they are optional modes rather than the default identity of
  e-RT.
- Type M error at crossing is tracked for e-RTb, e-RTe, and e-RTc because early
  stopping enriches for favorable random fluctuation.

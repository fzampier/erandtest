# AGENTS.md

Working instructions for Codex and future coding/research agents in this
repository.

## Project Identity

This repository is the V9 workspace for the e-RT manuscript and code. Keep it
focused on the active randomization-based monitoring framework and its
reproducibility chain.

The main scientific goal for V9 is to sharpen e-RT as a randomization-based
continuous monitoring framework and to separate:

- the validity engine: randomized assignment makes the betting game fair under
  the null;
- the wager policy: adaptive, fixed, design-calibrated, or
  oracle-for-simulation-only.

## Source Of Truth

- Canonical manuscript source: `manuscript/e-RT_v9.tex`.
- Readable mirror: `manuscript/e-RT_v9.md`.
- Preferred active reproducibility commands:

```sh
make deps-check
make results
make figures
make manuscript
make inventory
```

Use `make all` for the complete active chain. The artifact map lives in
`notes/reproducibility_inventory.md`.

Do not edit the Markdown mirror as the authoritative manuscript unless the user
explicitly asks for a Markdown-only drafting pass.

## Editing Principles

- Prefer small, reviewable manuscript edits.
- When adding new claims, add matching citations or notes for citations to add.
- Use direct quotes from copyrighted papers only when short and necessary;
  prefer careful paraphrase with citations.
- Be explicit when distinguishing proven validity from simulation-supported
  power.

## Active Scientific Scope

The active manuscript variants are:

- e-RTb for binary event/no-event outcomes;
- e-RTe for event-only monitoring;
- e-RTc for continuous outcomes.

The active paper should stay centered on e-RT as a randomization-based
assignment-prediction test.

Key diagnostics:

- Type M error at first e-process crossing for e-RTb and e-RTe; for e-RTe,
  report ARR from the full randomized-trial snapshot when denominators are
  available, while keeping the event-only tilt as the native monitoring scale.
- Type M error at first e-process crossing for e-RTc, reported on the Cohen's
  `d` scale.
- Crossing-time effect estimates versus final-study estimates.

## Active Code

- `R/ertb.R`: binary e-RTb module.
- `R/erte.R`: event-only e-RTe module.
- `R/ertc.R`: continuous e-RTc module.
- `R/simulations/`: active simulation and artifact-generation scripts.

Current code direction:

- Keep e-RTb support for `wager = c("adaptive", "design", "fixed", "oracle")`.
- Keep e-RTe aligned with the same wager-policy family, noting that design mode
  operates on the event-coin scale.
- Keep e-RTc aligned with the same wager-policy family, noting that design mode
  uses a normal-shift working model for `Pr(T = 1 | Y)` and is parametric by
  default.
- Keep Type M diagnostics clearly separated from the anytime-valid e-value
  claim.

Generated CSV outputs are kept under `results/`. Manuscript figures and tables
are generated into `manuscript/` by the active Makefile chain.

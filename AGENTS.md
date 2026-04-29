# AGENTS.md

Working instructions for Codex and future coding/research agents in this repository.

## Project Identity

This repository is the clean V8-forward workspace for the e-RT manuscript and code. It starts from the active arXiv Version 7 material copied from `/Users/fgz5335/Desktop/e-RT`, which is the historical archive and should remain untouched.

The main scientific goal for V8 is to sharpen e-RT as a randomization-based continuous monitoring framework and to separate:

- the validity engine: randomized assignment makes the betting game fair under the null;
- the wager policy: adaptive, fixed, design-calibrated, or oracle-for-simulation-only.

## Source Of Truth

- Canonical manuscript source: `manuscript/e-RT_v8.tex`.
- Readable mirror: `manuscript/e-RT_v8.md`.
- Regenerate the Markdown mirror after LaTeX edits with:

```sh
pandoc manuscript/e-RT_v8.tex -f latex -t gfm --citeproc --bibliography=manuscript/references.bib --wrap=none -o manuscript/e-RT_v8.md
```

Do not edit the Markdown mirror as the authoritative manuscript unless the user explicitly asks for a Markdown-only drafting pass.

## Editing Principles

- Preserve continuity with arXiv Version 7.
- Keep the old `/Users/fgz5335/Desktop/e-RT` archive untouched.
- Prefer small, reviewable manuscript edits.
- When adding new claims, add matching citations or notes for citations to add.
- Use direct quotes from copyrighted papers only when short and necessary; prefer careful paraphrase with citations.
- Be explicit when distinguishing proven validity from simulation-supported power.

## V8 Scientific Direction

V8 should introduce wager policy as a first-class design layer:

- adaptive wager: learned from accumulating data;
- fixed wager: prespecified constant;
- design-calibrated wager: derived from a design alternative, similar in spirit to GROW calibration;
- oracle wager: uses the true simulated effect and is allowed only as a simulation benchmark.

V8 should also consider replacing e-RTu with a more grounded pairwise win/loss e-process connected to generalized pairwise comparisons and win-ratio methods.

## Code Direction

Initial active code files:

- `R/ertb.R`: binary e-RTb baseline from V7.
- `R/erte.R`: event-only e-RTe baseline from V7.
- `R/simulations/`: place new V8 simulation scripts here.

Planned code changes:

- Refactor e-RTb to support `wager = c("adaptive", "design", "fixed", "oracle")`.
- Refactor e-RTe similarly, noting that design mode operates on the event-coin scale.
- Add misspecification grids comparing adaptive, design-calibrated, fixed, and oracle wagers.
- Add a separate prototype for a pairwise win/loss e-process before integrating it into the manuscript.


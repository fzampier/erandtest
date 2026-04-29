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

Key diagnostic additions for V8:

- Type M error at first e-process crossing for e-RTb and e-RTe.
- Crossing-time effect estimates versus final-study estimates.
- For e-RTwr, WR at crossing, final-study WR, and exaggeration relative to both the true/design WR and the final-study WR.

## Code Direction

Initial active code files:

- `R/ertb.R`: binary e-RTb baseline from V7.
- `R/erte.R`: event-only e-RTe baseline from V7.
- `R/ertwr.R`: pairwise win/loss e-RTwr prototype.
- `R/simulations/`: V8 simulation scripts.

Planned code changes:

- Refactor e-RTb to support `wager = c("adaptive", "design", "fixed", "oracle")`.
- Refactor e-RTe similarly, noting that design mode operates on the event-coin scale.
- Add misspecification grids comparing adaptive, design-calibrated, fixed, and oracle wagers.
- Add Type M error at crossing to e-RTb/e-RTe simulation outputs.
- Extend e-RTwr simulations to use `WRestimates`/Yu-Ganju sample sizes.
- Add e-RTwr WR diagnostics using both the sequential disjoint-pair WR and an all-pairs `BuyseTest`/GPC WR where appropriate.

## e-RTwr Conventions

The current e-RTwr prototype is intentionally conservative about dependence:

- form disjoint or predictably matched treatment-control pairs;
- let each pair contribute `D = +1` for treatment win, `D = -1` for control win, and `D = 0` for tie;
- update wealth as `W_j = W_{j-1}(1 + lambda_j D_j)`;
- use fixed/design wagers with `lambda = (WR - 1) / (WR + 1)`;
- use adaptive full Kelly by default, currently burn-in 10 and ramp 50.

Do not treat the sequential disjoint-pair WR as identical to the all-pairs GPC win ratio. The all-pairs WR is a useful final-trial descriptive/reference estimand, likely computed through `BuyseTest`, but the monitoring estimand is tied to the prespecified sequential pairing rule.

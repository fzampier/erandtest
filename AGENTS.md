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
cd manuscript && pandoc e-RT_v8.tex -f latex -t gfm --citeproc --bibliography=references.bib --wrap=none -o e-RT_v8.md
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

V8 now defers e-RTu from the active manuscript and uses e-RTwr as the more grounded pairwise win/loss e-process connected to generalized pairwise comparisons and win-ratio methods.

Key diagnostic additions for V8:

- Type M error at first e-process crossing for e-RTb and e-RTe; for e-RTe, report ARR from the full randomized-trial snapshot when denominators are available, while keeping the event-only tilt as the native monitoring scale.
- Type M error at first e-process crossing for e-RTc, reported on the Cohen's `d` scale.
- Crossing-time effect estimates versus final-study estimates.
- For e-RTwr, WR at crossing, final-study WR, and exaggeration relative to both the true/design WR and the final-study WR.
- For e-RTwr simple continuous endpoints, package-backed `BuyseTest` validation of the internal all-pairs WR estimator.
- e-RTms and e-RTu are parked as future work rather than active V8 sections.

## Code Direction

Initial active code files:

- `R/ertb.R`: binary e-RTb baseline from V7.
- `R/erte.R`: event-only e-RTe baseline from V7.
- `R/ertc.R`: continuous e-RTc V8 module, preserving the standalone V7 adaptive sign-direction wager and adding parametric normal-shift design/oracle wagers.
- `R/ertwr.R`: pairwise win/loss e-RTwr prototype.
- `R/simulations/`: V8 simulation scripts.

Current code direction:

- Refactor e-RTb to support `wager = c("adaptive", "design", "fixed", "oracle")`.
- Refactor e-RTe similarly, noting that design mode operates on the event-coin scale.
- Refactor e-RTc similarly, noting that design mode uses a normal-shift working model for `Pr(T = 1 | Y)` and is parametric by default.
- Add misspecification grids comparing adaptive, design-calibrated, fixed, and oracle wagers.
- Type M error at crossing has been added to e-RTb/e-RTe simulation outputs. The e-RTe simulation now feeds only event arm labels to the e-process but computes crossing-time ARR from the full simulated trial snapshot.
- e-RTwr simulations now use `WRestimates`/Yu-Ganju sample sizes.
- e-RTwr WR diagnostics use both the sequential disjoint-pair WR and an internal all-pairs continuous WR; `BuyseTest` is available as a validation/reference check.

## e-RTwr Conventions

The current e-RTwr prototype is intentionally conservative about dependence:

- form disjoint or predictably matched treatment-control pairs;
- let each pair contribute `D = +1` for treatment win, `D = -1` for control win, and `D = 0` for tie;
- update wealth as `W_j = W_{j-1}(1 + lambda_j D_j)`;
- use fixed/design wagers with `lambda = (WR - 1) / (WR + 1)`;
- use adaptive full Kelly by default, currently burn-in 10 and ramp 50.

Do not treat the sequential disjoint-pair WR as identical to the all-pairs GPC win ratio. The all-pairs WR is a useful final-trial descriptive/reference estimand, and `R/simulations/ertwr_buysetest_check.R` confirms agreement between the internal simple-continuous estimator and `BuyseTest`; the monitoring estimand remains tied to the prespecified sequential pairing rule.

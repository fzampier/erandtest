# Sokolova/Sokolov and evalinger Comparison

Sokolova and Sokolov present a design-calibrated e-value monitoring framework. Their binary construction uses paired outcomes and a GROW-optimal betting fraction selected from a prespecified design alternative.

The `evalinger` package exposes `eprocess_binary()` and `eprocess_logrank()` as primary e-process constructors. The binary implementation uses pairwise differences `D = X_T - X_C` and products `prod(1 + lambda * D)`. When `lambda` is missing, it is computed from design response rates.

The survival implementation uses a design hazard ratio `theta`. Its fallback implementation maps `theta` to a logrank-style betting fraction through `(1 - theta) / (1 + theta)`.

V8 framing:

> Sokolova and Sokolov represent a design-calibrated e-value approach. e-RT represents a randomization-prediction approach. The former tunes wagers to a prespecified effect; the latter can learn wagers from the trial stream, while still allowing design-fixed wager policies as an optional mode.

Connection to e-RTwr:

- The e-RTwr fixed/design wager uses the same win/loss betting scale: `lambda = (WR - 1) / (WR + 1)`.
- The current e-RTwr prototype differs by using disjoint or predictably formed treatment-control pairs for sequential monitoring.
- Classical all-pairs GPC/win-ratio estimates, likely via `BuyseTest`, should be reported as final-study comparators rather than silently treated as the same estimand.
- e-RTwr sample sizes should use the Yu-Ganju win-ratio sample-size formula, through `WRestimates` or an equivalent local implementation.

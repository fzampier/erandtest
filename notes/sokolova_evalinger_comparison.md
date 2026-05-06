# Sokolova/Sokolov and evalinger Comparison

Sokolova and Sokolov present a design-calibrated e-value monitoring framework. Their binary construction uses paired outcomes and a GROW-optimal betting fraction selected from a prespecified design alternative.

The `evalinger` package exposes design-calibrated e-process constructors. The binary implementation uses pairwise differences `D = X_T - X_C` and products `prod(1 + lambda * D)`. When `lambda` is missing, it is computed from design response rates.

V9 framing:

> Sokolova and Sokolov represent a design-calibrated e-value approach. e-RT represents a randomization-prediction approach. The former tunes wagers to a prespecified effect; the latter can learn wagers from the trial stream, while still allowing design-fixed wager policies as an optional mode.

Pairwise note:

- The former e-RTwr prototype used a related win/loss betting scale, but it is
  now parked under `explorations/ertwr/` because it bets on pairwise outcome
  direction after treatment assignment is known.
- Active V9 should use Sokolova/GROW primarily for the design-calibrated wager
  policy comparison in e-RTb, e-RTe, and e-RTc.
- Future pairwise/GPC work should be reformulated as a randomization test:
  form pairs predictably, identify the clinically preferred member from the
  outcomes, then bet whether that member was randomized to treatment.

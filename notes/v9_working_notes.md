# V9 Working Notes

Version 9 is a scope correction of the active manuscript and reproducibility
chain. The active paper now centers on e-RT as an assignment-prediction
randomization monitoring framework for:

1. e-RTb: binary event/no-event outcomes;
2. e-RTe: event-only monitoring;
3. e-RTc: continuous outcomes.

## Current Manuscript Scope

- Canonical manuscript source: `manuscript/e-RT_v9.tex`.
- Readable mirror: `manuscript/e-RT_v9.md`.
- Active generated PDF: `manuscript/e-RT_v9.pdf`.
- The current manuscript keeps the validity-engine versus wager-policy
  framing, design-calibrated wager comparisons, and Type M diagnostics for the
  active endpoint families.
- Event-only monitoring now states the needed conditional exchangeability of
  observed event labels under the null.

## Active Simulation Priorities

1. Keep e-RTb, e-RTe, and e-RTc tables synchronized between generated CSVs,
   manuscript tables, figures, and `notes/reproducibility_inventory.md`.
2. Treat burn-in, ramp, and Kelly intensity as design-stage choices, especially
   for e-RTe where the planned event stream can be short.
3. Keep design-calibrated wagers framed as optional efficiency tools, not as
   validity requirements.
4. Keep Type M diagnostics clearly separated from the anytime-valid e-value
   claim.

## Parked Explorations

- Former pairwise/GPC endpoint ideas remain under `explorations/ertwr/` and are
  not active manuscript claims.
- Reciprocal-futility work remains under `explorations/ertb_futility/` and is
  not part of `make all`.

## Journal Derivative Notes

Likely cuts for a shorter journal derivative:

- move e-RTe tuning sensitivity to supplement;
- move most didactic trajectory figures to supplement;
- compress design-wager misspecification prose after the main tables;
- shorten pairwise/GPC future work;
- defer software/API examples until a stable package interface exists.

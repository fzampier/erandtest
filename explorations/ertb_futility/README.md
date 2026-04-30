# e-RTb Reciprocal Futility Exploration

This folder contains exploratory simulations for continuous futility monitoring
in binary e-RTb. It is not part of the active V8 manuscript reproducibility
chain.

The motivating design uses a control event risk of 30%, an MCID absolute risk
reduction of 5 percentage points, and the corresponding fixed-sample
`power.prop.test` sample size for 80% power at alpha 0.05 (`N = 2502` total).

The futility target is the clinically meaningful-benefit null:

`H_F: ARR >= 0.05`

Futility is declared when a reciprocal e-process against this null crosses
`1 / alpha_f`, with `alpha_f = 0.05` by default.

The exploration compares a design-calibrated conditional likelihood-ratio
reciprocal process with a nuisance-robust conditional likelihood-ratio process
that uses only worst-case assignment-probability bounds implied by the MCID.

The 5,000-replicate run is the substantive exploratory output. At the design
baseline (`p_ctrl = 0.30`), the design-calibrated no-benefit reciprocal process
crossed for futility in 78.6% of no-benefit trials and 30.0% of 2.5pp ARR
trials, while wrong-futility crossing was 3.7% at the 5pp MCID boundary. The
nuisance-robust process had no observed wrong-futility crossings in the tested
`ARR >= MCID` scenarios, but it was much less powerful for detecting
sub-MCID benefit.

Baseline sensitivity matters. With the design-calibrated process at the 5pp
MCID boundary, wrong-futility crossing was 0.7% when `p_ctrl = 0.20`, 3.7% when
`p_ctrl = 0.30`, and 9.8% when `p_ctrl = 0.40`. Treat the design-calibrated
process as baseline-specific unless a proof or calibration strategy says
otherwise.

Run from the repository root:

```sh
Rscript explorations/ertb_futility/R/ertb_reciprocal_futility.R 20
Rscript explorations/ertb_futility/R/ertb_reciprocal_futility.R 5000
```

Primary outputs:

- `results/ertb_reciprocal_futility_5000.csv`
- `notes/ertb_reciprocal_futility_5000.md`
- `figures/ertb_reciprocal_futility_decisions_5000.pdf`
- `figures/ertb_reciprocal_futility_stopping_5000.pdf`
- `figures/ertb_reciprocal_futility_trajectories_5000.pdf`

Full trial-level CSVs can be regenerated locally but are intentionally not
tracked because they are large and not used by the active manuscript. The `_20`
files are smoke-test outputs only and should not be cited.

# Manuscript Trajectory Examples

- Base seed: `20260503`.
- Candidate panels per figure: `150`.
- Trajectories per panel: `30`.

Panels are selected deterministically. Null panels prefer no false crossings; alternative panels target crossing rates close to the relevant simulation operating characteristics.

| endpoint | scenario | figure_file | panel_seed | n_total | target_crossing_rate | crossing_rate | n_crossed | median_crossing | median_crossing_frac | median_final_evalue | q995_evalue | selection_score |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| e-RTb | Null, 10pp ARR design, 80% fixed-sample power | manuscript/traj_null_10pct_80pow.pdf | 20261504 | 712 | 0.0% | 0.0% |  0 | NA |  | 0.36 | 5.61 | 0.0000 |
| e-RTb | Null, 10pp ARR design, 90% fixed-sample power | manuscript/traj_null_10pct_90pow.pdf | 20262506 | 954 | 0.0% | 0.0% |  0 | NA |  | 0.31 | 3.45 | 0.0000 |
| e-RTb | True ARR 10pp, 80% fixed-sample power design | manuscript/traj_alt_10pct_80pow.pdf | 20263646 | 712 | 50.0% | 50.0% | 15 | 388.0 | 54.5% | 7.12 | 2380.68 | 0.0013 |
| e-RTb | True ARR 10pp, 90% fixed-sample power design | manuscript/traj_alt_10pct_90pow.pdf | 20264577 | 954 | 66.0% | 66.7% | 20 | 488.5 | 51.2% | 24.24 | 6738.73 | 0.0097 |
| e-RTe | Null event coin, 500 events | manuscript/traj_eRTe_null.pdf | 20265504 | 500 | 0.0% | 0.0% |  0 | NA |  | 0.30 | 6.20 | 0.0000 |
| e-RTe | 25% vs 20% event rates, 500 events | manuscript/traj_eRTe_alt.pdf | 20266611 | 500 | 40.0% | 40.0% | 12 | 348.5 | 69.7% | 5.80 | 6677.56 | 0.0007 |
| e-RTc | Null, matched design wager for d = 0.40 | manuscript/traj_eRTC_null_d0.4_80pow.pdf | 20267504 | 200 | 0.0% | 0.0% |  0 | NA |  | 0.02 | 6.54 | 0.0000 |
| e-RTc | True d = 0.40, matched design wager | manuscript/traj_eRTC_alt_d0.4_80pow.pdf | 20268590 | 200 | 67.0% | 66.7% | 20 | 119.0 | 59.5% | 12.81 | 1966.91 | 0.0046 |

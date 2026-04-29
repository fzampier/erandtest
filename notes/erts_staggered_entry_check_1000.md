# e-RTs Staggered-Entry Check

- Seed: `20260502`.
- Replicates per scenario: `1000`.
- Patients/events planned from log-rank default formula for HR 0.80: `631`.
- Recruitment period: `12` months.
- Control median event time in the calendar-order check: `12` months.
- Wager policy: V8 fixed 0.25 e-RTs policy with burn-in 30 and ramp 50.

## Paired Time-On-Study Identity

The same simulated trial was analyzed once as simultaneous entry and once after adding uniform staggered entry times, then subtracting entry time before analysis. These two analyses should be identical under complete follow-up.

| true_hr | max_abs_log_evalue_difference | crossing_agreement_rate |
| --- | --- | --- |
| 0.8 | 0 | 1 |
| 1 | 0 | 1 |

## Summary

| true_hr | method | n_sims | n_patients | median_events_available | crossing_rate | final_above_threshold_rate | median_crossing_event | median_final_evalue | q25_final_evalue | q75_final_evalue | median_log_final_evalue | median_final_hr |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 0.8 | Simultaneous entry, time-on-study order | 1000 | 631 | 629 | 0.66 | 0.522 | 328.5 | 22.96 | 2.702 | 185.9 | 3.134 | 0.7957 |
| 0.8 | Staggered entry, calendar-event order | 1000 | 631 | 629 | 0.644 | 0.522 | 309 | 24.79 | 2.159 | 202.2 | 3.21 | 0.7949 |
| 0.8 | Staggered entry, time-on-study order | 1000 | 631 | 629 | 0.66 | 0.522 | 328.5 | 22.96 | 2.702 | 185.9 | 3.134 | 0.7957 |
| 1 | Simultaneous entry, time-on-study order | 1000 | 631 | 630 | 0.026 | 0.001 | 289 | 0.01093 | 0.001342 | 0.08582 | -4.517 | 1.001 |
| 1 | Staggered entry, calendar-event order | 1000 | 631 | 630 | 0.036 | 0.004 | 245 | 0.01257 | 0.001482 | 0.08337 | -4.377 | 1.001 |
| 1 | Staggered entry, time-on-study order | 1000 | 631 | 630 | 0.026 | 0.001 | 289 | 0.01093 | 0.001342 | 0.08582 | -4.517 | 1.001 |

## Interpretation

The time-on-study analysis confirms only the narrow complete-follow-up simplification. It does not prove that a calendar-time monitoring process has identical operating characteristics. The calendar-event-order rows are therefore reported separately.

# e-RTwr Versus Sokolova-Style GROW Comparison, 1,000 Reps

Command:

```sh
Rscript explorations/ertwr/R/simulations/ertwr_sokolova_comparison.R 1000
```

Output:

```text
explorations/ertwr/results/ertwr_sokolova_comparison_1000.csv
```

Seed:

```r
set.seed(20260501)
```

## Framing

The `evalinger` binary e-process uses paired binary differences,

```text
D_i = X_i^T - X_i^C,
E_n = prod_i (1 + lambda D_i),
```

with a GROW/design-calibrated fixed wager. For a simple continuous WR-sign analogue with no ties, the same GROW wager is:

```math
\lambda = \frac{WR - 1}{WR + 1}.
```

This means the current fixed/design e-RTwr row is already the Sokolova-style GROW wager at the same disjoint-pair sample size. The important difference is sample-size calibration:

- e-RTwr pilot used the Yu-Ganju final WR sample size, i.e. an 80% powered final analysis size.
- A Sokolova-style e-design calibrates `Nmax` for the e-process crossing probability itself.

This comparison applies the paired e-process algebra to continuous pairwise signs. It is not a claim that `evalinger` currently implements continuous WR monitoring.

## Results

| True WR | Comparator | Pairs | Patients | N/Yu-Ganju | Null reject | Power | Median crossing |
|---:|---|---:|---:|---:|---:|---:|---:|
| 1.10 | Final all-pairs WR test | 2,305 | 4,610 | 1.00x | 5.0% | 80.0% | -- |
| 1.10 | e-RTwr adaptive | 2,305 | 4,610 | 1.00x | 4.2% | 31.4% | 1,064 |
| 1.10 | e-RTwr fixed/GROW same N | 2,305 | 4,610 | 1.00x | 3.1% | 57.3% | 1,366 |
| 1.10 | Sokolova-style GROW e-design | 3,861 | 7,722 | 1.68x | 3.9% | 80.0% | 1,644 |
| 1.20 | Final all-pairs WR test | 630 | 1,260 | 1.00x | 5.0% | 80.0% | -- |
| 1.20 | e-RTwr adaptive | 630 | 1,260 | 1.00x | 3.2% | 35.1% | 320 |
| 1.20 | e-RTwr fixed/GROW same N | 630 | 1,260 | 1.00x | 2.7% | 56.6% | 374 |
| 1.20 | Sokolova-style GROW e-design | 1,095 | 2,190 | 1.74x | 3.1% | 80.0% | 483 |
| 1.30 | Final all-pairs WR test | 305 | 610 | 1.00x | 5.0% | 80.1% | -- |
| 1.30 | e-RTwr adaptive | 305 | 610 | 1.00x | 1.8% | 36.9% | 175 |
| 1.30 | e-RTwr fixed/GROW same N | 305 | 610 | 1.00x | 2.9% | 56.7% | 181 |
| 1.30 | Sokolova-style GROW e-design | 517 | 1,034 | 1.70x | 3.6% | 80.0% | 228 |
| 1.50 | Final all-pairs WR test | 128 | 256 | 1.00x | 5.0% | 80.2% | -- |
| 1.50 | e-RTwr adaptive | 128 | 256 | 1.00x | 1.3% | 33.4% | 86 |
| 1.50 | e-RTwr fixed/GROW same N | 128 | 256 | 1.00x | 2.5% | 53.3% | 77 |
| 1.50 | Sokolova-style GROW e-design | 206 | 412 | 1.61x | 2.9% | 80.3% | 99 |

## Interpretation

The apparent power gap is mostly not a mysterious failure of the GROW wager. At the same Yu-Ganju final-test sample size, the fixed/GROW e-process reaches about 53-57% anytime power. To make the same e-process reach about 80% crossing probability, the maximum pair count must increase by about 1.6-1.7x in these simulations.

The adaptive e-RTwr row remains lower, about 31-37%, because it is paying two prices at once:

- it is an anytime monitor, not a fixed final test;
- it is effect-size agnostic and learns the wager from noisy pairwise signs.

The best V8 framing is therefore:

- e-RTwr adaptive is the agnostic monitoring mode.
- e-RTwr fixed/design is the Sokolova/GROW-style efficiency mode at a chosen sample size.
- A true Sokolova-style design should report its own e-process-calibrated `Nmax`, not borrow the final-analysis Yu-Ganju N and expect 80% crossing power.

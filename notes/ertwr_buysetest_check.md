# e-RTwr BuyseTest Cross-Check

Purpose: validate the fast internal all-pairs continuous win-ratio calculation against the package-backed `BuyseTest` implementation for simple continuous endpoints.

Command:

```sh
Rscript R/simulations/ertwr_buysetest_check.R 100 80
```

Settings:

- seed: 20260430
- true WR grid: 1.00, 1.10, 1.20, 1.30, 1.50
- 100 simulated trials per WR value
- 80 treatment-control pairs per simulated trial

Result:

| True WR | Max absolute WR difference | Max absolute log-ratio |
|---:|---:|---:|
| 1.00 | 2.22e-16 | 2.22e-16 |
| 1.10 | 2.22e-16 | 2.22e-16 |
| 1.20 | 2.22e-16 | 2.22e-16 |
| 1.30 | 2.22e-16 | 2.22e-16 |
| 1.50 | 4.44e-16 | 2.22e-16 |

Conclusion: for the simple continuous endpoint without hierarchical priorities, the internal all-pairs WR estimator agrees with `BuyseTest` to floating-point precision. The main e-RTwr simulations should continue using the internal estimator for speed, while `BuyseTest` remains the external GPC/win-ratio reference and the natural package to use when moving toward hierarchical Buyse-style endpoints.

# Composite e-RTwr / BuyseTest Simulation, 300 Reps

Command:

```sh
Rscript explorations/ertwr/R/simulations/ertwr_composite_buysetest.R 300 250
```

Output:

```text
explorations/ertwr/results/ertwr_composite_buysetest_300_250.csv
```

Seed:

```r
set.seed(20260502)
```

## Setup

This is the first package-backed composite endpoint scaffold. Data are generated with `BuyseTest::simBuyseTest()` and analyzed with `BuyseTest`.

The prioritized endpoint hierarchy is:

1. time-to-event endpoint, `TTE(eventtime, status = status, threshold = 0)`;
2. binary toxicity endpoint, `B(toxicity)`, where no toxicity is favorable;
3. continuous score endpoint, `C(score, threshold = 0)`, where higher is favorable.

The final all-pairs reference analysis uses:

```r
BuyseTest(
  treatment ~
    TTE(eventtime, status = status, threshold = 0) +
    B(toxicity) +
    C(score, threshold = 0),
  hierarchical = TRUE,
  scoring.rule = "Gehan",
  method.inference = "u-statistic"
)
```

The sequential monitor uses `getPairScore(..., cumulative = TRUE)` to extract final composite pair scores, then samples disjoint treatment-control pairs and updates:

```math
E_j = E_{j-1}(1 + \lambda_j D_j),
```

where `D_j` is the composite favorable-minus-unfavorable pair score. The fixed/design monitor uses design WR 1.30, so:

```math
\lambda = \frac{1.30 - 1}{1.30 + 1}.
```

## Scenario Parameters

Null:

- TTE scale: treatment 1.00, control 1.00;
- toxicity: treatment 30%, control 30%;
- score mean: treatment 0.00, control 0.00.

Composite alternative:

- TTE scale: treatment 1.30, control 1.00;
- toxicity: treatment 20%, control 30%;
- score mean: treatment 0.25, control 0.00.

Each replicate used 250 patients per arm.

## Results

Rates are shown with Monte Carlo standard errors in parentheses.

| Scenario | Reps | Final BuyseTest reject | Adaptive e-RTwr reject | Fixed/design e-RTwr reject | Median BuyseTest WR | Median disjoint WR | Median adaptive crossing | Median fixed crossing |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| composite_alt | 300 | 82.3% (2.2%) | 27.7% (2.6%) | 51.3% (2.9%) | 1.31 | 1.31 | 122 | 156 |
| null | 300 | 4.3% (1.2%) | 1.7% (0.7%) | 1.7% (0.7%) | 1.00 | 1.02 | 61 | 177 |

The null median crossing times are based on very few false-positive crossings and should not be interpreted substantively.

## Interpretation

This first composite endpoint simulation reproduces the same broad pattern seen in the simple continuous WR-sign simulations:

- the final all-pairs `BuyseTest` analysis is powerful at the chosen sample size;
- fixed/design e-RTwr is less powerful than final all-pairs GPC but substantially more powerful than adaptive/agnotic e-RTwr;
- adaptive e-RTwr pays a large price for not using the design WR;
- Type I error was controlled in this exploratory run.

The median final all-pairs WR and median disjoint-pair WR under the composite alternative were both about 1.31, which is encouraging: the disjoint monitor is targeting a clinically recognizable composite win tendency, even though it uses far fewer pairwise comparisons than the final all-pairs GPC analysis.

## Caveats

This is an exploratory scaffold, not a finished real-time composite monitor.

- It uses `BuyseTest` pair scores to define the composite endpoint, then samples disjoint pairs for the e-process.
- With `scoring.rule = "Gehan"`, pair scores are deterministic from pair data, which is the safest first pass for martingale thinking.
- More elaborate `BuyseTest` scoring rules, especially Peron/Efron survival-curve scoring, may depend on estimated survival curves and would need separate work before treating the resulting score as predictable in a live e-process.
- The final `BuyseTest` analysis uses all treatment-control pairs, while e-RTwr uses disjoint pairs; this is a major source of the power gap.

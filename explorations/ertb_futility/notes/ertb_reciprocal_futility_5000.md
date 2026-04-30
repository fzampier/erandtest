# e-RTb Reciprocal Futility Exploration, 5,000 Simulations

Seed: `set.seed(20260505)`.

Primary design: control event risk 30%, MCID ARR 5.0pp, total N = 2,502, efficacy alpha = 0.05, futility alpha = 0.05.

Futility target: reject `ARR >= MCID` using a reciprocal e-process.

Implemented futility processes:

- `design/no_benefit`: simple reciprocal likelihood-ratio e-process calibrated to baseline 30%, MCID boundary ARR 5pp, and no-benefit alternative.
- `design/half_mcid`: same boundary, but calibrated to a 2.5pp sub-MCID alternative.
- `robust/no_benefit`: conservative conditional-assignment reciprocal process using only worst-case bounds implied by `ARR >= MCID`; this is designed to be robust across baseline risks but is expected to be less powerful than the design-calibrated process.

Primary baseline summary (`p_ctrl = 0.30`, no-benefit futility alternative):

```
 Futility process True ARR Efficacy cross Futility cross Dual efficacy
           design    0.0pp           2.5%          78.6%          1.4%
           robust    0.0pp           2.5%           7.9%          2.2%
           design    2.5pp          10.5%          30.0%         10.4%
           robust    2.5pp          10.5%           0.3%         10.5%
           design    5.0pp          44.9%           3.7%         44.9%
           robust    5.0pp          44.9%           0.0%         44.9%
           design    7.5pp          84.6%           0.2%         84.6%
           robust    7.5pp          84.6%           0.0%         84.6%
           design   10.0pp          98.7%           0.0%         98.7%
           robust   10.0pp          98.7%           0.0%         98.7%
 Dual futility Continue Median futility Wrong futility No-cross final ARR
         78.1%    20.5%           1,104           0.0%             2.07pp
          7.4%    90.5%           2,033           0.0%             0.21pp
         29.9%    59.7%           1,338           0.0%             3.00pp
          0.3%    89.2%           1,918           0.0%             2.30pp
          3.6%    51.5%           1,174           3.7%             4.15pp
          0.0%    55.1%              --           0.0%             4.05pp
          0.2%    15.2%             684           0.2%             5.24pp
          0.0%    15.4%              --           0.0%             5.21pp
          0.0%     1.3%           1,006           0.0%             6.40pp
          0.0%     1.3%              --           0.0%             6.38pp
```

Interpretation checklist:

- Efficacy crossings are counted separately from futility crossings; futility stopping is not counted as efficacy rejection.
- `wrong_futility_rate` is the probability that the futility process crosses when the true ARR is at least the MCID.
- Design-calibrated futility is most interpretable at the design baseline. Baseline-misspecification rows are included to avoid overclaiming uniform validity.
- The robust process is the conservative candidate for a formal composite futility guarantee; it uses least-favorable conditional assignment probabilities rather than a baseline-specific model.

Output files:

- `explorations/ertb_futility/results/ertb_reciprocal_futility_5000.csv`
- `explorations/ertb_futility/results/ertb_reciprocal_futility_trials_5000.csv`
- `explorations/ertb_futility/figures/ertb_reciprocal_futility_decisions_5000.pdf`
- `explorations/ertb_futility/figures/ertb_reciprocal_futility_stopping_5000.pdf`
- `explorations/ertb_futility/figures/ertb_reciprocal_futility_trajectories_5000.pdf`

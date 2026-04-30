# =============================================================================
# Exploratory e-RTb reciprocal futility simulations
# =============================================================================
#
# Run from repository root:
#   Rscript explorations/ertb_futility/R/ertb_reciprocal_futility.R 5000
#
# Outputs:
#   explorations/ertb_futility/results/ertb_reciprocal_futility_<n_sims>.csv
#   explorations/ertb_futility/results/ertb_reciprocal_futility_trials_<n_sims>.csv
#   explorations/ertb_futility/notes/ertb_reciprocal_futility_<n_sims>.md
#   explorations/ertb_futility/figures/*.pdf

suppressPackageStartupMessages({
  source("R/ertb.R")
  library(dplyr)
  library(ggplot2)
  library(tidyr)
})

args <- commandArgs(trailingOnly = TRUE)
n_sims <- if (length(args) >= 1) as.integer(args[[1]]) else 5000L
if (is.na(n_sims) || n_sims < 1) stop("n_sims must be a positive integer")

set.seed(20260505)

out_dir <- "explorations/ertb_futility"
results_dir <- file.path(out_dir, "results")
notes_dir <- file.path(out_dir, "notes")
figures_dir <- file.path(out_dir, "figures")
dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(notes_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)

alpha_eff <- 0.05
alpha_f <- 0.05
threshold_eff <- 1 / alpha_eff
threshold_f <- 1 / alpha_f
mcid <- 0.05
design_baseline <- 0.30
design_treatment <- design_baseline - mcid
target_power <- 0.80
n_patients <- 2 * ceiling(power.prop.test(
  p1 = design_baseline,
  p2 = design_treatment,
  power = target_power,
  sig.level = alpha_eff
)$n)

baselines <- c(0.20, 0.30, 0.40)
true_arrs <- c(0, 0.025, 0.05, 0.075, 0.10)

futility_specs <- data.frame(
  futility_process = c("design", "design", "robust"),
  futility_alt = c("no_benefit", "half_mcid", "no_benefit"),
  stringsAsFactors = FALSE
)

threshold_crossing <- function(wealth, threshold) {
  crossing <- which(wealth >= threshold)
  if (length(crossing) == 0) NA_integer_ else crossing[[1]]
}

arr_estimate <- function(treatment, outcome, upto = length(treatment)) {
  if (is.na(upto) || upto < 1) return(NA_real_)
  upto <- min(length(treatment), as.integer(upto))
  idx <- seq_len(upto)
  trt <- treatment[idx] == 1
  ctrl <- treatment[idx] == 0
  if (!any(trt) || !any(ctrl)) return(NA_real_)
  mean(outcome[idx][ctrl]) - mean(outcome[idx][trt])
}

assignment_prob <- function(p_trt, p_ctrl, outcome) {
  if (outcome == 1) {
    p_trt / (p_trt + p_ctrl)
  } else {
    (1 - p_trt) / ((1 - p_trt) + (1 - p_ctrl))
  }
}

futility_alt_rates <- function(process, alt, design_baseline, mcid) {
  if (process == "robust" && alt != "no_benefit") {
    stop("Robust futility process is implemented only for no-benefit alternative")
  }

  alt_arr <- switch(
    alt,
    no_benefit = 0,
    half_mcid = mcid / 2,
    stop("Unknown futility alternative: ", alt)
  )

  c(p_ctrl = design_baseline, p_trt = design_baseline - alt_arr)
}

compute_futility_eRTb <- function(treatment, outcome,
                                  process = c("design", "robust"),
                                  alt = c("no_benefit", "half_mcid"),
                                  design_baseline = 0.30,
                                  mcid = 0.05) {
  process <- match.arg(process)
  alt <- match.arg(alt)
  n <- length(treatment)

  if (process == "robust") {
    if (alt != "no_benefit") {
      stop("Robust futility process is implemented only for no-benefit alternative")
    }

    # Under H_F: ARR >= MCID and 1:1 randomization,
    # Pr(T=1 | event) <= (1 - MCID) / (2 - MCID), and
    # Pr(T=1 | no event) >= 1 / (2 - MCID), without specifying the baseline risk.
    # These least-favorable bounds give a conservative reciprocal process.
    q_null <- ifelse(
      outcome == 1,
      (1 - mcid) / (2 - mcid),
      1 / (2 - mcid)
    )
    q_alt <- 0.5
    multipliers <- ifelse(
      treatment == 1,
      q_alt / q_null,
      (1 - q_alt) / (1 - q_null)
    )
    return(cumprod(pmax(multipliers, .Machine$double.xmin)))
  }

  alt_rates <- futility_alt_rates(process, alt, design_baseline, mcid)
  p_alt_ctrl <- alt_rates[["p_ctrl"]]
  p_alt_trt <- alt_rates[["p_trt"]]

  p_null_ctrl <- design_baseline
  p_null_trt <- design_baseline - mcid

  log_e <- numeric(n)
  running <- 0

  for (i in seq_len(n)) {
    y <- outcome[[i]]
    t <- treatment[[i]]
    q_alt <- assignment_prob(p_alt_trt, p_alt_ctrl, y)

    q_null <- assignment_prob(p_null_trt, p_null_ctrl, y)
    multiplier <- if (t == 1) {
      q_alt / q_null
    } else {
      (1 - q_alt) / (1 - q_null)
    }

    running <- running + log(pmax(multiplier, .Machine$double.xmin))
    log_e[[i]] <- running
  }

  exp(log_e)
}

dual_decision <- function(eff_cross, fut_cross) {
  if (is.na(eff_cross) && is.na(fut_cross)) return(c(decision = "continue", stop = NA))
  if (!is.na(eff_cross) && is.na(fut_cross)) return(c(decision = "efficacy", stop = eff_cross))
  if (is.na(eff_cross) && !is.na(fut_cross)) return(c(decision = "futility", stop = fut_cross))
  if (eff_cross < fut_cross) return(c(decision = "efficacy", stop = eff_cross))
  if (fut_cross < eff_cross) return(c(decision = "futility", stop = fut_cross))
  c(decision = "tie", stop = eff_cross)
}

format_pct <- function(x, digits = 1) {
  ifelse(is.na(x), "--", sprintf(paste0("%.", digits, "f%%"), 100 * x))
}

format_num <- function(x, digits = 2) {
  ifelse(is.na(x), "--", sprintf(paste0("%.", digits, "f"), x))
}

format_int <- function(x) {
  ifelse(is.na(x), "--", formatC(as.integer(round(x)), format = "d", big.mark = ","))
}

format_arr_pp <- function(x, digits = 2) {
  ifelse(is.na(x), "--", sprintf(paste0("%.", digits, "fpp"), 100 * x))
}

scenario_grid <- expand.grid(
  p_ctrl = baselines,
  true_arr = true_arrs,
  KEEP.OUT.ATTRS = FALSE
) |>
  mutate(p_trt = p_ctrl - true_arr) |>
  filter(p_trt >= 0, p_trt <= 1) |>
  arrange(p_ctrl, true_arr)

trial_rows <- vector("list", nrow(scenario_grid))
path_rows <- list()
path_counter <- 0L

for (scenario_index in seq_len(nrow(scenario_grid))) {
  scenario <- scenario_grid[scenario_index, ]
  p_ctrl <- scenario$p_ctrl
  true_arr <- scenario$true_arr
  p_trt <- scenario$p_trt

  cat(sprintf(
    "Scenario %d/%d: p_ctrl=%.2f p_trt=%.3f true ARR=%.1fpp N=%d\n",
    scenario_index, nrow(scenario_grid), p_ctrl, p_trt, 100 * true_arr,
    n_patients
  ))

  scenario_records <- vector("list", n_sims)

  for (sim in seq_len(n_sims)) {
    trial <- simulate_trial(n_patients, rate_trt = p_trt, rate_ctrl = p_ctrl)
    efficacy_wealth <- compute_eRT(
      trial$treatment,
      trial$outcome,
      burn_in = 50,
      ramp = 100,
      wager = "adaptive",
      kelly_fraction = 0.5
    )
    efficacy_crossing <- threshold_crossing(efficacy_wealth, threshold_eff)
    final_arr <- arr_estimate(trial$treatment, trial$outcome)

    futility_records <- lapply(seq_len(nrow(futility_specs)), function(j) {
      spec <- futility_specs[j, ]
      futility_wealth <- compute_futility_eRTb(
        trial$treatment,
        trial$outcome,
        process = spec$futility_process,
        alt = spec$futility_alt,
        design_baseline = design_baseline,
        mcid = mcid
      )
      futility_crossing <- threshold_crossing(futility_wealth, threshold_f)
      dd <- dual_decision(efficacy_crossing, futility_crossing)

      if (p_ctrl == design_baseline && sim <= 3 &&
          spec$futility_process == "design" &&
          spec$futility_alt == "no_benefit") {
        path_counter <<- path_counter + 1L
        path_rows[[path_counter]] <<- data.frame(
          sim = sim,
          p_ctrl = p_ctrl,
          true_arr = true_arr,
          patient = seq_len(n_patients),
          efficacy_log_e = log(pmax(efficacy_wealth, .Machine$double.xmin)),
          futility_log_e = log(pmax(futility_wealth, .Machine$double.xmin)),
          stringsAsFactors = FALSE
        )
      }

      data.frame(
        sim = sim,
        p_ctrl = p_ctrl,
        p_trt = p_trt,
        true_arr = true_arr,
        n_patients = n_patients,
        futility_process = spec$futility_process,
        futility_alt = spec$futility_alt,
        efficacy_crossing = efficacy_crossing,
        futility_crossing = futility_crossing,
        dual_decision = dd[["decision"]],
        dual_stop = as.numeric(dd[["stop"]]),
        efficacy_final_evalue = tail(efficacy_wealth, 1),
        futility_final_evalue = tail(futility_wealth, 1),
        final_arr = final_arr,
        stringsAsFactors = FALSE
      )
    })

    scenario_records[[sim]] <- bind_rows(futility_records)
  }

  trial_rows[[scenario_index]] <- bind_rows(scenario_records)
}

trial_results <- bind_rows(trial_rows)
trial_results <- trial_results |>
  mutate(
    meaningful_or_better = true_arr >= mcid,
    efficacy_crossed = !is.na(efficacy_crossing),
    futility_crossed = !is.na(futility_crossing),
    no_crossing_dual = dual_decision == "continue",
    wrong_futility = meaningful_or_better & futility_crossed,
    futility_detection = !meaningful_or_better & futility_crossed
  )

summary_results <- trial_results |>
  group_by(p_ctrl, p_trt, true_arr, futility_process, futility_alt) |>
  summarize(
    n_sims = n(),
    n_patients = first(n_patients),
    efficacy_cross_rate = mean(efficacy_crossed),
    futility_cross_rate = mean(futility_crossed),
    dual_efficacy_rate = mean(dual_decision == "efficacy"),
    dual_futility_rate = mean(dual_decision == "futility"),
    dual_tie_rate = mean(dual_decision == "tie"),
    dual_continue_rate = mean(dual_decision == "continue"),
    no_crossing_rate = mean(dual_decision == "continue"),
    median_efficacy_crossing = ifelse(any(efficacy_crossed), median(efficacy_crossing[efficacy_crossed]), NA_real_),
    median_futility_crossing = ifelse(any(futility_crossed), median(futility_crossing[futility_crossed]), NA_real_),
    median_dual_stop = ifelse(any(!is.na(dual_stop)), median(dual_stop, na.rm = TRUE), NA_real_),
    wrong_futility_rate = mean(wrong_futility),
    futility_detection_rate = mean(futility_detection),
    median_final_arr = median(final_arr),
    q25_final_arr = unname(quantile(final_arr, 0.25)),
    q75_final_arr = unname(quantile(final_arr, 0.75)),
    median_final_arr_no_crossing = ifelse(any(no_crossing_dual), median(final_arr[no_crossing_dual]), NA_real_),
    q25_final_arr_no_crossing = ifelse(any(no_crossing_dual), unname(quantile(final_arr[no_crossing_dual], 0.25)), NA_real_),
    q75_final_arr_no_crossing = ifelse(any(no_crossing_dual), unname(quantile(final_arr[no_crossing_dual], 0.75)), NA_real_),
    median_final_efficacy_e = median(efficacy_final_evalue),
    median_final_futility_e = median(futility_final_evalue),
    .groups = "drop"
  ) |>
  arrange(p_ctrl, true_arr, futility_process, futility_alt)

summary_file <- file.path(
  results_dir,
  sprintf("ertb_reciprocal_futility_%s.csv", n_sims)
)
trial_file <- file.path(
  results_dir,
  sprintf("ertb_reciprocal_futility_trials_%s.csv", n_sims)
)
write.csv(summary_results, summary_file, row.names = FALSE)
write.csv(trial_results, trial_file, row.names = FALSE)

primary_summary <- summary_results |>
  filter(p_ctrl == design_baseline, futility_alt == "no_benefit")

decision_plot_data <- trial_results |>
  filter(p_ctrl == design_baseline, futility_alt == "no_benefit") |>
  count(futility_process, true_arr, dual_decision) |>
  group_by(futility_process, true_arr) |>
  mutate(prop = n / sum(n)) |>
  ungroup()

pdf(file.path(figures_dir, sprintf("ertb_reciprocal_futility_decisions_%s.pdf", n_sims)),
    width = 9, height = 5)
print(
  ggplot(decision_plot_data, aes(x = factor(100 * true_arr), y = prop, fill = dual_decision)) +
    geom_col() +
    facet_wrap(~ futility_process) +
    scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
    labs(
      x = "True ARR (percentage points)",
      y = "Decision proportion",
      fill = "First decision",
      title = "Dual e-RTb efficacy/futility decisions",
      subtitle = "Primary baseline 30%, MCID 5pp, no-benefit futility alternative"
    ) +
    theme_minimal()
)
dev.off()

stop_plot_data <- trial_results |>
  filter(p_ctrl == design_baseline, futility_alt == "no_benefit",
         dual_decision %in% c("efficacy", "futility")) |>
  mutate(true_arr_pp = 100 * true_arr)

pdf(file.path(figures_dir, sprintf("ertb_reciprocal_futility_stopping_%s.pdf", n_sims)),
    width = 9, height = 5)
print(
  ggplot(stop_plot_data, aes(x = factor(true_arr_pp), y = dual_stop, fill = dual_decision)) +
    geom_boxplot(outlier.alpha = 0.15) +
    facet_wrap(~ futility_process) +
    labs(
      x = "True ARR (percentage points)",
      y = "Stopping patient",
      fill = "First decision",
      title = "Stopping times under dual e-RTb monitoring"
    ) +
    theme_minimal()
)
dev.off()

if (length(path_rows) > 0) {
  path_data <- bind_rows(path_rows) |>
    pivot_longer(
      cols = c(efficacy_log_e, futility_log_e),
      names_to = "process",
      values_to = "log_e"
    ) |>
    mutate(
      process = recode(
        process,
        efficacy_log_e = "Efficacy e-process",
        futility_log_e = "Futility reciprocal e-process"
      ),
      panel = sprintf("ARR %.1fpp, sim %d", 100 * true_arr, sim)
    )

  pdf(file.path(figures_dir, sprintf("ertb_reciprocal_futility_trajectories_%s.pdf", n_sims)),
      width = 10, height = 8)
  print(
    ggplot(path_data, aes(x = patient, y = log_e, color = process)) +
      geom_line(alpha = 0.9, linewidth = 0.35) +
      geom_hline(yintercept = log(threshold_eff), linetype = "dashed") +
      facet_wrap(~ panel, scales = "free_y") +
      labs(
        x = "Patient",
        y = "log e-value",
        color = NULL,
        title = "Representative efficacy and futility e-process trajectories",
        subtitle = "Design-calibrated reciprocal futility process, no-benefit alternative"
      ) +
      theme_minimal()
  )
  dev.off()
}

primary_table <- primary_summary |>
  transmute(
    `Futility process` = futility_process,
    `True ARR` = sprintf("%.1fpp", 100 * true_arr),
    `Efficacy cross` = format_pct(efficacy_cross_rate),
    `Futility cross` = format_pct(futility_cross_rate),
    `Dual efficacy` = format_pct(dual_efficacy_rate),
    `Dual futility` = format_pct(dual_futility_rate),
    `Continue` = format_pct(dual_continue_rate),
    `Median futility` = format_int(median_futility_crossing),
    `Wrong futility` = format_pct(wrong_futility_rate),
    `No-cross final ARR` = format_arr_pp(median_final_arr_no_crossing)
  )

notes_file <- file.path(
  notes_dir,
  sprintf("ertb_reciprocal_futility_%s.md", n_sims)
)

notes_lines <- c(
  sprintf("# e-RTb Reciprocal Futility Exploration, %s Simulations", format_int(n_sims)),
  "",
  "Seed: `set.seed(20260505)`.",
  "",
  sprintf("Primary design: control event risk %.0f%%, MCID ARR %.1fpp, total N = %s, efficacy alpha = %.2f, futility alpha = %.2f.",
          100 * design_baseline, 100 * mcid, format_int(n_patients), alpha_eff, alpha_f),
  "",
  "Futility target: reject `ARR >= MCID` using a reciprocal e-process.",
  "",
  "Implemented futility processes:",
  "",
  "- `design/no_benefit`: simple reciprocal likelihood-ratio e-process calibrated to baseline 30%, MCID boundary ARR 5pp, and no-benefit alternative.",
  "- `design/half_mcid`: same boundary, but calibrated to a 2.5pp sub-MCID alternative.",
  "- `robust/no_benefit`: conservative conditional-assignment reciprocal process using only worst-case bounds implied by `ARR >= MCID`; this is designed to be robust across baseline risks but is expected to be less powerful than the design-calibrated process.",
  "",
  "Primary baseline summary (`p_ctrl = 0.30`, no-benefit futility alternative):",
  "",
  "```",
  paste(capture.output(print(as.data.frame(primary_table), row.names = FALSE)), collapse = "\n"),
  "```",
  "",
  "Interpretation checklist:",
  "",
  "- Efficacy crossings are counted separately from futility crossings; futility stopping is not counted as efficacy rejection.",
  "- `wrong_futility_rate` is the probability that the futility process crosses when the true ARR is at least the MCID.",
  "- Design-calibrated futility is most interpretable at the design baseline. Baseline-misspecification rows are included to avoid overclaiming uniform validity.",
  "- The robust process is the conservative candidate for a formal composite futility guarantee; it uses least-favorable conditional assignment probabilities rather than a baseline-specific model.",
  "",
  "Output files:",
  "",
  sprintf("- `%s`", summary_file),
  sprintf("- `%s`", trial_file),
  sprintf("- `%s`", file.path(figures_dir, sprintf("ertb_reciprocal_futility_decisions_%s.pdf", n_sims))),
  sprintf("- `%s`", file.path(figures_dir, sprintf("ertb_reciprocal_futility_stopping_%s.pdf", n_sims))),
  sprintf("- `%s`", file.path(figures_dir, sprintf("ertb_reciprocal_futility_trajectories_%s.pdf", n_sims)))
)

writeLines(notes_lines, notes_file)

cat(sprintf("Saved %s\n", summary_file))
cat(sprintf("Saved %s\n", trial_file))
cat(sprintf("Saved %s\n", notes_file))
cat("Saved figures in ", figures_dir, "\n", sep = "")

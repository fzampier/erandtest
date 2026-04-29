# =============================================================================
# V8 e-RTs Staggered-Entry Checks
# =============================================================================
#
# This script keeps the staggered-entry simulation inside the standalone V8
# repository. It separates two questions:
#
#   1. Complete-follow-up, time-on-study analysis:
#      If the same trial is given staggered entry times and analyzed using
#      event time minus entry time, the e-RTs stream is identical to the
#      simultaneous-entry stream.
#
#   2. Calendar-order staggered monitoring:
#      If events are processed in the order in which they occur on calendar
#      time, risk sets contain only patients who have already entered. This is
#      the more realistic real-time monitoring check and is reported separately.
#
# Run:
#   Rscript R/simulations/erts_staggered_entry_check.R 1000
#
# Outputs:
#   results/erts_staggered_entry_check_<n_sims>.csv
#   results/erts_staggered_entry_summary_<n_sims>.csv
#   notes/erts_staggered_entry_check_<n_sims>.md
#   manuscript/supp_staggered_equivalence.pdf

suppressPackageStartupMessages(source("R/erts.R"))

dir.create("results", showWarnings = FALSE)
dir.create("notes", showWarnings = FALSE)
dir.create("manuscript", showWarnings = FALSE)

args <- commandArgs(trailingOnly = TRUE)
n_sims <- if (length(args) >= 1) as.integer(args[[1]]) else 1000L
if (is.na(n_sims) || n_sims < 1) stop("n_sims must be a positive integer")

set.seed(20260502)

alpha <- 0.05
threshold <- 1 / alpha
planning_hr <- 0.80
n_patients <- logrank_design_events(planning_hr, target_power = 0.80, alpha = alpha)
recruit_period <- 12
baseline_hazard <- log(2) / 12

wager_args <- list(
  wager = "fixed",
  fixed_lambda = 0.25,
  burn_in = 30,
  ramp = 50,
  alpha = alpha
)

calendar_logrank_stream <- function(entry_time, followup_time, status, treatment) {
  if (length(entry_time) != length(followup_time) ||
      length(entry_time) != length(status) ||
      length(entry_time) != length(treatment)) {
    stop("entry_time, followup_time, status, and treatment must have the same length")
  }

  if (is.factor(treatment)) treatment <- as.numeric(treatment) - 1
  treatment <- as.numeric(treatment)
  status <- as.integer(status)
  calendar_stop_time <- entry_time + followup_time

  event_rows <- which(status == 1L)
  event_rows <- event_rows[order(calendar_stop_time[event_rows], event_rows)]

  rows <- lapply(seq_along(event_rows), function(j) {
    idx <- event_rows[[j]]
    t_j <- calendar_stop_time[[idx]]
    at_risk <- entry_time <= t_j & calendar_stop_time >= t_j
    risk_total <- sum(at_risk)
    risk_trt <- sum(treatment[at_risk] == 1)
    p_event_trt <- risk_trt / risk_total

    data.frame(
      event = j,
      time = t_j,
      x = treatment[[idx]],
      p = p_event_trt,
      u = treatment[[idx]] - p_event_trt,
      v = p_event_trt * (1 - p_event_trt),
      risk_total = risk_total,
      risk_trt = risk_trt
    )
  })

  out <- do.call(rbind, rows)
  out[out$v > 0, , drop = FALSE]
}

run_stream <- function(stream) {
  do.call(compute_eRTs_stream, c(list(stream = stream), wager_args))
}

run_time_on_study <- function(time, status, treatment) {
  do.call(compute_eRTs, c(
    list(time = time, status = status, treatment = treatment),
    wager_args
  ))
}

record_result <- function(sim, true_hr, method, res) {
  data.frame(
    sim = sim,
    true_hr = true_hr,
    method = method,
    n_patients = n_patients,
    n_events_available = nrow(res$path),
    crossed = !is.na(res$crossed_at),
    crossing_event = res$crossed_at,
    final_evalue = res$final_wealth,
    log_final_evalue = log(res$final_wealth),
    final_log_hr = res$final_log_hr,
    final_hr = res$final_hr,
    stringsAsFactors = FALSE
  )
}

run_one_sim <- function(sim, true_hr) {
  trial <- simulate_trial_survival(
    n = n_patients,
    hr = true_hr,
    baseline_hazard = baseline_hazard
  )
  entry_time <- runif(n_patients, 0, recruit_period)
  calendar_event_time <- entry_time + trial$time
  calculated_study_time <- calendar_event_time - entry_time

  res_simultaneous <- run_time_on_study(
    trial$time,
    trial$status,
    trial$treatment
  )
  res_staggered_study_time <- run_time_on_study(
    calculated_study_time,
    trial$status,
    trial$treatment
  )
  res_staggered_calendar <- run_stream(calendar_logrank_stream(
    entry_time = entry_time,
    followup_time = trial$time,
    status = trial$status,
    treatment = trial$treatment
  ))

  rbind(
    record_result(
      sim,
      true_hr,
      "Simultaneous entry, time-on-study order",
      res_simultaneous
    ),
    record_result(
      sim,
      true_hr,
      "Staggered entry, time-on-study order",
      res_staggered_study_time
    ),
    record_result(
      sim,
      true_hr,
      "Staggered entry, calendar-event order",
      res_staggered_calendar
    )
  )
}

median_na <- function(x) {
  if (length(x) == 0 || all(is.na(x))) NA_real_ else median(x, na.rm = TRUE)
}

quantile_na <- function(x, prob) {
  if (length(x) == 0 || all(is.na(x))) {
    NA_real_
  } else {
    unname(quantile(x, prob, na.rm = TRUE))
  }
}

summarize_results <- function(records) {
  groups <- split(records, list(records$true_hr, records$method), drop = TRUE)
  rows <- lapply(groups, function(d) {
    data.frame(
      true_hr = unique(d$true_hr),
      method = unique(d$method),
      n_sims = nrow(d),
      n_patients = unique(d$n_patients),
      median_events_available = median_na(d$n_events_available),
      crossing_rate = mean(d$crossed),
      final_above_threshold_rate = mean(d$final_evalue >= threshold),
      median_crossing_event = median_na(d$crossing_event[d$crossed]),
      median_final_evalue = median_na(d$final_evalue),
      q25_final_evalue = quantile_na(d$final_evalue, 0.25),
      q75_final_evalue = quantile_na(d$final_evalue, 0.75),
      median_log_final_evalue = median_na(d$log_final_evalue),
      median_final_hr = median_na(d$final_hr),
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out[order(out$true_hr, out$method), ]
}

markdown_table <- function(df) {
  formatted <- df
  numeric_cols <- vapply(formatted, is.numeric, logical(1))
  formatted[numeric_cols] <- lapply(formatted[numeric_cols], function(x) {
    ifelse(is.na(x), "", sprintf("%.4g", x))
  })

  header <- paste(names(formatted), collapse = " | ")
  divider <- paste(rep("---", ncol(formatted)), collapse = " | ")
  rows <- apply(formatted, 1, paste, collapse = " | ")
  c(paste0("| ", header, " |"), paste0("| ", divider, " |"), paste0("| ", rows, " |"))
}

cat(sprintf(
  "Running e-RTs staggered-entry checks: n_sims=%d, n_patients=%d, planning HR=%.2f\n",
  n_sims, n_patients, planning_hr
))

records <- list()
k <- 1L
for (true_hr in c(1.00, planning_hr)) {
  cat(sprintf("\nScenario true HR=%.2f\n", true_hr))
  for (sim in seq_len(n_sims)) {
    if (sim %% 100 == 0) cat(sprintf("  simulated %d / %d\n", sim, n_sims))
    records[[k]] <- run_one_sim(sim, true_hr)
    k <- k + 1L
  }
}

records <- do.call(rbind, records)
summary <- summarize_results(records)

paired_wide <- merge(
  subset(
    records,
    method == "Simultaneous entry, time-on-study order",
    c("sim", "true_hr", "log_final_evalue", "crossed", "crossing_event")
  ),
  subset(
    records,
    method == "Staggered entry, time-on-study order",
    c("sim", "true_hr", "log_final_evalue", "crossed", "crossing_event")
  ),
  by = c("sim", "true_hr"),
  suffixes = c("_simultaneous", "_staggered")
)

paired_check <- data.frame(
  true_hr = sort(unique(paired_wide$true_hr)),
  max_abs_log_evalue_difference = vapply(
    sort(unique(paired_wide$true_hr)),
    function(hr) {
      d <- paired_wide[paired_wide$true_hr == hr, ]
      max(abs(d$log_final_evalue_simultaneous - d$log_final_evalue_staggered))
    },
    numeric(1)
  ),
  crossing_agreement_rate = vapply(
    sort(unique(paired_wide$true_hr)),
    function(hr) {
      d <- paired_wide[paired_wide$true_hr == hr, ]
      mean(
        d$crossed_simultaneous == d$crossed_staggered &
          ifelse(
            is.na(d$crossing_event_simultaneous) & is.na(d$crossing_event_staggered),
            TRUE,
            d$crossing_event_simultaneous == d$crossing_event_staggered
          )
      )
    },
    numeric(1)
  ),
  stringsAsFactors = FALSE
)

records_file <- sprintf("results/erts_staggered_entry_check_%s.csv", n_sims)
summary_file <- sprintf("results/erts_staggered_entry_summary_%s.csv", n_sims)
note_file <- sprintf("notes/erts_staggered_entry_check_%s.md", n_sims)

write.csv(records, records_file, row.names = FALSE)
write.csv(summary, summary_file, row.names = FALSE)

note_lines <- c(
  "# e-RTs Staggered-Entry Check",
  "",
  sprintf("- Seed: `%d`.", 20260502),
  sprintf("- Replicates per scenario: `%d`.", n_sims),
  sprintf("- Patients/events planned from log-rank default formula for HR 0.80: `%d`.", n_patients),
  sprintf("- Recruitment period: `%s` months.", recruit_period),
  sprintf("- Control median event time in the calendar-order check: `%s` months.", round(log(2) / baseline_hazard, 3)),
  "- Wager policy: V8 fixed 0.25 e-RTs policy with burn-in 30 and ramp 50.",
  "",
  "## Paired Time-On-Study Identity",
  "",
  "The same simulated trial was analyzed once as simultaneous entry and once after adding uniform staggered entry times, then subtracting entry time before analysis. These two analyses should be identical under complete follow-up.",
  "",
  markdown_table(paired_check),
  "",
  "## Summary",
  "",
  markdown_table(summary),
  "",
  "## Interpretation",
  "",
  "The time-on-study analysis confirms only the narrow complete-follow-up simplification. It does not prove that a calendar-time monitoring process has identical operating characteristics. The calendar-event-order rows are therefore reported separately."
)
writeLines(note_lines, note_file)

if (requireNamespace("ggplot2", quietly = TRUE)) {
  alt_records <- subset(records, true_hr == planning_hr)
  p <- ggplot2::ggplot(
    alt_records,
    ggplot2::aes(x = final_evalue, fill = method, color = method)
  ) +
    ggplot2::geom_density(alpha = 0.22, linewidth = 0.4) +
    ggplot2::scale_x_log10() +
    ggplot2::labs(
      title = "e-RTs Staggered-Entry Check",
      subtitle = sprintf("Final e-values under HR %.2f, N = %d, %d simulations", planning_hr, n_patients, n_sims),
      x = "Final e-value (log scale)",
      y = "Density"
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(legend.position = "bottom", legend.title = ggplot2::element_blank())

  ggplot2::ggsave(
    "manuscript/supp_staggered_equivalence.pdf",
    p,
    width = 8,
    height = 5
  )
}

cat("\nPaired time-on-study identity check:\n")
print(paired_check)
cat("\nSummary:\n")
print(summary)
cat(sprintf("\nWrote %s\nWrote %s\nWrote %s\n", records_file, summary_file, note_file))

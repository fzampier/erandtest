# =============================================================================
# V9 Manuscript Trajectory Examples
# =============================================================================
#
# Rebuilds the didactic trajectory figures used in the manuscript. The panels
# are selected deterministically from candidate fixed-seed panels so that the
# examples are representative: null panels avoid false crossings when possible,
# and alternative panels show crossing rates close to the corresponding
# simulation operating characteristics.
#
# Run:
#   Rscript R/simulations/manuscript_trajectory_examples.R
#
# Outputs:
#   manuscript/traj_null_10pct_80pow.pdf
#   manuscript/traj_null_10pct_90pow.pdf
#   manuscript/traj_alt_10pct_80pow.pdf
#   manuscript/traj_alt_10pct_90pow.pdf
#   manuscript/traj_eRTe_null.pdf
#   manuscript/traj_eRTe_alt.pdf
#   manuscript/traj_eRTC_null_d0.4_80pow.pdf
#   manuscript/traj_eRTC_alt_d0.4_80pow.pdf
#   results/manuscript_trajectory_examples.csv
#   notes/manuscript_trajectory_examples.md

suppressPackageStartupMessages({
  source("R/ertb.R")
  source("R/erte.R")
  source("R/ertc.R")
  library(ggplot2)
  library(scales)
})

dir.create("manuscript", showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)
dir.create("notes", showWarnings = FALSE)

alpha <- 0.05
threshold <- 1 / alpha
n_traces <- 30
n_candidates <- 150
base_seed <- 20260503
visible_evalue_ceiling <- 1e4

theme_ert <- function() {
  theme_minimal(base_size = 11) +
    theme(
      plot.title = element_text(face = "bold", size = 11),
      plot.subtitle = element_text(size = 9, color = "gray30"),
      axis.title = element_text(size = 9),
      axis.text = element_text(size = 8),
      legend.position = "bottom",
      legend.title = element_blank(),
      legend.text = element_text(size = 8),
      panel.grid.minor = element_blank()
    )
}

crossing_index <- function(wealth) {
  idx <- which(wealth >= threshold)
  if (length(idx) == 0) NA_integer_ else idx[[1]]
}

evalue_labels <- function(x) {
  vapply(x, function(z) {
    if (!is.finite(z)) return("")
    if (z < 1) return(formatC(z, format = "fg", digits = 2))
    formatC(z, format = "f", digits = 0, big.mark = ",")
  }, character(1))
}

stack_traces <- function(traces, endpoint, scenario, panel_seed, n_total) {
  do.call(
    rbind,
    lapply(seq_along(traces), function(i) {
      wealth <- traces[[i]]
      crossed_at <- crossing_index(wealth)
      data.frame(
        endpoint = endpoint,
        scenario = scenario,
        panel_seed = panel_seed,
        trial = i,
        index = seq_along(wealth),
        n_total = n_total,
        wealth = wealth,
        crossed_at = crossed_at,
        crossed = !is.na(crossed_at),
        stringsAsFactors = FALSE
      )
    })
  )
}

summarize_panel <- function(df, target_crossing_rate) {
  by_trial <- unique(df[, c("trial", "crossed", "crossed_at", "n_total")])
  final_evalues <- vapply(
    split(df, df$trial),
    function(d) d$wealth[which.max(d$index)],
    numeric(1)
  )
  crossed <- by_trial$crossed
  crossing_rate <- mean(crossed)
  median_crossing <- if (any(crossed)) {
    median(by_trial$crossed_at[crossed], na.rm = TRUE)
  } else {
    NA_real_
  }
  median_crossing_frac <- if (any(crossed)) {
    median(by_trial$crossed_at[crossed] / by_trial$n_total[crossed], na.rm = TRUE)
  } else {
    NA_real_
  }

  data.frame(
    endpoint = unique(df$endpoint),
    scenario = unique(df$scenario),
    panel_seed = unique(df$panel_seed),
    n_traces = length(unique(df$trial)),
    n_total = unique(df$n_total)[[1]],
    target_crossing_rate = target_crossing_rate,
    crossing_rate = crossing_rate,
    n_crossed = sum(crossed),
    median_crossing = median_crossing,
    median_crossing_frac = median_crossing_frac,
    median_final_evalue = median(final_evalues, na.rm = TRUE),
    q995_evalue = unname(quantile(df$wealth, 0.995, na.rm = TRUE)),
    stringsAsFactors = FALSE
  )
}

score_panel <- function(summary, target_crossing_rate,
                        target_crossing_frac = NA_real_,
                        prefer_no_null_crossing = FALSE) {
  score <- abs(summary$crossing_rate - target_crossing_rate)
  if (prefer_no_null_crossing && summary$crossing_rate > 0) {
    score <- score + 10 * summary$crossing_rate
  }
  if (is.finite(target_crossing_frac) && is.finite(summary$median_crossing_frac)) {
    score <- score + 0.25 * abs(summary$median_crossing_frac - target_crossing_frac)
  }
  if (is.finite(summary$q995_evalue) && summary$q995_evalue > visible_evalue_ceiling) {
    score <- score + 0.05 * log10(summary$q995_evalue / visible_evalue_ceiling)
  }
  score
}

select_panel <- function(make_trace, endpoint, scenario, n_total,
                         target_crossing_rate,
                         target_crossing_frac = NA_real_,
                         prefer_no_null_crossing = FALSE,
                         seed_offset = 0) {
  best <- NULL
  best_score <- Inf
  best_summary <- NULL

  for (candidate in seq_len(n_candidates)) {
    panel_seed <- base_seed + seed_offset + candidate
    set.seed(panel_seed)
    traces <- lapply(seq_len(n_traces), function(i) make_trace())
    df <- stack_traces(traces, endpoint, scenario, panel_seed, n_total)
    summary <- summarize_panel(df, target_crossing_rate)
    score <- score_panel(
      summary,
      target_crossing_rate = target_crossing_rate,
      target_crossing_frac = target_crossing_frac,
      prefer_no_null_crossing = prefer_no_null_crossing
    )
    if (score < best_score) {
      best <- df
      best_score <- score
      best_summary <- summary
      best_summary$selection_score <- score
    }
  }

  list(data = best, summary = best_summary)
}

trajectory_plot <- function(df, title, subtitle, x_label) {
  line_df <- unique(df[, c("trial", "crossed")])
  line_df$cross_status <- ifelse(line_df$crossed, "Crossed", "Did not cross")
  has_crossed <- any(line_df$crossed)
  df <- merge(df, line_df[, c("trial", "cross_status")], by = "trial")
  df$cross_status <- factor(df$cross_status, levels = c("Did not cross", "Crossed"))
  y_upper <- max(1e4, 10^ceiling(log10(max(df$wealth, na.rm = TRUE))))
  y_upper <- min(y_upper, 1e5)
  y_breaks <- sort(unique(c(1e-3, 1e-2, 1e-1, 1, threshold, 1e2, 1e3, 1e4, y_upper)))

  p <- ggplot(df, aes(x = index, y = wealth, group = trial, color = cross_status)) +
    geom_line(alpha = 0.58, linewidth = 0.38) +
    geom_hline(yintercept = threshold, linetype = "dashed", color = "#B3261E", linewidth = 0.45) +
    geom_hline(yintercept = 1, linetype = "dotted", color = "gray45", linewidth = 0.4) +
    scale_color_manual(
      values = c("Did not cross" = "#667085", "Crossed" = "#007C89"),
      drop = TRUE
    ) +
    scale_y_log10(
      breaks = y_breaks,
      labels = evalue_labels
    ) +
    coord_cartesian(ylim = c(1e-3, y_upper)) +
    labs(
      title = title,
      subtitle = subtitle,
      x = x_label,
      y = "E-value (log scale)"
    ) +
    theme_ert()

  if (!has_crossed) {
    p <- p + theme(legend.position = "none")
  }

  p
}

save_panel <- function(panel, file, title, scenario_text, x_label) {
  summary <- panel$summary
  subtitle <- sprintf(
    "%s; %d/%d crossed; median final E = %.2f",
    scenario_text,
    summary$n_crossed,
    summary$n_traces,
    summary$median_final_evalue
  )

  ggsave(
    file,
    trajectory_plot(panel$data, title, subtitle, x_label),
    width = 5.6,
    height = 4.1
  )
}

make_ertb_trace <- function(n_patients, p_ctrl, p_trt,
                            burn_in = 50, ramp = 100) {
  trial <- simulate_trial(n_patients, rate_trt = p_trt, rate_ctrl = p_ctrl)
  compute_eRT(
    trial$treatment,
    trial$outcome,
    burn_in = burn_in,
    ramp = ramp,
    wager = "adaptive"
  )
}

ertb_n <- function(arr, target_power) {
  ss <- power.prop.test(
    p1 = 0.40,
    p2 = 0.40 - arr,
    power = target_power,
    sig.level = alpha
  )
  2 * ceiling(ss$n)
}

make_erte_trace <- function(n_events, p_event_trt) {
  arms <- simulate_events(n_events, p_event_trt)
  compute_eRTe(
    arms,
    burn_in = 30,
    ramp = 50,
    threshold = threshold,
    wager = "adaptive"
  )$wealth
}

make_ertc_trace <- function(n_patients, true_d, design_d = 0.40) {
  trial <- simulate_trial_continuous(
    n = n_patients,
    mu_ctrl = 0,
    mu_trt = true_d,
    sd = 1
  )
  compute_eRTc(
    trial$treatment,
    trial$outcome,
    burn_in = 20,
    ramp = 50,
    wager = "design",
    mu_ctrl_design = 0,
    mu_trt_design = design_d,
    sd_design = 1
  )
}

panels <- list()

n_ertb_80 <- ertb_n(arr = 0.10, target_power = 0.80)
n_ertb_90 <- ertb_n(arr = 0.10, target_power = 0.90)

panels$ertb_null_80 <- select_panel(
  make_trace = function() make_ertb_trace(n_ertb_80, p_ctrl = 0.40, p_trt = 0.40),
  endpoint = "e-RTb",
  scenario = "Null, 10pp ARR design, 80% fixed-sample power",
  n_total = n_ertb_80,
  target_crossing_rate = 0,
  prefer_no_null_crossing = TRUE,
  seed_offset = 1000
)

panels$ertb_null_90 <- select_panel(
  make_trace = function() make_ertb_trace(n_ertb_90, p_ctrl = 0.40, p_trt = 0.40),
  endpoint = "e-RTb",
  scenario = "Null, 10pp ARR design, 90% fixed-sample power",
  n_total = n_ertb_90,
  target_crossing_rate = 0,
  prefer_no_null_crossing = TRUE,
  seed_offset = 2000
)

panels$ertb_alt_80 <- select_panel(
  make_trace = function() make_ertb_trace(n_ertb_80, p_ctrl = 0.40, p_trt = 0.30),
  endpoint = "e-RTb",
  scenario = "True ARR 10pp, 80% fixed-sample power design",
  n_total = n_ertb_80,
  target_crossing_rate = 0.50,
  target_crossing_frac = 0.55,
  seed_offset = 3000
)

panels$ertb_alt_90 <- select_panel(
  make_trace = function() make_ertb_trace(n_ertb_90, p_ctrl = 0.40, p_trt = 0.30),
  endpoint = "e-RTb",
  scenario = "True ARR 10pp, 90% fixed-sample power design",
  n_total = n_ertb_90,
  target_crossing_rate = 0.66,
  target_crossing_frac = 0.50,
  seed_offset = 4000
)

n_erte_events <- 500
p_erte_alt <- event_coin(0.25, 0.20)

panels$erte_null <- select_panel(
  make_trace = function() make_erte_trace(n_erte_events, p_event_trt = 0.50),
  endpoint = "e-RTe",
  scenario = "Null event coin, 500 events",
  n_total = n_erte_events,
  target_crossing_rate = 0,
  prefer_no_null_crossing = TRUE,
  seed_offset = 5000
)

panels$erte_alt <- select_panel(
  make_trace = function() make_erte_trace(n_erte_events, p_event_trt = p_erte_alt),
  endpoint = "e-RTe",
  scenario = "25% vs 20% event rates, 500 events",
  n_total = n_erte_events,
  target_crossing_rate = 0.40,
  target_crossing_frac = 0.70,
  seed_offset = 6000
)

n_ertc <- design_n_continuous(0.40, target_power = 0.80, alpha = alpha)

panels$ertc_null <- select_panel(
  make_trace = function() make_ertc_trace(n_ertc, true_d = 0, design_d = 0.40),
  endpoint = "e-RTc",
  scenario = "Null, matched design wager for d = 0.40",
  n_total = n_ertc,
  target_crossing_rate = 0,
  prefer_no_null_crossing = TRUE,
  seed_offset = 7000
)

panels$ertc_alt <- select_panel(
  make_trace = function() make_ertc_trace(n_ertc, true_d = 0.40, design_d = 0.40),
  endpoint = "e-RTc",
  scenario = "True d = 0.40, matched design wager",
  n_total = n_ertc,
  target_crossing_rate = 0.67,
  target_crossing_frac = 0.60,
  seed_offset = 8000
)

save_panel(
  panels$ertb_null_80,
  "manuscript/traj_null_10pct_80pow.pdf",
  "e-RTb null example",
  "40% vs 40%, N = 712",
  "Patient"
)
save_panel(
  panels$ertb_null_90,
  "manuscript/traj_null_10pct_90pow.pdf",
  "e-RTb null example",
  "40% vs 40%, N = 954",
  "Patient"
)
save_panel(
  panels$ertb_alt_80,
  "manuscript/traj_alt_10pct_80pow.pdf",
  "e-RTb alternative example",
  "40% vs 30%, N = 712",
  "Patient"
)
save_panel(
  panels$ertb_alt_90,
  "manuscript/traj_alt_10pct_90pow.pdf",
  "e-RTb alternative example",
  "40% vs 30%, N = 954",
  "Patient"
)
save_panel(
  panels$erte_null,
  "manuscript/traj_eRTe_null.pdf",
  "e-RTe null example",
  "event coin = 0.50, 500 events",
  "Event"
)
save_panel(
  panels$erte_alt,
  "manuscript/traj_eRTe_alt.pdf",
  "e-RTe alternative example",
  sprintf("event coin = %.3f, 500 events", p_erte_alt),
  "Event"
)
save_panel(
  panels$ertc_null,
  "manuscript/traj_eRTC_null_d0.4_80pow.pdf",
  "e-RTc null example",
  sprintf("matched design wager d = 0.40, N = %d", n_ertc),
  "Patient"
)
save_panel(
  panels$ertc_alt,
  "manuscript/traj_eRTC_alt_d0.4_80pow.pdf",
  "e-RTc alternative example",
  sprintf("true d = 0.40, N = %d", n_ertc),
  "Patient"
)
summary <- do.call(rbind, lapply(panels, `[[`, "summary"))
summary$figure_file <- c(
  "manuscript/traj_null_10pct_80pow.pdf",
  "manuscript/traj_null_10pct_90pow.pdf",
  "manuscript/traj_alt_10pct_80pow.pdf",
  "manuscript/traj_alt_10pct_90pow.pdf",
  "manuscript/traj_eRTe_null.pdf",
  "manuscript/traj_eRTe_alt.pdf",
  "manuscript/traj_eRTC_null_d0.4_80pow.pdf",
  "manuscript/traj_eRTC_alt_d0.4_80pow.pdf"
)
rownames(summary) <- NULL

write.csv(summary, "results/manuscript_trajectory_examples.csv", row.names = FALSE)

format_pct <- function(x) sprintf("%.1f%%", 100 * x)
note_table <- summary
note_table$target_crossing_rate <- format_pct(note_table$target_crossing_rate)
note_table$crossing_rate <- format_pct(note_table$crossing_rate)
note_table$median_crossing_frac <- ifelse(
  is.na(note_table$median_crossing_frac),
  "",
  format_pct(note_table$median_crossing_frac)
)
note_table$median_final_evalue <- sprintf("%.2f", note_table$median_final_evalue)
note_table$q995_evalue <- sprintf("%.2f", note_table$q995_evalue)
note_table$selection_score <- sprintf("%.4f", note_table$selection_score)

markdown_table <- function(df) {
  header <- paste(names(df), collapse = " | ")
  divider <- paste(rep("---", ncol(df)), collapse = " | ")
  rows <- apply(df, 1, paste, collapse = " | ")
  c(paste0("| ", header, " |"), paste0("| ", divider, " |"), paste0("| ", rows, " |"))
}

note_lines <- c(
  "# Manuscript Trajectory Examples",
  "",
  sprintf("- Base seed: `%d`.", base_seed),
  sprintf("- Candidate panels per figure: `%d`.", n_candidates),
  sprintf("- Trajectories per panel: `%d`.", n_traces),
  "",
  "Panels are selected deterministically. Null panels prefer no false crossings; alternative panels target crossing rates close to the relevant simulation operating characteristics.",
  "",
  markdown_table(note_table[, c(
    "endpoint", "scenario", "figure_file", "panel_seed", "n_total",
    "target_crossing_rate", "crossing_rate", "n_crossed",
    "median_crossing", "median_crossing_frac", "median_final_evalue",
    "q995_evalue", "selection_score"
  )])
)
writeLines(note_lines, "notes/manuscript_trajectory_examples.md")

cat("Wrote curated manuscript trajectory examples:\n")
for (file in summary$figure_file) cat(sprintf("  %s\n", file))
cat("Wrote results/manuscript_trajectory_examples.csv\n")
cat("Wrote notes/manuscript_trajectory_examples.md\n")

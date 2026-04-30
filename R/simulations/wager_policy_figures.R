# =============================================================================
# V8 Wager Policy Figures and Manuscript Table
# =============================================================================
#
# Builds manuscript-ready trajectory figures and summary tables for the
# adaptive-vs-design-fixed wager comparison.
#
# Run:
#   Rscript R/simulations/wager_policy_figures.R

suppressPackageStartupMessages(source("R/ertb.R"))
suppressPackageStartupMessages(source("R/erte.R"))
suppressPackageStartupMessages(library(scales))

set.seed(20260429)

dir.create("manuscript", showWarnings = FALSE)

alpha <- 0.05
threshold <- 1 / alpha
p_ctrl <- 0.40
true_arr <- 0.05
p_trt_true <- p_ctrl - true_arr
n_ertb <- 2942
n_erte <- n_ertb
n_events_erte <- expected_events(n_erte, p_ctrl, p_trt_true)
n_traces <- 30

policy_labels <- c(
  adaptive = "Adaptive",
  matched = "Fixed matched",
  over = "Fixed overestimated"
)

format_pp <- function(x) {
  ifelse(is.na(x), "--", sprintf("%.1fpp", 100 * x))
}

format_pct <- function(x) {
  sprintf("%.1f\\%%", 100 * x)
}

format_number <- function(x) {
  ifelse(is.na(x), "--", formatC(as.integer(round(x)), format = "d", big.mark = "{,}"))
}

policy_short <- function(policy, misspecification) {
  if (grepl("^adaptive", policy)) {
    "Adaptive"
  } else if (grepl("^oracle", policy)) {
    "Oracle"
  } else if (misspecification %in% c("underestimated", "matched", "overestimated")) {
    switch(
      misspecification,
      underestimated = "Fixed under",
      matched = "Fixed matched",
      overestimated = "Fixed over"
    )
  } else if (grepl("5pp", policy)) {
    "Fixed 5pp"
  } else if (grepl("10pp", policy)) {
    "Fixed 10pp"
  } else {
    policy
  }
}

make_ertb_trace_df <- function(policy_key, panel_label) {
  do.call(
    rbind,
    lapply(seq_len(n_traces), function(j) {
      trial <- simulate_trial(n_ertb, rate_trt = p_trt_true, rate_ctrl = p_ctrl)

      wealth <- switch(
        policy_key,
        adaptive = compute_eRT(
          trial$treatment, trial$outcome,
          burn_in = 50, ramp = 100, wager = "adaptive"
        ),
        matched = compute_eRT(
          trial$treatment, trial$outcome,
          burn_in = 50, ramp = 100, wager = "design",
          p_ctrl_design = p_ctrl, p_trt_design = p_ctrl - 0.05
        ),
        over = compute_eRT(
          trial$treatment, trial$outcome,
          burn_in = 50, ramp = 100, wager = "design",
          p_ctrl_design = p_ctrl, p_trt_design = p_ctrl - 0.10
        ),
        stop("Unknown e-RTb policy")
      )

      data.frame(
        index = seq_along(wealth),
        wealth = wealth,
        trial = j,
        policy = panel_label
      )
    })
  )
}

make_erte_trace_df <- function(policy_key, panel_label) {
  do.call(
    rbind,
    lapply(seq_len(n_traces), function(j) {
      trial <- simulate_trial(n_erte, rate_trt = p_trt_true, rate_ctrl = p_ctrl)
      event_idx <- which(trial$outcome == 1)
      events <- trial$treatment[event_idx]

      res <- switch(
        policy_key,
        adaptive = compute_eRTe(
          events,
          burn_in = 30, ramp = 50, threshold = threshold,
          wager = "adaptive"
        ),
        matched = compute_eRTe(
          events,
          burn_in = 30, ramp = 50, threshold = threshold,
          wager = "design",
          p_ctrl_design = p_ctrl, p_trt_design = p_ctrl - 0.05
        ),
        over = compute_eRTe(
          events,
          burn_in = 30, ramp = 50, threshold = threshold,
          wager = "design",
          p_ctrl_design = p_ctrl, p_trt_design = p_ctrl - 0.10
        ),
        stop("Unknown e-RTe policy")
      )

      data.frame(
        index = seq_along(res$wealth),
        wealth = res$wealth,
        trial = j,
        policy = panel_label
      )
    })
  )
}

plot_trace <- function(df, x_lab, title, subtitle) {
  ggplot(df, aes(x = index, y = wealth, group = interaction(policy, trial))) +
    geom_line(alpha = 0.42, linewidth = 0.25, color = "steelblue") +
    geom_hline(yintercept = threshold, linetype = "dashed", color = "red3") +
    geom_hline(yintercept = 1, linetype = "dotted", color = "gray45") +
    facet_wrap(~ policy, nrow = 1) +
    scale_y_log10(labels = label_number()) +
    labs(
      title = title,
      subtitle = subtitle,
      x = x_lab,
      y = "e-value (log scale)"
    ) +
    theme_minimal(base_size = 11) +
    theme(
      plot.title = element_text(face = "bold"),
      panel.grid.minor = element_blank(),
      strip.text = element_text(face = "bold")
    )
}

ertb_traces <- do.call(
  rbind,
  Map(make_ertb_trace_df, names(policy_labels), unname(policy_labels))
)

erte_traces <- do.call(
  rbind,
  Map(make_erte_trace_df, names(policy_labels), unname(policy_labels))
)

ggsave(
  "manuscript/traj_wager_ertb_5pp.pdf",
  plot_trace(
    ertb_traces,
    x_lab = "Patient",
    title = "e-RTb wager-policy trajectories",
    subtitle = "Control event rate 40%, treatment event rate 35%, 30 simulated trials per panel"
  ),
  width = 10,
  height = 4.2
)

ggsave(
  "manuscript/traj_wager_erte_5pp.pdf",
  plot_trace(
    erte_traces,
    x_lab = "Event",
    title = "e-RTe wager-policy trajectories",
    subtitle = sprintf(
      "Control event rate 40%%, treatment event rate 35%%, %d expected events, 30 simulated trials per panel",
      n_events_erte
    )
  ),
  width = 10,
  height = 4.2
)

results_file <- "results/wager_policy_5000_same_n.csv"
if (!file.exists(results_file)) {
  stop(sprintf("Missing %s. Run wager_policy_comparison.R first.", results_file))
}

results <- read.csv(results_file, stringsAsFactors = FALSE)
n_sims_values <- unique(results$n_sims)
if (length(n_sims_values) != 1) stop("Expected one n_sims value in wager-policy results")
n_sims_label <- formatC(n_sims_values[[1]], format = "d", big.mark = ",")
n_sims_latex <- formatC(n_sims_values[[1]], format = "d", big.mark = "{,}")
results$policy_display <- mapply(policy_short, results$policy, results$wager_misspecification)
results$wager_display <- format_pp(results$wager_arr)
results$n_display <- format_number(results$n_patients)
results$events_display <- format_number(results$n_events)
results$rate_display <- format_pct(results$rejection_rate)
results$crossing_display <- format_number(results$median_crossing)
results$sample_arr_display <- format_pp(results$sample_size_arr)
results$true_arr_display <- format_pp(results$true_arr)

real_power <- subset(
  results,
  scenario_type == "alternative" & !grepl("^oracle", policy)
)

type1 <- subset(results, scenario_type == "null")
type1$policy_plot <- factor(
  type1$policy_display,
  levels = c("Adaptive", "Fixed 5pp", "Fixed 10pp")
)
type1$design_plot <- paste0("Design ARR ", format_pp(type1$sample_size_arr))
type1$lower <- pmax(0, type1$rejection_rate - 1.96 * type1$se)
type1$upper <- pmin(1, type1$rejection_rate + 1.96 * type1$se)

type1_plot <- ggplot(
  type1,
  aes(x = policy_plot, y = rejection_rate, ymin = lower, ymax = upper)
) +
  geom_hline(yintercept = alpha, linetype = "dashed", color = "red3") +
  geom_pointrange(color = "steelblue", linewidth = 0.35) +
  facet_grid(endpoint ~ design_plot) +
  scale_y_continuous(labels = percent_format(accuracy = 1), limits = c(0, 0.07)) +
  labs(
    title = "Type I error by wager policy",
    subtitle = sprintf("%s simulated null trials per scenario; bars show approximate 95%% Monte Carlo intervals", n_sims_label),
    x = NULL,
    y = "Type I error"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold"),
    axis.text.x = element_text(angle = 30, hjust = 1),
    panel.grid.minor = element_blank(),
    strip.text = element_text(face = "bold")
  )

ggsave("manuscript/wager_policy_type1.pdf", type1_plot, width = 8.5, height = 5.2)

real_power$policy_plot <- factor(
  real_power$policy_display,
  levels = c("Adaptive", "Fixed under", "Fixed matched", "Fixed over")
)
real_power$scenario_plot <- paste0("True ARR ", format_pp(real_power$true_arr))

power_plot <- ggplot(
  real_power,
  aes(x = policy_plot, y = rejection_rate, fill = endpoint)
) +
  geom_col(position = position_dodge(width = 0.72), width = 0.62) +
  facet_wrap(~ scenario_plot, nrow = 1) +
  scale_y_continuous(labels = percent_format(accuracy = 1), limits = c(0, 1)) +
  scale_x_discrete(labels = c(
    "Adaptive" = "Adaptive",
    "Fixed under" = "Fixed\nunder",
    "Fixed matched" = "Fixed\nmatched",
    "Fixed over" = "Fixed\nover"
  )) +
  scale_fill_manual(values = c("e-RTb" = "#3A6EA5", "e-RTe" = "#5B8E7D")) +
  labs(
    title = "Power by wager policy",
    subtitle = sprintf("%s simulated trials per scenario; fixed wagers use full-Kelly design calibration", n_sims_label),
    x = NULL,
    y = "Power",
    fill = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold"),
    axis.text.x = element_text(lineheight = 0.9),
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    strip.text = element_text(face = "bold")
  )

ggsave("manuscript/wager_policy_power.pdf", power_plot, width = 8.5, height = 4.8)

type1$scenario_display <- paste("Null", type1$sample_arr_display, "design")
type1$median_display <- "--"
type1$metric_display <- type1$rate_display
type1$policy_order <- match(type1$policy_display, c("Adaptive", "Fixed 5pp", "Fixed 10pp"))
type1_table <- type1[order(type1$endpoint, type1$sample_size_arr, type1$policy_order), ]

power_table <- subset(results, scenario_type == "alternative")
power_table$scenario_display <- paste("True", power_table$true_arr_display)
power_table$median_display <- power_table$crossing_display
power_table$metric_display <- power_table$rate_display
power_table$policy_order <- match(
  power_table$policy_display,
  c("Adaptive", "Fixed under", "Fixed matched", "Fixed over", "Oracle")
)
power_table <- power_table[order(power_table$endpoint, power_table$true_arr, power_table$policy_order), ]

row_summary <- function(x) {
  sprintf(
    "%s & %s & %s & %s & %s & %s & %s & %s \\\\",
    x$endpoint,
    x$scenario_display,
    x$policy_display,
    x$wager_display,
    x$n_display,
    x$events_display,
    x$metric_display,
    x$median_display
  )
}

type1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  sprintf("\\caption{Type I error for adaptive and design-fixed wager policies at the same enrolled-patient sample sizes. Each row summarizes %s simulated null trials with $p_C = 0.40$ and $\\alpha = 0.05$. Sample sizes were obtained from the usual fixed-sample two-proportion calculation with 80\\%% power; no event-only inflation was used for e-RTe in this comparison.}", n_sims_latex),
  "\\label{tab:wager_policy_type1}",
  "\\begin{tabular}{@{}lllrrrr@{}}",
  "\\toprule",
  "Endpoint & Scenario & Policy & Wager ARR & $N$ & Events & Type I \\\\",
  "\\midrule",
  vapply(seq_len(nrow(type1_table)), function(i) {
    x <- type1_table[i, ]
    sprintf(
      "%s & %s & %s & %s & %s & %s & %s \\\\",
      x$endpoint,
      x$scenario_display,
      x$policy_display,
      x$wager_display,
      x$n_display,
      x$events_display,
      x$metric_display
    )
  }, character(1)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{table}"
)

power_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  sprintf("\\caption{Power for adaptive and design-fixed wager policies at the same enrolled-patient sample sizes. Each row summarizes %s simulated trials with $p_C = 0.40$ and $\\alpha = 0.05$. Fixed policies use full-Kelly wagers calibrated to the listed wager ARR; adaptive e-RTb uses half-Kelly and adaptive e-RTe uses full-Kelly.}", n_sims_latex),
  "\\label{tab:wager_policy_v8}",
  "\\begin{tabular}{@{}lllrrrrr@{}}",
  "\\toprule",
  "Endpoint & Scenario & Policy & Wager ARR & $N$ & Events & Power & Median crossing \\\\",
  "\\midrule",
  vapply(seq_len(nrow(power_table)), function(i) row_summary(power_table[i, ]), character(1)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(c(type1_lines, "", power_lines), "manuscript/wager_policy_results_table.tex")

type_m_table <- subset(
  results,
  scenario_type == "alternative" &
    wager_misspecification %in% c("adaptive", "matched") &
    endpoint %in% c("e-RTb", "e-RTe")
)
type_m_table$policy_display <- ifelse(
  type_m_table$wager_misspecification == "adaptive",
  "Adaptive",
  "Fixed matched"
)
type_m_table$true_display <- format_pp(type_m_table$true_arr)
type_m_table$policy_order <- match(type_m_table$policy_display, c("Adaptive", "Fixed matched"))
type_m_table <- type_m_table[
  order(type_m_table$true_arr, type_m_table$endpoint, type_m_table$policy_order),
]

type_m_rows <- vapply(seq_len(nrow(type_m_table)), function(i) {
  x <- type_m_table[i, ]
  sprintf(
    "%s & %s & %s & %.2f & %.2f & %.2f & %.2f & %.2f \\\\",
    x$true_display,
    x$endpoint,
    x$policy_display,
    100 * x$median_crossing_effect,
    100 * x$median_final_effect,
    x$median_type_m_at_crossing,
    x$type_m_q75,
    x$type_m_q90
  )
}, character(1))

type_m_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\small",
  "\\caption{Type M error at first e-process crossing for e-RTb and e-RTe. Crossing and final effects are absolute risk reductions in percentage points. For e-RTe, the e-process itself remains event-only; the absolute risk reduction is a full-data diagnostic computed from all randomized patients observed by the crossing time. Type M is computed among trials that crossed.}",
  "\\begin{tabular}{@{}lllrrrrr@{}}",
  "\\toprule",
  "True & Endpoint & Policy & Crossing & Final & Median M & Q75 & Q90 \\\\",
  "\\midrule",
  type_m_rows,
  "\\bottomrule",
  "\\end{tabular}",
  "\\label{tab:type_m_crossing}",
  "\\end{table}"
)

writeLines(type_m_lines, "manuscript/wager_policy_type_m_table.tex")

cat("Wrote:\n")
cat("  manuscript/traj_wager_ertb_5pp.pdf\n")
cat("  manuscript/traj_wager_erte_5pp.pdf\n")
cat("  manuscript/wager_policy_type1.pdf\n")
cat("  manuscript/wager_policy_power.pdf\n")
cat("  manuscript/wager_policy_results_table.tex\n")
cat("  manuscript/wager_policy_type_m_table.tex\n")

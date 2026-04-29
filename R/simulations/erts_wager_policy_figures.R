# =============================================================================
# V8 e-RTs Wager Policy Figures
# =============================================================================
#
# Builds manuscript-ready figures from the fixed-seed e-RTs simulation output.
#
# Run:
#   Rscript R/simulations/erts_wager_policy_figures.R
#
# Inputs:
#   results/erts_wager_policy_1000.csv
#
# Outputs:
#   manuscript/erts_wager_policy_power.pdf
#   manuscript/erts_wager_policy_type_m.pdf

suppressPackageStartupMessages({
  library(ggplot2)
  library(scales)
})

results_file <- "results/erts_wager_policy_1000.csv"
if (!file.exists(results_file)) {
  stop(sprintf("Missing %s. Run R/simulations/erts_wager_policy.R 1000 first.", results_file))
}

dir.create("manuscript", showWarnings = FALSE)

alpha <- 0.05
target_power <- 0.80

results <- read.csv(results_file, stringsAsFactors = FALSE)

power <- subset(results, scenario_type == "alternative")
power$policy_plot <- factor(
  power$policy_display,
  levels = c(
    "Fixed 0.25",
    "Adaptive half",
    "Design under",
    "Design matched",
    "Design over"
  )
)
power$hr_plot <- factor(
  sprintf("True HR %.2f", power$true_hr),
  levels = sprintf("True HR %.2f", sort(unique(power$true_hr), decreasing = TRUE))
)
power$lower <- pmax(0, power$rejection_rate - 1.96 * power$se)
power$upper <- pmin(1, power$rejection_rate + 1.96 * power$se)

policy_colors <- c(
  "Fixed 0.25" = "#3B6EA8",
  "Adaptive half" = "#6C757D",
  "Design under" = "#D6A157",
  "Design matched" = "#2E8B57",
  "Design over" = "#B85C5C"
)

power_plot <- ggplot(
  power,
  aes(x = policy_plot, y = rejection_rate, ymin = lower, ymax = upper, color = policy_plot)
) +
  geom_hline(yintercept = target_power, linetype = "dashed", color = "gray35") +
  geom_pointrange(linewidth = 0.38) +
  facet_wrap(~ hr_plot, nrow = 1) +
  scale_color_manual(values = policy_colors, guide = "none") +
  scale_y_continuous(labels = percent_format(accuracy = 1), limits = c(0, 0.85)) +
  labs(
    title = "e-RTs power by wager policy",
    subtitle = "1,000 simulations per scenario; dashed line marks 80% fixed-sample log-rank design power",
    x = NULL,
    y = "Crossing probability"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold"),
    axis.text.x = element_text(angle = 35, hjust = 1),
    panel.grid.minor = element_blank(),
    strip.text = element_text(face = "bold")
  )

ggsave(
  "manuscript/erts_wager_policy_power.pdf",
  power_plot,
  width = 9.5,
  height = 4.8
)

type_m <- subset(power, !is.na(median_type_m))
type_m$type_m_lower <- pmin(type_m$median_type_m, type_m$type_m_q75)
type_m$type_m_upper <- type_m$type_m_q90

type_m_plot <- ggplot(
  type_m,
  aes(
    x = policy_plot,
    y = median_type_m,
    ymin = type_m_lower,
    ymax = type_m_upper,
    color = policy_plot
  )
) +
  geom_hline(yintercept = 1, linetype = "dotted", color = "gray35") +
  geom_pointrange(linewidth = 0.38) +
  facet_wrap(~ hr_plot, nrow = 1) +
  scale_color_manual(values = policy_colors, guide = "none") +
  scale_y_continuous(limits = c(0.9, 3.9), breaks = seq(1, 4, by = 0.5)) +
  labs(
    title = "e-RTs Type M error at crossing",
    subtitle = "Points are medians; bars extend from median to 90th percentile among crossing trials",
    x = NULL,
    y = "Exaggeration ratio on |log(HR)| scale"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold"),
    axis.text.x = element_text(angle = 35, hjust = 1),
    panel.grid.minor = element_blank(),
    strip.text = element_text(face = "bold")
  )

ggsave(
  "manuscript/erts_wager_policy_type_m.pdf",
  type_m_plot,
  width = 9.5,
  height = 4.8
)

cat("Wrote manuscript/erts_wager_policy_power.pdf and manuscript/erts_wager_policy_type_m.pdf\n")

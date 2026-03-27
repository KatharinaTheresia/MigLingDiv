library(dplyr)     
library(ggplot2)   
library(purrr)      
library(broom)  
library(readr)

#### this script fits yearly linear models of total (static) entropy on imported entropy, 
# extracts coefficients and model statistics, and visualizes the effect with 95% CIs. ####


# load data 
import_entropy <- read.csv("../data/final/imported_entropy.csv") %>%
  rename_with(~ tolower(trimws(.)))

# remove rows with missing values
model_df <- na.omit(import_entropy)

# Years to analyze 
# (2024 is excluded as predates the outcome variable)
years <- c(1990, 1995, 2000, 2005, 2010, 2015, 2020)

# Fit one linear model per year for total entropy ~ imported entropy 
models <- map(years, ~ {
  formula <- as.formula(paste("shannon_entropy ~ imp_entropy_", .x, sep = ""))
  lm(formula, data = model_df)
})
names(models) <- paste0("m_", years)

# extract coefficients (slopes only) into a tidy table
coef_tbl <- map2_dfr(models, years, ~ {
  tidy(.x) %>%
    filter(term != "(Intercept)") %>%
    mutate(year = .y)
})

# extract model-level statistics (R², adjusted R², RMSE, AIC, BIC, F-stat, etc.)
fit_tbl <- map2_dfr(models, years, ~ {
  glance(.x) %>%
    transmute(
      year = .y,
      r2 = r.squared,
      adj_r2 = adj.r.squared,
      rmse = sigma,
      aic = AIC,
      bic = BIC,
      f_stat = statistic,
      df1 = df,
      df2 = df.residual,
      f_p = p.value
    )
})

# merge coefficients with model stats
coef_with_fit <- left_join(coef_tbl, fit_tbl, by = "year")


## visualization 

# prepare coefficient plot with 95% confidence intervals
coef_plot <- coef_tbl %>%
  mutate(
    year = as.integer(year),
    y_lab = factor(year, levels = sort(unique(year))),  # for plotting
    lo = estimate - 1.96 * std.error,                  # lower CI
    hi = estimate + 1.96 * std.error                   # upper CI
  )

# mean beta across all years (for reference line)
mean_beta <- mean(coef_plot$estimate, na.rm = TRUE)

# create ggplot
p <- ggplot(coef_plot, aes(x = estimate, y = y_lab)) +
  # mean line
  geom_vline(xintercept = mean_beta, linetype = "dashed", color = "grey40", linewidth = 0.5) +
  # confidence intervals
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0.18, linewidth = 0.6, color = "#2C7BB6") +
  # points
  geom_point(size = 3, shape = 21, fill = "purple", color = "purple") +
  # connect dots chronologically
  geom_path(linewidth = 0.4, color = "purple", alpha = 0.6, aes(group = 1)) +
  # ---- fixed annotations (moved to avoid overlap)
  annotate("text", x = mean_beta, y = length(levels(coef_plot$y_lab)) + 0.3,
           label = "Mean effect across years", size = 4, hjust = 0, color = "grey30") +
  annotate("text", x = max(coef_plot$hi) + 0.02, y = 1,
           label = "", size = 3, hjust = 1, color = "grey30") +
  # ---- natural axis: start at zero 
  coord_cartesian(xlim = c(0.6, 1.1)) +
  scale_y_discrete(limits = rev(levels(coef_plot$y_lab))) +
  labs(
    title = "effect of imported linguistic entropy on total entropy",
    x = "β estimate (with 95% CI)", y = "Year"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.major.y = element_line(color = "grey85"),  # ← keep grid lines
    panel.grid.major.x = element_line(color = "grey90"),
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 15)
  )

# save plot to scripts folder (or adjust path as needed)
ggsave(
  filename = "effectplot.png",
  plot = p,
  width = 7, height = 4.1, units = "in",
  dpi = 600
)



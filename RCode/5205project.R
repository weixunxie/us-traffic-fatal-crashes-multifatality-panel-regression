library(readxl)

accident_2019 <- read_xlsx("accident_2019.csv")
accident_2020 <- read_xlsx("accident_2020.csv")
accident_2021 <- read_xlsx("accident_2021.csv")

accident_2019[] <- lapply(accident_2019, as.character)
accident_2020[] <- lapply(accident_2020, as.character)
accident_2021[] <- lapply(accident_2021, as.character)

accident_2019$YEAR <- 2019
accident_2020$YEAR <- 2020
accident_2021$YEAR <- 2021

accident_all <- bind_rows(accident_2019, accident_2020, accident_2021)

# Data already loaded as accident_all
dat <- accident_all %>%
  mutate(
    multi_fatal = if_else(as.integer(FATALS) >= 2, 1L, 0L),
    night = if_else(as.integer(HOUR) %in% c(20:23, 0:5), 1L, 0L),
    drunk = if_else(DRUNK_DR == 1, 1L, 0L)
  )

# Aggregate to State × Month
panel <- dat %>%
  group_by(STATE, YEAR, MONTH) %>%
  summarise(
    n_crash = n(),
    multi_rate = mean(multi_fatal, na.rm = TRUE),
    night_share = mean(night, na.rm = TRUE),
    drunk_share = mean(drunk, na.rm = TRUE),
    avg_vehicles = mean(as.numeric(VE_TOTAL), na.rm = TRUE),
    avg_persons = mean(as.numeric(PERSONS), na.rm = TRUE),
    .groups = "drop"
  )

# Descriptive statistics
desc <- panel %>%
  summarise(
    across(
      c(multi_rate, night_share, drunk_share, avg_vehicles, avg_persons),
      list(
        mean   = ~mean(.x, na.rm = TRUE),
        sd     = ~sd(.x, na.rm = TRUE),
        p25    = ~quantile(.x, 0.25, na.rm = TRUE),
        median = ~median(.x, na.rm = TRUE),
        p75    = ~quantile(.x, 0.75, na.rm = TRUE)
      ),
      .names = "{.col}_{.fn}"
    )
  )
desc_tidy <- desc %>%
  pivot_longer(
    cols = everything(),
    names_to = "var_stat",
    values_to = "value"
  ) %>%
  separate(var_stat, into = c("variable", "statistic"), sep = "_(?=[^_]+$)") %>%
  pivot_wider(
    names_from = statistic,
    values_from = value
  ) %>%
  mutate(
    variable = case_when(
      variable == "multi_rate" ~ "Multi-fatality rate",
      variable == "night_share" ~ "Night-time share",
      variable == "drunk_share" ~ "Drunk-driving share",
      variable == "avg_vehicles" ~ "Avg vehicles per crash",
      variable == "avg_persons" ~ "Avg persons per crash"
    )
  )

kable(desc_tidy, 
      caption = "State × Month level descriptive statistics",
      digits = 4,
      align = c('l', rep('r', 5)))

### Some graphics related to our project
library(ggplot2)
library(forcats)

# Ensure that MONTH is a numeric value
panel <- panel %>%
  mutate(MONTH = as.integer(MONTH),
         YEAR = as.integer(YEAR))

# 1. Multi-fatality trend over time
panel %>%
  mutate(month_label = paste0(YEAR, "-", sprintf("%02d", MONTH))) %>%
  group_by(month_label) %>%
  summarise(multi_rate = mean(multi_rate, na.rm = TRUE), .groups="drop") %>%
  ggplot(aes(x = month_label, y = multi_rate, group=1)) +
  geom_line(color="steelblue", linewidth=1) +
  geom_point(color="darkred", size=2) +
  labs(title="Multi-fatality rate over time",
       x="Month", y="Multi-fatality rate") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle=45, hjust=1))

# 2. State-level boxplot
ggplot(panel, aes(x = fct_reorder(as.factor(STATE), multi_rate, median), y = multi_rate)) +
  geom_boxplot(fill="lightblue", color="gray40") +
  coord_flip() +
  labs(title="State distribution of multi-fatality rate",
       x="State", y="Multi-fatality rate") +
  theme_minimal()

# 3. Bubble chart (3D visualization)
panel %>%
  mutate(
    time_index = (YEAR - min(YEAR)) * 12 + MONTH,
    STATE_ord = as.integer(fct_reorder(as.factor(STATE), multi_rate))
  ) %>%
  ggplot(aes(x = time_index, y = STATE_ord, size = multi_rate, color = night_share)) +
  geom_point(alpha=0.7) +
  scale_color_gradient(low="yellow", high="red") +
  scale_size(range = c(1,8)) +
  labs(
    title="Bubble chart: Multi-fatality rate (size) & Night share (color)",
    x="Time (by month)", y="State index",
    color="Night share", size="Multi-fatality rate"
  ) +
  theme_minimal()

# 4. Scatter plot: night_share vs drunk_share
ggplot(panel, aes(x = night_share, y = drunk_share, size = multi_rate)) +
  geom_point(alpha = 0.6, color = "darkgreen") +
  scale_size(range=c(1,8)) +
  labs(
    title="Night vs Drunk share vs Multi-fatality rate",
    x="Night share", y="Drunk share", size="Multi-fatality rate"
  ) +
  theme_minimal()


# regression
reg <- lm(
  multi_rate ~ night_share + drunk_share + avg_vehicles + avg_persons
  + factor(STATE) + factor(MONTH),
  data = panel
)
summary(reg)


# Model selection
reg_int <- lm(
  multi_rate ~ night_share * drunk_share +
    avg_vehicles + avg_persons +
    factor(STATE) + factor(MONTH),
  data = panel
)
summary(reg_int)

reg_quad <- lm(
  multi_rate ~ night_share + drunk_share +
    I(avg_persons^2) + avg_vehicles +
    factor(STATE) + factor(MONTH),
  data = panel
)
summary(reg_quad)

AIC(reg, reg_int, reg_quad)


# Diagnostics
par(mfrow = c(2, 2))
plot(reg_int)

influence.measures(reg_int)

cook <- cooks.distance(reg_int)
which(cook > 4 / nrow(panel))

set.seed(123)
n <- nrow(panel)
train_id <- sample(seq_len(n), size = 0.7 * n)
train <- panel[train_id, ]
test  <- panel[-train_id, ]

reg_int <- lm(
  multi_rate ~ night_share * drunk_share +
    avg_vehicles + avg_persons +
    factor(STATE) + factor(MONTH),
  data = train
)
y_hat <- predict(reg_int, newdata = test)
MSPR <- mean((test$multi_rate - y_hat)^2, na.rm = TRUE)
MSPR

MSE <- mean(residuals(reg_int)^2)
MSE

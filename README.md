# us-traffic-fatal-crashes-multifatality-panel-regression

This project analyzes fatal traffic crashes in the United States using the Fatality Analysis Reporting System (FARS) from 2019 to 2021. The analysis aggregates crash-level records to a **state–month** panel dataset and studies how crash composition and risk behaviors relate to the **multi-fatality accident rate** (the proportion of fatal crashes involving **two or more fatalities**).

## Research Goal

Rather than modeling whether a fatal crash occurs, this project focuses on **severity structure**:  
**What factors are associated with a higher share of multi-fatal crashes within a state and month?**

## Data

Source: **Fatality Analysis Reporting System (FARS)** maintained by NHTSA.  
Unit of analysis: **State × Month** (2019–2021).

### Key Variables (State–Month Level)

- **multi_rate**: Proportion of fatal crashes with ≥2 fatalities
- **night_share**: Share of fatal crashes occurring between 20:00–05:59
- **drunk_share**: Share of fatal crashes involving alcohol
- **avg_vehicles**: Average number of vehicles per fatal crash
- **avg_persons**: Average number of persons per fatal crash
- Controls: **state fixed effects** and **month fixed effects**

## Methods

### Exploratory Analysis
- Descriptive statistics at the state–month level
- Visualizations of time trends and cross-state variation in multi-fatality rate
- Joint visualization of night driving, alcohol involvement, and multi-fatality risk

### Regression Model (Panel OLS with Fixed Effects)

Baseline specification:

multi_rate_{s,t} = β0 + β1 night_share_{s,t} + β2 drunk_share_{s,t}
                  + β3 avg_vehicles_{s,t} + β4 avg_persons_{s,t}
                  + α_s + γ_t + ε_{s,t}

Where:
- α_s: state fixed effects (time-invariant heterogeneity)
- γ_t: month fixed effects (seasonality)

Model selection in the appendix considers:
- An **interaction** term between night_share and drunk_share (selected by AIC)
- A quadratic alternative (not retained)

## Main Findings

From the fixed-effects regression results:

- **Night-time share is positively associated with multi-fatality rate**  
  Higher proportions of night-time fatal crashes correspond to higher shares of multi-fatal crashes.

- **Drunk-driving share is positively associated with multi-fatality rate**  
  Alcohol-involved crash prevalence substantially increases the multi-fatal crash share.

- **Average persons per crash is the strongest positive predictor**  
  More people involved per crash increases exposure and raises multi-fatality probability.

- **Average vehicles per crash shows a negative association**  
  Multi-vehicle crashes may occur more often in lower-speed or congested settings, reducing multi-fatal severity conditional on being fatal.

Overall model fit is modest but reasonable for noisy accident outcomes, and the model is jointly significant.

## Validation & Robustness

- Diagnostics: residual patterns, heteroskedasticity check, Q–Q plot
- Influence: Cook’s distance and leverage analysis (no single observation dominates)
- Generalization: MSPR vs. in-sample MSE indicates no severe overfitting

## Limitations

- Aggregation to state–month supports systemic inference but limits individual-level mechanisms
- Correlational results (not causal)
- Omitted covariates: weather, roadway type, speed limits, emergency response, etc.
- Proportional outcomes can be volatile in low-accident months/states
- Linear models may miss nonlinear thresholds

## Authors

Qiangwei Weng, Qianyu Zhang, Luxin Liu, Weixun Xie  
(Columbia University STAT 5205 project)

## Citation

If you use or reference this work, please cite the project report:
“State–Month Analysis of Fatal Crash Characteristics in the US (2019–2021)”.

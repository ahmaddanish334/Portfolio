# COVID-19 Forecasting in Germany

Three-part forecasting case study using German COVID-19 data from the Robert Koch Institute.

The project moves from classical time-series models to machine learning and then to a common forecast-comparison framework.

## Project structure

```text
01_Linear_Models/
  covid_linear_forecasting.ipynb
  report.pdf

02_Machine_Learning/
  covid_ml_forecasting.ipynb
  report.pdf

03_Model_Comparison/
  covid_forecast_comparison.ipynb
  report.pdf

requirements.txt
```

## 1. Linear time-series models

The first stage forecasts daily COVID-19 cases and deaths using autoregressive and seasonal models.

Main work:
- log transformation of cases and deaths
- ACF and PACF analysis
- AR(1) and AR(7) benchmarks
- BIC-based lag selection
- ARX models with additional predictors
- stationarity and residual checks
- seasonal autoregressive models
- rolling out-of-sample forecasting
- RMSFE, Theil's U and Diebold-Mariano comparisons

The results show a strong weekly reporting pattern. Longer lag structures improve forecast accuracy substantially. In the rolling evaluation, SARIMA(50) gives the lowest RMSFE for cases, while AR(36) gives the lowest RMSFE for deaths.

## 2. Machine-learning forecasts

The second stage focuses on one-step-ahead forecasting of daily cases with nonlinear models.

The notebook compares:
- regression trees
- multi-layer perceptron neural networks

The models are estimated with:
- lagged case values
- lagged age-group case counts
- temperature
- a Monday indicator

The data are split chronologically, hyperparameters are tuned on a validation period, and the models are re-estimated with an expanding window during the test period.

The MLP performs better than the regression tree in the reported test results. Adding covariates improves the MLP slightly, while the tree becomes slightly worse.

## 3. Forecast comparison

The final stage brings the earlier forecasting ideas into one common evaluation framework.

It includes:
- AR and ARX forecasts
- fixed-origin and rolling-window estimation
- decision-tree and random-forest forecasts
- a common 80/20 train-test split
- RMSFE comparison on the original case-count scale
- Diebold-Mariano tests
- Bonferroni-adjusted pairwise comparisons
- feature-importance analysis
- error diagnostics over time

The final comparison evaluates 15 forecast series over the same test period. The strongest reported model is a rolling random forest using lagged case values only.

## Data

The main source is the public SARS-CoV-2 surveillance dataset from the Robert Koch Institute.

Additional temperature data are retrieved from the Open-Meteo historical weather archive.

The raw source data are not included in this repository because the notebooks retrieve or construct the required data during the workflow.

## Requirements

Install the main Python dependencies with:

```bash
pip install -r requirements.txt
```

## Notes

This work was completed as a three-part academic group case study at TU Dortmund University.

The original submitted reports are included unchanged in each project folder and identify the contributors to the group work.

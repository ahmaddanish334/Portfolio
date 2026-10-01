# Clearing the Air

Analysis of PM2.5 pollution across five Chinese cities using causal adjustment, machine learning, and weather-regime clustering.

This project was completed for the Data & AI in Economics course at TU Dortmund University.

## Research question

How is the northern winter-heating regime associated with hourly PM2.5 concentrations in Beijing and Shenyang relative to Shanghai, Guangzhou, and Chengdu after adjusting for meteorological conditions, and how well can non-linear machine-learning models predict pollution dynamics?

## Data

The analysis covers five cities from 2010 to 2015:

- Beijing
- Shenyang
- Shanghai
- Guangzhou
- Chengdu

The final analytical panel contains 175,993 hourly city observations.

Data sources:

- UCI PM2.5 Data of Five Chinese Cities
- Open-Meteo historical weather data
- EDGAR city-year emissions data used as a background sensitivity check

The raw data used by the notebook is included in `data/`.

## Methods

The project has three main analytical blocks.

### 1. Heating-regime analysis

A backdoor-adjusted regression is used to estimate the association between the northern winter-heating period and PM2.5 while controlling for weather and city, year, month, and hour fixed effects.

Robustness checks include:

- placebo treatments
- random common-cause perturbation
- repeated data-subset estimation
- EDGAR emissions sensitivity analysis

The adjusted heating-regime coefficient is **+21.33 µg/m³ PM2.5**, with a 95% confidence interval of **[9.59, 33.07]**.

This estimate depends on the stated adjustment assumptions and should not be interpreted as a natural-experiment estimate.

### 2. Supervised learning

Several forecasting approaches are compared using a chronological setup with 2014 for validation and 2015 as the untouched holdout period.

Models include:

- Random Forest
- HistGradientBoosting
- OLS
- Ridge
- lag-1 and lag-24 persistence benchmarks

The strongest holdout result is the Random Forest delta model:

| Metric | Result |
|---|---:|
| RMSE | 11.65 |
| MAE | 6.14 |
| R² | 0.966 |

Its RMSE is about 10.6% lower than the lag-1 persistence benchmark.

### 3. Weather regimes

K-Means clustering is applied to standardized, PCA-reduced weather variables.

Four weather regimes are retained for interpretation.

The cold, low-boundary-layer regime has the highest average PM2.5 burden at about **101.1 µg/m³**, while the warm, humid/rainy regime has the lowest at about **46.4 µg/m³**.

## Project structure

```text
notebook/
  clearing_the_air_analysis.ipynb

presentation/
  clearing_the_air_presentation.pdf

data/
  pm25/
  weather/
  emissions/

requirements.txt
README.md
```

## Run

Install the dependencies:

```bash
pip install -r requirements.txt
```

Then open:

```text
notebook/clearing_the_air_analysis.ipynb
```

The notebook searches the current project directory and `/mnt/data` for the required source files. If you run it locally, keep the CSV files available in the project data folders or update the input paths in the data-loading section.

## Contributors

Oliver Ossadnik  
Danish Ahmad

Academic group project, TU Dortmund University.

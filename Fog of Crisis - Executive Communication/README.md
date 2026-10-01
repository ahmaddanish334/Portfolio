# The Fog of Crisis

Panel-data analysis of executive communication complexity around the COVID-19 pandemic.

The project studies whether executive language became more complex after the onset of COVID-19 and whether the change was stronger in industries that were more exposed to the crisis.

## Research question

Did the onset of COVID-19 increase executive communication complexity, measured with the Gunning Fog Index, and was the increase larger in high-exposure industries?

## Data

The source dataset contains:

- 24,255 observations
- 1,106 companies
- 2,259 executives
- publication dates from 2007 to 2025

The analysis uses executive transcript text together with company, executive, sentiment, linguistic, video, and financial variables.

The original parquet file is approximately 448 MB and is not stored in this repository. See `data/README.md` for reproduction instructions.

## Methods

The analysis includes:

- descriptive pre/post COVID comparisons
- firm fixed-effects panel regressions
- clustered standard errors
- Difference-in-Differences interaction models
- firm and time fixed effects
- balanced-panel robustness checks
- controls for sentiment, language, executive characteristics, video characteristics, stock returns, volatility, and profitability

## Main findings

### Overall COVID effect

The firm fixed-effects model estimates an increase of about **0.46 Fog Index points** after the COVID onset, with a highly statistically significant coefficient.

This suggests that executive communication became more complex during the pandemic period after controlling for the included firm and communication characteristics.

### Industry exposure

The interaction between COVID and high industry exposure is very small and statistically insignificant.

The analysis therefore does not find evidence that high-exposure industries experienced a meaningfully larger increase in communication complexity than lower-exposure industries.

### Robustness

A specification with both firm and time fixed effects gives a COVID × exposure coefficient of approximately **0.020** with a p-value of **0.860**.

The balanced-panel specification also produces an interaction estimate close to the full-sample result.

## Project structure

```text
notebooks/
  fog_of_crisis_analysis.ipynb
  dataset_description.ipynb

presentation/
  fog_of_crisis_presentation.pdf

data/
  README.md

requirements.txt
README.md
```

## Run

Install the dependencies:

```bash
pip install -r requirements.txt
```

Place `youtube_data_anonymized.parquet` in the project root, then open:

```text
notebooks/fog_of_crisis_analysis.ipynb
```

If you keep the dataset somewhere else, update the parquet path in the loading cell.

## Contributors

Danish Ahmad  
Sadia Kiran  
Ajeyaa Sinha Roy

Academic group project, TU Dortmund University.

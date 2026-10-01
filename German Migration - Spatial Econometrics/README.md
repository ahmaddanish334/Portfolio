# Median Income and Net Migration Across German Districts

Spatial econometric analysis of net migration across German districts.

The project asks whether median income is associated with net migration after accounting for regional economic conditions and spatial dependence between neighbouring districts.

## Data

The analysis uses INKAR/BBSR district-level indicators for **400 German districts** matched to NUTS-3 regions.

Years in the source data: **2014–2019**.  
Outcome years after constructing one-year lags: **2015–2019**.

Main variables include:

- net migration
- median income
- GDP per worker
- unemployment
- education
- foreign population share
- business tax
- population density
- rurality
- federal-state indicators

Spatial boundaries are obtained from Eurostat/GISCO.

## Methods

The workflow includes:

- panel reshaping and lag construction
- missing-value checks and limited education imputation
- multicollinearity diagnostics
- Moran's I for spatial autocorrelation
- queen-contiguity spatial weights
- OLS benchmark
- Spatial Autoregressive Model (SAR)
- Spatial Error Model (SEM)
- Spatial Durbin Model (SDM)
- adjusted Rao score diagnostics
- AIC model comparison
- direct, indirect and total SAR impacts
- residual Moran's I checks

## Model selection

The main model comparison is:

| Model | AIC |
|---|---:|
| SAR | 818.4 |
| OLS | 822.5 |
| SEM | 824.5 |
| SDM | 825.2 |

The adjusted spatial-lag diagnostic supports the SAR specification, while the spatial-error diagnostic does not support SEM.

## Main results

In the preferred SAR model:

- spatial lag coefficient: **0.058**, p = **0.012**
- lagged migration: **0.903**, p < **0.001**
- lagged median income: **-1.021**, p = **0.124**

The strongest result is persistence in migration, together with statistically significant spatial dependence.

After controlling for the regional covariates and spatial structure, lagged median income is not statistically significant. The analysis therefore does not find robust evidence that higher median income independently explains net migration across German districts.

The results are interpreted as associations rather than causal effects.

## Project structure

```text
src/
  spatial_migration_analysis.R
  spatial_migration_analysis.Rnw

presentation/
  spatial_migration_analysis.pdf

data/
  inkar.xlsx

requirements.txt
README.md
```

## Reproducing the analysis

The original project was written as a Sweave `.Rnw` file. A standalone `.R` version of the code is also included for easier inspection.

Install the required R packages listed in `requirements.txt`.

The analysis uses:

```text
data/inkar.xlsx
```

If running the original `.Rnw` file directly, either copy the Excel file beside the `.Rnw` file or update the `read_excel()` path to `data/inkar.xlsx`.

The GIS boundary data are obtained through `giscoR`, so internet access is required when those boundaries are downloaded.

## Author

Danish Ahmad

Seminar project in Quantitative Regional Economics.

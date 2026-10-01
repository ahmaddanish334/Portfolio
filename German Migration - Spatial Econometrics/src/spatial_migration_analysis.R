# Spatial Econometric Analysis of Net Migration Across German Districts
# Extracted from the original Sweave (.Rnw) project file.
# The presentation source remains in src/spatial_migration_analysis.Rnw.

bib_entries <- c(
  paste0("@", "misc{bbsr_inkar,"),
  "  author = {{BBSR}},",
  "  title = {{INKAR -- Indicators and Maps for Spatial and Urban Development}},",
  "  year = {2026},",
  "  note = {Data source}",
  "}",
  "",
  paste0("@", "misc{eurostat_gisco,"),
  "  author = {{Eurostat / GISCO}},",
  "  title = {{NUTS-3 Geospatial Boundary Data for Germany}},",
  "  year = {2021},",
  "  note = {Geospatial boundary data}",
  "}",
  "",
  paste0("@", "article{sjaastad1962,"),
  "  author = {Sjaastad, Larry A.},",
  "  title = {The Costs and Returns of Human Migration},",
  "  journal = {Journal of Political Economy},",
  "  year = {1962},",
  "  volume = {70},",
  "  number = {5, Part 2},",
  "  pages = {80--93}",
  "}",
  "",
  paste0("@", "article{harris_todaro1970,"),
  "  author = {Harris, John R. and Todaro, Michael P.},",
  "  title = {Migration, Unemployment and Development: A Two-Sector Analysis},",
  "  journal = {American Economic Review},",
  "  year = {1970},",
  "  volume = {60},",
  "  number = {1},",
  "  pages = {126--142}",
  "}",
  "",
  paste0("@", "book{anselin1988,"),
  "  author = {Anselin, Luc},",
  "  title = {Spatial Econometrics: Methods and Models},",
  "  publisher = {Kluwer Academic Publishers},",
  "  year = {1988}",
  "}",
  "",
  paste0("@", "book{cliff_ord1981,"),
  "  author = {Cliff, Andrew D. and Ord, J. Keith},",
  "  title = {Spatial Processes: Models and Applications},",
  "  publisher = {Pion},",
  "  year = {1981}",
  "}",
  "",
  paste0("@", "book{lesage_pace2009,"),
  "  author = {LeSage, James and Pace, R. Kelley},",
  "  title = {Introduction to Spatial Econometrics},",
  "  publisher = {CRC Press},",
  "  year = {2009}",
  "}",
  "",
  paste0("@", "book{bivand2013,"),
  "  author = {Bivand, Roger S. and Pebesma, Edzer and Gomez-Rubio, Virgilio},",
  "  title = {Applied Spatial Data Analysis with R},",
  "  publisher = {Springer},",
  "  year = {2013}",
  "}"
)

writeLines(bib_entries, "qre_references.bib")

##=============================================================================

##-----------------------------------------------
## PACKAGE INSTALLATION (run once, then comment out)
##-----------------------------------------------
# install.packages(c("readxl", "tidyverse", "ggplot2", "sf",
#                    "giscoR", "spdep", "spatialreg", "corrplot", "car",
#                    "plm", "stringdist", "sandwich", "lmtest", "splm"))

##-----------------------------------------------
## Part 1: Setup and Data Import
##-----------------------------------------------

set.seed(123)

library(readxl)
library(tidyverse)
library(ggplot2)
library(sf)
library(giscoR)
library(stringdist)
library(spdep)
library(spatialreg)
library(corrplot)
library(car)
library(plm)
library(sandwich)
library(lmtest)
library(splm)

# Import the revised INKAR data. The first two rows contain labels/years, so they
# are skipped and clear English variable names are assigned below.
inkar_raw <- read_excel(
  "inkar.xlsx",
  sheet = "Daten",
  skip = 2,
  col_names = FALSE
)

colnames(inkar_raw) <- c(
  "ID", "Name", "Aggregat",
  paste0("Unemployment_",   2014:2019),
  paste0("Foreign_Share_",  2014:2019),
  paste0("Migration_",      2014:2019),
  paste0("Education_",      2014:2019),
  paste0("MedianIncome_",   2014:2019),
  "Rurality_2019",
  paste0("BWS_Secondary_",  2014:2019),
  paste0("BusinessTax_",    2014:2019),
  paste0("GDP_per_worker_", 2014:2019),
  paste0("PopDensity_",     2014:2019)
)

# Basic cleaning: keep valid district rows, standardise IDs and convert numeric variables.
inkar_clean <- inkar_raw %>%
  filter(!is.na(ID)) %>%
  mutate(
    ID = stringr::str_pad(as.character(ID), width = 5, side = "left", pad = "0"),
    Name = stringr::str_squish(as.character(Name)),
    across(-c(ID, Name, Aggregat), as.numeric)
  )

cat("\nRows after import:", nrow(inkar_clean), "\n")
cat("Columns after import:", ncol(inkar_clean), "\n")

if (nrow(inkar_clean) != 400) {
  warning("Expected 400 districts. Check imported rows.")
}

##-----------------------------------------------
## Part 2: Federal-State Variable
##-----------------------------------------------

state_map <- c(
  "01" = "Schleswig-Holstein",
  "02" = "Hamburg",
  "03" = "Lower Saxony",
  "04" = "Bremen",
  "05" = "North Rhine-Westphalia",
  "06" = "Hesse",
  "07" = "Rhineland-Palatinate",
  "08" = "Baden-Wuerttemberg",
  "09" = "Bavaria",
  "10" = "Saarland",
  "11" = "Berlin",
  "12" = "Brandenburg",
  "13" = "Mecklenburg-Western Pomerania",
  "14" = "Saxony",
  "15" = "Saxony-Anhalt",
  "16" = "Thuringia"
)

inkar_clean <- inkar_clean %>%
  mutate(
    State_Code = substr(ID, 1, 2),
    Federal_State = unname(state_map[State_Code])
  )

if (any(is.na(inkar_clean$Federal_State))) {
  print(inkar_clean %>% filter(is.na(Federal_State)) %>% select(ID, Name, State_Code))
  stop("At least one district could not be assigned to a federal state.")
}

cat("\n================= FEDERAL-STATE DISTRIBUTION =================\n")
print(table(inkar_clean$Federal_State))

##-----------------------------------------------
## Part 3: Missing Data Treatment
##-----------------------------------------------

cat("\n================= MISSING DATA CHECK =================\n")
cat("Total missing values:", sum(is.na(inkar_clean)), "\n")

missing_by_column <- colSums(is.na(inkar_clean))
print(missing_by_column[missing_by_column > 0])

# Missing values occur only in Education. To keep the panel balanced, each
# missing Education cell is replaced with that district's mean Education value
# across the other observed years.
education_cols <- grep("^Education_", names(inkar_clean), value = TRUE)
education_row_mean <- rowMeans(
  as.data.frame(inkar_clean[, education_cols]),
  na.rm = TRUE
)

if (any(!is.finite(education_row_mean))) {
  stop("At least one district has no observed Education value in any year.")
}

inkar_final <- inkar_clean
imputation_log <- tibble(
  ID = character(),
  Name = character(),
  Variable = character(),
  Imputed_Value = numeric()
)

for (v in education_cols) {
  missing_rows <- which(is.na(inkar_final[[v]]))

  if (length(missing_rows) > 0) {
    imputation_log <- bind_rows(
      imputation_log,
      tibble(
        ID = inkar_final$ID[missing_rows],
        Name = inkar_final$Name[missing_rows],
        Variable = v,
        Imputed_Value = education_row_mean[missing_rows]
      )
    )

    inkar_final[[v]][missing_rows] <- education_row_mean[missing_rows]
  }
}

cat("\nImputed Education cells:\n")
print(imputation_log, n = Inf)
cat("Any NAs remaining after Education imputation?", anyNA(inkar_final), "\n")

# Retain original non-imputed data for a complete-case check.
inkar_nonimputed <- inkar_clean

##-----------------------------------------------
## Part 4: Convert to Long Panel Format
##-----------------------------------------------

# Rurality is only available for 2019. It is treated as a time-invariant
# district characteristic and copied to all panel years.
inkar_long <- inkar_final %>%
  pivot_longer(
    cols = -c(ID, Name, Aggregat, State_Code, Federal_State, Rurality_2019),
    names_to = c(".value", "Year"),
    names_pattern = "(.+)_(\\d{4})"
  ) %>%
  mutate(
    Year = as.numeric(Year),
    Rurality = Rurality_2019
  ) %>%
  arrange(ID, Year)

cat("\n================= LONG PANEL CHECK =================\n")
cat("Districts:", dplyr::n_distinct(inkar_long$ID), "\n")
cat("Years:", sort(unique(inkar_long$Year)), "\n")
cat("Observations:", nrow(inkar_long), "\n")

if (dplyr::n_distinct(inkar_long$ID) != 400 || nrow(inkar_long) != 2400) {
  stop("Expected 400 districts x 6 years = 2400 observations before lagging.")
}

##-----------------------------------------------
## Part 5: Log Checks and Lagged Model Data
##-----------------------------------------------

positive_log_variables <- c("MedianIncome", "GDP_per_worker", "PopDensity")

nonpositive_counts <- sapply(
  inkar_long[positive_log_variables],
  function(x) sum(!is.na(x) & x <= 0)
)

cat("\n================= LOG INPUT CHECK =================\n")
print(nonpositive_counts)

if (any(nonpositive_counts > 0)) {
  stop("At least one variable selected for log transformation has non-positive values.")
}

# Timing choice: migration, median income and GDP per worker are lagged by one
# year because these variables were central to the revised specification and are
# more likely to raise timing/endogeneity concerns. The remaining controls are
# kept contemporaneous because they are slow-moving district characteristics or
# institutional controls. This is a modelling choice and should be mentioned as
# a limitation in the write-up.
model_data <- inkar_long %>%
  group_by(ID) %>%
  arrange(Year, .by_group = TRUE) %>%
  mutate(
    L1_Migration = dplyr::lag(Migration),
    L1_log_MedianIncome = dplyr::lag(log(MedianIncome)),
    L1_log_GDP_per_worker = dplyr::lag(log(GDP_per_worker)),
    log_PopDensity = log(PopDensity)
  ) %>%
  ungroup() %>%
  filter(Year %in% 2015:2019) %>%
  drop_na(
    Migration,
    L1_Migration,
    L1_log_MedianIncome,
    L1_log_GDP_per_worker,
    Unemployment,
    Education,
    Foreign_Share,
    BusinessTax,
    log_PopDensity,
    Rurality,
    Federal_State
  )

cat("\n================= MAIN MODEL DATA CHECK =================\n")
cat("Districts:", dplyr::n_distinct(model_data$ID), "\n")
cat("Outcome years:", sort(unique(model_data$Year)), "\n")
cat("Observations:", nrow(model_data), "\n")

if (dplyr::n_distinct(model_data$ID) != 400 ||
    nrow(model_data) != 2000 ||
    !isTRUE(all.equal(sort(unique(model_data$Year)), as.numeric(2015:2019)))) {
  stop("Expected lagged model data to contain 400 districts x 5 years = 2000 observations.")
}

##-----------------------------------------------
## Part 6: Validate Lag Construction
##-----------------------------------------------

expected_lags <- inkar_long %>%
  transmute(
    ID,
    Year = Year + 1,
    Expected_L1_Migration = Migration,
    Expected_L1_log_MedianIncome = log(MedianIncome),
    Expected_L1_log_GDP_per_worker = log(GDP_per_worker)
  )

lag_validation <- model_data %>%
  left_join(expected_lags, by = c("ID", "Year")) %>%
  summarise(
    Max_Migration_Lag_Difference = max(abs(L1_Migration - Expected_L1_Migration), na.rm = TRUE),
    Max_MedianIncome_Lag_Difference = max(abs(L1_log_MedianIncome - Expected_L1_log_MedianIncome), na.rm = TRUE),
    Max_GDP_Lag_Difference = max(abs(L1_log_GDP_per_worker - Expected_L1_log_GDP_per_worker), na.rm = TRUE)
  )

cat("\n================= LAG VALIDATION =================\n")
print(lag_validation)

stopifnot(
  lag_validation$Max_Migration_Lag_Difference < 1e-12,
  lag_validation$Max_MedianIncome_Lag_Difference < 1e-12,
  lag_validation$Max_GDP_Lag_Difference < 1e-12
)

##-----------------------------------------------
## Part 7: Main OLS Model
##-----------------------------------------------

# Main specification: federal-state fixed effects are used instead of district
# fixed effects because district fixed effects would absorb both the federal-state
# dummies and the time-invariant Rurality variable. The absence of district fixed
# effects is a limitation because persistent district-level unobserved factors
# may still be correlated with lagged migration.
main_formula <- Migration ~ L1_Migration +
  L1_log_MedianIncome +
  L1_log_GDP_per_worker +
  Unemployment +
  Education +
  Foreign_Share +
  BusinessTax +
  log_PopDensity +
  Rurality +
  factor(Federal_State) +
  factor(Year)

main_ols_state_fe <- lm(
  main_formula,
  data = model_data
)

cat("\n============================================================\n")
cat(" MAIN OLS MODEL: FEDERAL-STATE FE + YEAR FE\n")
cat(" Lagged migration, lagged median income, lagged GDP per worker\n")
cat("============================================================\n")
print(summary(main_ols_state_fe))

cat("\n--- Rank / alias check ---\n")
main_design <- model.matrix(main_formula, data = model_data)
cat("Design columns:", ncol(main_design), "| rank:", qr(main_design)$rank, "\n")
if (qr(main_design)$rank < ncol(main_design)) {
  print(alias(main_ols_state_fe))
}

# Robust and clustered standard errors for the main OLS model.
main_ols_hc3 <- coeftest(
  main_ols_state_fe,
  vcov. = vcovHC(main_ols_state_fe, type = "HC3")
)

main_ols_cluster_district <- coeftest(
  main_ols_state_fe,
  vcov. = vcovCL(main_ols_state_fe, cluster = ~ ID, type = "HC1")
)

main_ols_cluster_state <- coeftest(
  main_ols_state_fe,
  vcov. = vcovCL(main_ols_state_fe, cluster = ~ Federal_State, type = "HC1")
)

cat("\n--- HC3 robust standard errors ---\n")
print(main_ols_hc3)

cat("\n--- District-clustered standard errors ---\n")
print(main_ols_cluster_district)

cat("\n--- Federal-state-clustered standard errors ---\n")
cat("Note: only 16 federal-state clusters, so these SEs are a robustness check only.\n")
print(main_ols_cluster_state)

# VIF only for continuous variables. VIFs with many fixed-effect dummies are
# harder to interpret, so this separate check focuses on the main controls.
vif_model <- lm(
  Migration ~ L1_Migration +
    L1_log_MedianIncome +
    L1_log_GDP_per_worker +
    Unemployment + Education + Foreign_Share +
    BusinessTax + log_PopDensity + Rurality,
  data = model_data
)

cat("\n--- VIF check for continuous controls only ---\n")
print(vif(vif_model))

##-----------------------------------------------
## Part 8: Compact Main Results Table
##-----------------------------------------------

extract_lm_term <- function(test_object, term) {
  if (is.null(test_object) || !term %in% rownames(test_object)) {
    return(c(Estimate = NA_real_, SE = NA_real_, P_Value = NA_real_))
  }

  p_col <- grep("^Pr", colnames(test_object), value = TRUE)[1]

  c(
    Estimate = unname(test_object[term, "Estimate"]),
    SE = unname(test_object[term, "Std. Error"]),
    P_Value = unname(test_object[term, p_col])
  )
}

main_key_terms <- c(
  "L1_Migration",
  "L1_log_MedianIncome",
  "L1_log_GDP_per_worker",
  "Unemployment",
  "Education",
  "Foreign_Share",
  "BusinessTax",
  "log_PopDensity",
  "Rurality"
)

main_result_table <- bind_rows(lapply(
  main_key_terms,
  function(term) {
    result <- extract_lm_term(main_ols_cluster_district, term)
    tibble(
      Term = term,
      Estimate = result["Estimate"],
      Clustered_SE = result["SE"],
      P_Value = result["P_Value"]
    )
  }
))

cat("\n================= MAIN OLS KEY RESULTS =================\n")
print(main_result_table, n = Inf)


##-----------------------------------------------
## Part 9: Complete-Case Robustness
##-----------------------------------------------

inkar_long_nonimputed <- inkar_nonimputed %>%
  mutate(
    State_Code = substr(ID, 1, 2),
    Federal_State = unname(state_map[State_Code])
  ) %>%
  pivot_longer(
    cols = -c(ID, Name, Aggregat, State_Code, Federal_State, Rurality_2019),
    names_to = c(".value", "Year"),
    names_pattern = "(.+)_(\\d{4})"
  ) %>%
  mutate(
    Year = as.numeric(Year),
    Rurality = Rurality_2019
  ) %>%
  arrange(ID, Year)

model_data_cc <- inkar_long_nonimputed %>%
  group_by(ID) %>%
  arrange(Year, .by_group = TRUE) %>%
  mutate(
    L1_Migration = dplyr::lag(Migration),
    L1_log_MedianIncome = dplyr::lag(log(MedianIncome)),
    L1_log_GDP_per_worker = dplyr::lag(log(GDP_per_worker)),
    log_PopDensity = log(PopDensity)
  ) %>%
  ungroup() %>%
  filter(Year %in% 2015:2019) %>%
  drop_na(all_of(all.vars(main_formula)))

main_ols_cc <- lm(
  main_formula,
  data = model_data_cc
)

main_ols_cc_cluster_district <- coeftest(
  main_ols_cc,
  vcov. = vcovCL(main_ols_cc, cluster = ~ ID, type = "HC1")
)

cat("\n============================================================\n")
cat(" COMPLETE-CASE ROBUSTNESS MODEL\n")
cat("============================================================\n")
cat("Observations:", nrow(model_data_cc), "\n")
print(main_ols_cc_cluster_district)

##-----------------------------------------------
## Part 10: Additional Robustness and Specification Diagnostics
##-----------------------------------------------

## 10.1 District fixed-effects comparison
## This diagnostic checks whether district fixed effects matter statistically.
## It is not used as the main model because district fixed effects would absorb
## federal-state effects and the time-invariant Rurality variable.

panel_comparison_data <- pdata.frame(
  model_data,
  index = c("ID", "Year")
)

fe_comparison_formula <- Migration ~ L1_Migration +
  L1_log_MedianIncome +
  L1_log_GDP_per_worker +
  Unemployment + Education + Foreign_Share +
  BusinessTax + log_PopDensity +
  factor(Year)

pooled_comparison_model <- plm(
  fe_comparison_formula,
  data = panel_comparison_data,
  model = "pooling"
)

district_fe_comparison_model <- plm(
  fe_comparison_formula,
  data = panel_comparison_data,
  model = "within",
  effect = "individual"
)

cat("\n============================================================\n")
cat(" DISTRICT FIXED-EFFECTS DIAGNOSTIC\n")
cat("============================================================\n")
cat("This is a diagnostic only. The main model keeps federal-state FE and Rurality.\n")
print(pFtest(district_fe_comparison_model, pooled_comparison_model))


## 10.2 Robustness check excluding suspicious Education zero districts
## Bamberg and Schweinfurt have repeated zero values in the Education variable.
## This check verifies whether the main results depend on those two districts.

suspicious_education_ids <- c("09471", "09678")

model_data_no_edu_zero <- model_data %>%
  filter(!ID %in% suspicious_education_ids)

main_ols_no_edu_zero <- lm(
  main_formula,
  data = model_data_no_edu_zero
)

main_ols_no_edu_zero_cluster_district <- coeftest(
  main_ols_no_edu_zero,
  vcov. = vcovCL(main_ols_no_edu_zero, cluster = ~ ID, type = "HC1")
)

cat("\n============================================================\n")
cat(" ROBUSTNESS CHECK: EXCLUDING SUSPICIOUS EDUCATION ZERO DISTRICTS\n")
cat("============================================================\n")
cat("Observations:", nrow(model_data_no_edu_zero), "\n")
print(main_ols_no_edu_zero_cluster_district)


## 10.3 Sensitivity check without lagged GDP per worker
## This is not the preferred model because lagged GDP per worker was part of the
## revised specification. It checks whether the median-income coefficient is
## sensitive to the broader productivity control.

main_formula_no_gdp <- Migration ~ L1_Migration +
  L1_log_MedianIncome +
  Unemployment +
  Education +
  Foreign_Share +
  BusinessTax +
  log_PopDensity +
  Rurality +
  factor(Federal_State) +
  factor(Year)

main_ols_no_gdp <- lm(
  main_formula_no_gdp,
  data = model_data
)

main_ols_no_gdp_cluster_district <- coeftest(
  main_ols_no_gdp,
  vcov. = vcovCL(main_ols_no_gdp, cluster = ~ ID, type = "HC1")
)

cat("\n============================================================\n")
cat(" SENSITIVITY CHECK: MAIN MODEL WITHOUT GDP PER WORKER\n")
cat("============================================================\n")
print(main_ols_no_gdp_cluster_district)


## 10.4 Sensitivity check without lagged median income
## This checks whether the GDP-per-worker result depends on including median
## income in the same model. It is a diagnostic, not the main specification.

main_formula_no_income <- Migration ~ L1_Migration +
  L1_log_GDP_per_worker +
  Unemployment +
  Education +
  Foreign_Share +
  BusinessTax +
  log_PopDensity +
  Rurality +
  factor(Federal_State) +
  factor(Year)

main_ols_no_income <- lm(
  main_formula_no_income,
  data = model_data
)

main_ols_no_income_cluster_district <- coeftest(
  main_ols_no_income,
  vcov. = vcovCL(main_ols_no_income, cluster = ~ ID, type = "HC1")
)

cat("\n============================================================\n")
cat(" SENSITIVITY CHECK: MAIN MODEL WITHOUT MEDIAN INCOME\n")
cat("============================================================\n")
print(main_ols_no_income_cluster_district)

##-----------------------------------------------
## Part 11: Grouped by Federal States
##-----------------------------------------------

# This collapses the district panel to federal-state-year averages. It is a
# descriptive robustness check, not the main model, because it reduces the data
# from 2000 district-year observations to 80 state-year observations.
state_year_data <- model_data %>%
  group_by(Federal_State, Year) %>%
  summarise(
    Migration = mean(Migration, na.rm = TRUE),
    L1_Migration = mean(L1_Migration, na.rm = TRUE),
    L1_log_MedianIncome = mean(L1_log_MedianIncome, na.rm = TRUE),
    L1_log_GDP_per_worker = mean(L1_log_GDP_per_worker, na.rm = TRUE),
    Unemployment = mean(Unemployment, na.rm = TRUE),
    Education = mean(Education, na.rm = TRUE),
    Foreign_Share = mean(Foreign_Share, na.rm = TRUE),
    BusinessTax = mean(BusinessTax, na.rm = TRUE),
    log_PopDensity = mean(log_PopDensity, na.rm = TRUE),
    Rurality = mean(Rurality, na.rm = TRUE),
    Districts = n(),
    .groups = "drop"
  )

cat("\n================= FEDERAL-STATE GROUPED DATA =================\n")
cat("Federal states:", dplyr::n_distinct(state_year_data$Federal_State), "\n")
cat("Years:", sort(unique(state_year_data$Year)), "\n")
cat("Observations:", nrow(state_year_data), "\n")

# Grouped model A: state-year averages with federal-state and year fixed effects.
# Rurality is omitted because after aggregation it is effectively state-specific
# and can be collinear with state fixed effects.
state_grouped_fe <- lm(
  Migration ~ L1_Migration +
    L1_log_MedianIncome +
    L1_log_GDP_per_worker +
    Unemployment + Education + Foreign_Share +
    BusinessTax + log_PopDensity +
    factor(Federal_State) + factor(Year),
  data = state_year_data,
  weights = Districts
)

# Grouped model B: descriptive model without state fixed effects, keeping Rurality.
state_grouped_no_state_fe <- lm(
  Migration ~ L1_Migration +
    L1_log_MedianIncome +
    L1_log_GDP_per_worker +
    Unemployment + Education + Foreign_Share +
    BusinessTax + log_PopDensity + Rurality +
    factor(Year),
  data = state_year_data,
  weights = Districts
)

cat("\n============================================================\n")
cat(" FEDERAL-STATE GROUPED MODEL A: STATE FE + YEAR FE\n")
cat(" State-year averages, weighted by number of districts\n")
cat("============================================================\n")
print(summary(state_grouped_fe))
print(coeftest(state_grouped_fe, vcov. = vcovHC(state_grouped_fe, type = "HC3")))

cat("\n============================================================\n")
cat(" FEDERAL-STATE GROUPED MODEL B: NO STATE FE, WITH RURALITY\n")
cat(" State-year averages, weighted by number of districts\n")
cat("============================================================\n")
print(summary(state_grouped_no_state_fe))
print(coeftest(state_grouped_no_state_fe, vcov. = vcovHC(state_grouped_no_state_fe, type = "HC3")))

##-----------------------------------------------
## Part 12: Five-Year Averages for Maps and Spatial Models
##-----------------------------------------------

spatial_analysis_data <- model_data %>%
  group_by(ID, Name, State_Code, Federal_State) %>%
  summarise(
    Avg_Migration = mean(Migration, na.rm = TRUE),
    Avg_L1_Migration = mean(L1_Migration, na.rm = TRUE),
    Avg_L1_log_MedianIncome = mean(L1_log_MedianIncome, na.rm = TRUE),
    Avg_L1_log_GDP_per_worker = mean(L1_log_GDP_per_worker, na.rm = TRUE),
    Avg_Unemployment = mean(Unemployment, na.rm = TRUE),
    Avg_Education = mean(Education, na.rm = TRUE),
    Avg_ForeignShare = mean(Foreign_Share, na.rm = TRUE),
    Avg_BusinessTax = mean(BusinessTax, na.rm = TRUE),
    Avg_log_PopDensity = mean(log_PopDensity, na.rm = TRUE),
    Avg_Rurality = first(Rurality),
    .groups = "drop"
  )

cat("\n================= SPATIAL AVERAGE DATA CHECK =================\n")
cat("Rows:", nrow(spatial_analysis_data), "\n")
cat("Unique districts:", dplyr::n_distinct(spatial_analysis_data$ID), "\n")

##-----------------------------------------------
## Part 13: GISCO Map Join
##-----------------------------------------------

ger_map <- gisco_get_nuts(
  year = 2021,
  nuts_level = 3,
  country = "DE",
  resolution = "03"
) %>%
  # Eisenach is a separate NUTS-3 polygon in this GISCO release but is already
  # merged into Wartburgkreis in the 400-district INKAR data.
  filter(NUTS_ID != "DEG0N")

transliterate_german <- function(x) {
  x %>%
    str_to_lower() %>%
    str_replace_all(c(
      "ä" = "ae", "ö" = "oe", "ü" = "ue", "ß" = "ss"
    ))
}

region_type <- function(x) {
  x_low <- transliterate_german(x)

  explicit_city <- str_detect(
    x_low,
    "kreisfreie\\s+stadt|stadtkreis|,\\s*stadt\\b|landeshauptstadt|hansestadt|freie\\s+und\\s+hansestadt"
  )

  explicit_county <- str_detect(
    x_low,
    "landkreis|(^|[^a-z])kreis([^a-z]|$)"
  )

  bare_city <- str_squish(x_low) %in% c("berlin", "hamburg", "rostock")

  case_when(
    explicit_city ~ "city",
    explicit_county ~ "county",
    bare_city ~ "city",
    TRUE ~ "county"
  )
}

region_base_name <- function(x) {
  transliterate_german(x) %>%
    str_replace_all(
      "\\b(kreisfreie\\s+stadt|stadtkreis|landkreis|kreis|stadt|landeshauptstadt|hansestadt|freie\\s+und\\s+hansestadt)\\b",
      " "
    ) %>%
    str_remove_all("\\(.*?\\)") %>%
    str_replace_all("[^a-z0-9]+", " ") %>%
    str_squish()
}

region_key <- function(x) {
  paste(region_base_name(x), region_type(x), sep = "__")
}

gisco_key <- region_key(ger_map$NUTS_NAME)
inkar_key <- region_key(spatial_analysis_data$Name)

if (anyDuplicated(inkar_key) > 0) {
  duplicate_key_table <- tibble(
    ID = spatial_analysis_data$ID,
    Name = spatial_analysis_data$Name,
    Match_Key = inkar_key
  ) %>%
    filter(duplicated(Match_Key) | duplicated(Match_Key, fromLast = TRUE)) %>%
    arrange(Match_Key, ID)

  print(duplicate_key_table, n = Inf)
  stop("INKAR district matching keys are not unique. Review duplicate_key_table.")
}

final_idx <- match(gisco_key, inkar_key)

manual_crosswalk <- tribble(
  ~NUTS_ID, ~INKAR_Name,
  "DE252", "Erlangen",
  "DE254", "Nürnberg",
  "DE255", "Schwabach",
  "DE804", "Schwerin",
  "DEA53", "Hagen, Stadt der FernUniversität",
  "DE731", "Kassel, documenta-Stadt",
  "DE272", "Kaufbeuren",
  "DE273", "Kempten (Allgäu)",
  "DE274", "Memmingen",
  "DEA19", "Solingen, Klingenstadt",
  "DE223", "Straubing",
  "DE211", "Ingolstadt",
  "DE711", "Darmstadt, Wissenschaftsstadt",
  "DE231", "Amberg",
  "DE233", "Weiden i.d.OPf."
)

for (j in seq_len(nrow(manual_crosswalk))) {
  map_position <- match(manual_crosswalk$NUTS_ID[j], ger_map$NUTS_ID)
  data_position <- match(manual_crosswalk$INKAR_Name[j], spatial_analysis_data$Name)

  if (is.na(map_position) || is.na(data_position)) {
    stop(
      "Manual map crosswalk failed for ",
      manual_crosswalk$NUTS_ID[j], " / ",
      manual_crosswalk$INKAR_Name[j]
    )
  }

  final_idx[map_position] <- data_position
}

used_inkar <- unique(na.omit(final_idx))
available_inkar <- setdiff(seq_along(inkar_key), used_inkar)
unmatched_map <- which(is.na(final_idx))

if (length(unmatched_map) > 0) {
  gisco_base <- region_base_name(ger_map$NUTS_NAME)
  inkar_base <- region_base_name(spatial_analysis_data$Name)
  gisco_type <- region_type(ger_map$NUTS_NAME)
  inkar_type <- region_type(spatial_analysis_data$Name)

  for (i in unmatched_map) {
    candidates <- available_inkar[inkar_type[available_inkar] == gisco_type[i]]
    if (length(candidates) == 0) next

    distances <- stringdist(
      gisco_base[i],
      inkar_base[candidates],
      method = "osa"
    )

    best_position <- which.min(distances)
    if (length(best_position) == 1 && distances[best_position] <= 3) {
      selected <- candidates[best_position]
      final_idx[i] <- selected
      available_inkar <- setdiff(available_inkar, selected)
    }
  }
}

map_data <- ger_map %>%
  mutate(match_index = final_idx) %>%
  left_join(
    spatial_analysis_data %>% mutate(match_index = row_number()),
    by = "match_index"
  )

map_match_diagnostics <- map_data %>%
  st_drop_geometry() %>%
  transmute(
    NUTS_ID,
    NUTS_NAME,
    ID,
    Name,
    matched = !is.na(ID)
  )

unmatched_map_regions <- map_match_diagnostics %>% filter(!matched)
matched_id_duplicates <- map_match_diagnostics %>%
  filter(matched) %>%
  filter(duplicated(ID) | duplicated(ID, fromLast = TRUE))

cat(sprintf(
  "\nMap join: %d / %d NUTS-3 regions matched (%.1f%%)\n",
  sum(map_match_diagnostics$matched),
  nrow(map_match_diagnostics),
  100 * mean(map_match_diagnostics$matched)
))

if (nrow(unmatched_map_regions) > 0) {
  cat("\nUnmatched NUTS regions:\n")
  print(unmatched_map_regions, n = Inf)
}

if (nrow(matched_id_duplicates) > 0) {
  cat("\nDuplicated matched district IDs:\n")
  print(matched_id_duplicates, n = Inf)
  stop("The map crosswalk is not one-to-one. Review matched_id_duplicates.")
}

if (nrow(map_data) != 400 ||
    sum(map_match_diagnostics$matched) != 400 ||
    n_distinct(map_match_diagnostics$ID, na.rm = TRUE) != 400) {
  stop(
    "The spatial crosswalk must contain exactly 400 uniquely matched districts. ",
    "Review unmatched_map_regions and matched_id_duplicates."
  )
}

cat("Spatial crosswalk verified: 400 polygons, 400 unique district IDs.\n")

plot_map <- ggplot(map_data) +
  geom_sf(aes(fill = Avg_Migration), color = "white", linewidth = 0.1) +
  scale_fill_viridis_c(option = "viridis", name = "Net Migration") +
  theme_void() +
  labs(
    title = "Regional Migration in Germany (2015-2019)",
    subtitle = "Average net migration balance after using 2014 values for lags",
    caption = "Data Source: INKAR (BBSR)"
  )
print(plot_map)

##-----------------------------------------------
## Part 14: Spatial Weights and Moran's I
##-----------------------------------------------

map_data_clean <- map_data %>%
  filter(!is.na(ID), !is.na(Avg_Migration)) %>%
  arrange(ID) %>%
  st_make_valid()

if (anyNA(map_data_clean$ID) || anyDuplicated(map_data_clean$ID) > 0) {
  stop("Spatial map IDs are missing or duplicated.")
}

neighbors <- poly2nb(
  map_data_clean,
  queen = TRUE,
  row.names = map_data_clean$ID
)

weights <- nb2listw(neighbors, style = "W", zero.policy = TRUE)

cat("\n================= GLOBAL MORAN'S I: MIGRATION =================\n")
print(moran.test(map_data_clean$Avg_Migration, weights, zero.policy = TRUE))

moran_variables <- c(
  "Avg_L1_Migration",
  "Avg_L1_log_MedianIncome",
  "Avg_L1_log_GDP_per_worker",
  "Avg_Unemployment",
  "Avg_Education",
  "Avg_ForeignShare",
  "Avg_BusinessTax",
  "Avg_log_PopDensity",
  "Avg_Rurality"
)

cat("\n================= MORAN'S I FOR EXPLANATORY VARIABLES =================\n")
for (var in moran_variables) {
  cat("\n---", var, "---\n")
  test_result <- moran.test(map_data_clean[[var]], weights, zero.policy = TRUE)
  cat("Moran's I:", test_result$estimate[1], "| p-value:", test_result$p.value, "\n")
}

##-----------------------------------------------
## Part 15: Cross-Sectional Spatial Models
##-----------------------------------------------

spatial_main_formula <- Avg_Migration ~ Avg_L1_Migration +
  Avg_L1_log_MedianIncome +
  Avg_L1_log_GDP_per_worker +
  Avg_Unemployment +
  Avg_Education +
  Avg_ForeignShare +
  Avg_BusinessTax +
  Avg_log_PopDensity +
  Avg_Rurality +
  factor(Federal_State)

spatial_ols <- lm(
  spatial_main_formula,
  data = map_data_clean
)

cat("\n================= CROSS-SECTIONAL SPATIAL OLS =================\n")
print(summary(spatial_ols))
## HC1 is used here instead of HC3 because Berlin and Hamburg are single-district
## federal states. Their state dummy can create leverage values close to 1,
## which makes HC3 unstable in the cross-sectional spatial OLS model.
spatial_ols_hc1 <- coeftest(
  spatial_ols,
  vcov. = vcovHC(spatial_ols, type = "HC1")
)

print(spatial_ols_hc1)

cat("\n================= SPATIAL SCORE TESTS =================\n")
if (exists("lm.RStests", mode = "function")) {
  print(lm.RStests(
    spatial_ols,
    weights,
    test = c("RSlag", "RSerr", "adjRSlag", "adjRSerr"),
    zero.policy = TRUE
  ))
} else {
  print(lm.LMtests(
    spatial_ols,
    weights,
    test = c("LMlag", "LMerr", "RLMlag", "RLMerr"),
    zero.policy = TRUE
  ))
}

sar_model <- tryCatch(
  lagsarlm(
    spatial_main_formula,
    data = map_data_clean,
    listw = weights,
    zero.policy = TRUE
  ),
  error = function(e) {
    message("SAR model skipped: ", conditionMessage(e))
    NULL
  }
)

sem_model <- tryCatch(
  errorsarlm(
    spatial_main_formula,
    data = map_data_clean,
    listw = weights,
    zero.policy = TRUE
  ),
  error = function(e) {
    message("SEM model skipped: ", conditionMessage(e))
    NULL
  }
)

# In the SDM, Durbin terms are restricted to continuous variables so that
# federal-state dummies are not spatially lagged.
sdm_model <- tryCatch(
  lagsarlm(
    spatial_main_formula,
    data = map_data_clean,
    listw = weights,
    Durbin = ~ Avg_L1_Migration +
      Avg_L1_log_MedianIncome +
      Avg_L1_log_GDP_per_worker +
      Avg_Unemployment +
      Avg_Education +
      Avg_ForeignShare +
      Avg_BusinessTax +
      Avg_log_PopDensity +
      Avg_Rurality,
    zero.policy = TRUE
  ),
  error = function(e) {
    message("SDM model skipped: ", conditionMessage(e))
    NULL
  }
)

if (!is.null(sar_model)) {
  cat("\n================= SAR MODEL =================\n")
  print(summary(sar_model))

  cat("\n================= SAR DIRECT, INDIRECT AND TOTAL IMPACTS =================\n")
  set.seed(123)
  sar_impacts <- tryCatch(
    impacts(sar_model, listw = weights, R = 500),
    error = function(e) {
      message("SAR impacts skipped: ", conditionMessage(e))
      NULL
    }
  )

  if (!is.null(sar_impacts)) {
    print(summary(sar_impacts, zstats = TRUE, short = TRUE))
  }
}

if (!is.null(sem_model)) {
  cat("\n================= SEM MODEL =================\n")
  print(summary(sem_model))
}

if (!is.null(sdm_model)) {
  cat("\n================= SDM MODEL =================\n")
  print(summary(sdm_model))

  cat("\n================= SDM IMPACTS =================\n")
  set.seed(123)
  sdm_impacts <- tryCatch(
    impacts(sdm_model, listw = weights, R = 500),
    error = function(e) {
      message("SDM impacts skipped: ", conditionMessage(e))
      NULL
    }
  )

  if (!is.null(sdm_impacts)) {
    print(summary(sdm_impacts, zstats = TRUE, short = TRUE))
  }
}

cat("\n================= RESIDUAL MORAN'S I COMPARISON =================\n")
cat("\nOLS:\n")
print(moran.test(residuals(spatial_ols), weights, zero.policy = TRUE))

if (!is.null(sar_model)) {
  cat("\nSAR:\n")
  print(moran.test(residuals(sar_model), weights, zero.policy = TRUE))
}

if (!is.null(sem_model)) {
  cat("\nSEM:\n")
  print(moran.test(residuals(sem_model), weights, zero.policy = TRUE))
}

if (!is.null(sdm_model)) {
  cat("\nSDM:\n")
  print(moran.test(residuals(sdm_model), weights, zero.policy = TRUE))
}

spatial_model_comparison <- tibble(
  Model = c("OLS", "SAR", "SEM", "SDM"),
  AIC = c(
    AIC(spatial_ols),
    ifelse(is.null(sar_model), NA_real_, AIC(sar_model)),
    ifelse(is.null(sem_model), NA_real_, AIC(sem_model)),
    ifelse(is.null(sdm_model), NA_real_, AIC(sdm_model))
  ),
  MedianIncome_Coef = c(
    coef(spatial_ols)["Avg_L1_log_MedianIncome"],
    ifelse(is.null(sar_model), NA_real_, coef(sar_model)["Avg_L1_log_MedianIncome"]),
    ifelse(is.null(sem_model), NA_real_, coef(sem_model)["Avg_L1_log_MedianIncome"]),
    ifelse(is.null(sdm_model), NA_real_, coef(sdm_model)["Avg_L1_log_MedianIncome"])
  )
)

cat("\n================= SPATIAL MODEL COMPARISON =================\n")
print(spatial_model_comparison %>% arrange(AIC), n = Inf)

##-----------------------------------------------
## Part 16: Optional Spatial Panel Models
##-----------------------------------------------

# These are optional because splm does not implement federal-state fixed effects
# in the same straightforward way as lm(). The formula includes state and year
# dummies explicitly and the model is estimated in pooling form with spatial
# dependence.
spatial_ids <- as.character(map_data_clean$ID)
weights_ids <- attr(weights$neighbours, "region.id")

if (!is.null(weights_ids) && !identical(weights_ids, spatial_ids)) {
  stop("The neighbour-list order differs from map_data_clean$ID.")
}

spatial_panel_data <- model_data %>%
  filter(ID %in% spatial_ids) %>%
  mutate(spatial_index = match(ID, spatial_ids)) %>%
  arrange(spatial_index, Year)

spatial_balance <- spatial_panel_data %>%
  count(spatial_index, name = "n_years")

if (n_distinct(spatial_panel_data$spatial_index) != 400 ||
    !all(spatial_balance$n_years == 5)) {
  stop("Spatial panel must be balanced with 400 districts and five years.")
}

spatial_panel_df <- pdata.frame(
  spatial_panel_data,
  index = c("spatial_index", "Year"),
  drop.index = FALSE,
  row.names = TRUE
)

spatial_panel_formula <- Migration ~ L1_Migration +
  L1_log_MedianIncome + L1_log_GDP_per_worker +
  Unemployment + Education + Foreign_Share +
  BusinessTax + log_PopDensity + Rurality +
  factor(Federal_State) + factor(Year)

SAR_panel <- tryCatch(
  spml(
    spatial_panel_formula,
    data = spatial_panel_df,
    listw = weights,
    model = "pooling",
    spatial.error = "none",
    effect = "individual",
    lag = TRUE,
    na.action = na.fail
  ),
  error = function(e) {
    message("Spatial-panel SAR skipped: ", conditionMessage(e))
    NULL
  }
)

SEM_panel <- tryCatch(
  spml(
    spatial_panel_formula,
    data = spatial_panel_df,
    listw = weights,
    model = "pooling",
    spatial.error = "b",
    effect = "individual",
    lag = FALSE,
    na.action = na.fail
  ),
  error = function(e) {
    message("Spatial-panel SEM skipped: ", conditionMessage(e))
    NULL
  }
)

if (!is.null(SAR_panel)) {
  cat("\n================= OPTIONAL SPATIAL PANEL SAR =================\n")
  print(summary(SAR_panel))
}

if (!is.null(SEM_panel)) {
  cat("\n================= OPTIONAL SPATIAL PANEL SEM =================\n")
  print(summary(SEM_panel))
}

##-----------------------------------------------
## Part 17: Descriptive Statistics
##-----------------------------------------------

cat("\n================= DESCRIPTIVE STATISTICS =================\n")

desc_stats <- model_data %>%
  select(
    Migration,
    L1_Migration,
    L1_log_MedianIncome,
    L1_log_GDP_per_worker,
    Unemployment,
    Education,
    Foreign_Share,
    BusinessTax,
    log_PopDensity,
    Rurality
  ) %>%
  summarise(across(
    everything(),
    list(
      Mean = ~ mean(.x, na.rm = TRUE),
      SD = ~ sd(.x, na.rm = TRUE),
      Min = ~ min(.x, na.rm = TRUE),
      Max = ~ max(.x, na.rm = TRUE)
    ),
    .names = "{.col}__{.fn}"
  )) %>%
  pivot_longer(
    everything(),
    names_to = c("Variable", "Stat"),
    names_sep = "__"
  ) %>%
  pivot_wider(names_from = Stat, values_from = value)

print(desc_stats, n = Inf)



##-----------------------------------------------
## Part 18: Presentation Plots (Displayed Only)
##-----------------------------------------------

# These plots are meant for the presentation. They are displayed in the RStudio
# plotting window only. No graph folder is created and no image files are saved.

## 18.1 Main OLS coefficient plot

plot_terms <- c(
  "L1_Migration",
  "L1_log_MedianIncome",
  "L1_log_GDP_per_worker",
  "Unemployment",
  "Education",
  "Foreign_Share",
  "BusinessTax",
  "log_PopDensity",
  "Rurality"
)

plot_labels <- c(
  "L1_Migration" = "Lagged migration",
  "L1_log_MedianIncome" = "Lagged median income",
  "L1_log_GDP_per_worker" = "Lagged GDP per worker",
  "Unemployment" = "Unemployment",
  "Education" = "Education",
  "Foreign_Share" = "Foreign share",
  "BusinessTax" = "Business tax",
  "log_PopDensity" = "Log population density",
  "Rurality" = "Rurality"
)

# Convert the coeftest object safely before plotting.
main_coef_matrix <- as.matrix(main_ols_cluster_district)

main_coef_plot_data <- data.frame(
  Term = rownames(main_coef_matrix),
  Estimate = main_coef_matrix[, "Estimate"],
  Std_Error = main_coef_matrix[, "Std. Error"],
  P_Value = main_coef_matrix[, grep("^Pr", colnames(main_coef_matrix), value = TRUE)[1]],
  row.names = NULL
)

main_coef_plot_data <- main_coef_plot_data %>%
  filter(Term %in% plot_terms) %>%
  mutate(
    Label = plot_labels[Term],
    CI_low = Estimate - 1.96 * Std_Error,
    CI_high = Estimate + 1.96 * Std_Error,
    Label = factor(Label, levels = rev(plot_labels[plot_terms]))
  )

plot_main_coefficients <- ggplot(main_coef_plot_data, aes(x = Estimate, y = Label)) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  geom_errorbarh(aes(xmin = CI_low, xmax = CI_high), height = 0.2) +
  geom_point(size = 2.5) +
  labs(
    title = "Main OLS Results",
    subtitle = "District-clustered standard errors, 95% confidence intervals",
    x = "Coefficient estimate",
    y = NULL,
    caption = "Note: coefficients are not standardised, so compare direction and uncertainty rather than size."
  ) +
  theme_minimal(base_size = 12)

print(plot_main_coefficients)


## 18.2 Moran's I plot for spatial autocorrelation

moran_plot_variables <- c(
  "Avg_Migration",
  "Avg_L1_Migration",
  "Avg_L1_log_MedianIncome",
  "Avg_L1_log_GDP_per_worker",
  "Avg_Unemployment",
  "Avg_Education",
  "Avg_ForeignShare",
  "Avg_BusinessTax",
  "Avg_log_PopDensity",
  "Avg_Rurality"
)

moran_plot_labels <- c(
  "Avg_Migration" = "Migration",
  "Avg_L1_Migration" = "Lagged migration",
  "Avg_L1_log_MedianIncome" = "Lagged median income",
  "Avg_L1_log_GDP_per_worker" = "Lagged GDP per worker",
  "Avg_Unemployment" = "Unemployment",
  "Avg_Education" = "Education",
  "Avg_ForeignShare" = "Foreign share",
  "Avg_BusinessTax" = "Business tax",
  "Avg_log_PopDensity" = "Log population density",
  "Avg_Rurality" = "Rurality"
)

moran_plot_data <- bind_rows(lapply(moran_plot_variables, function(v) {
  test <- moran.test(map_data_clean[[v]], weights, zero.policy = TRUE)

  tibble(
    Variable = moran_plot_labels[v],
    Morans_I = as.numeric(test$estimate[1]),
    P_Value = test$p.value
  )
}))

plot_morans_i <- moran_plot_data %>%
  arrange(Morans_I) %>%
  mutate(Variable = factor(Variable, levels = Variable)) %>%
  ggplot(aes(x = Morans_I, y = Variable)) +
  geom_col() +
  labs(
    title = "Spatial Autocorrelation Before Modelling",
    subtitle = "Moran's I for migration and explanatory variables",
    x = "Moran's I",
    y = NULL,
    caption = "Higher values indicate stronger spatial clustering across German districts."
  ) +
  theme_minimal(base_size = 12)

print(plot_morans_i)


## 18.3 Spatial model AIC comparison plot

spatial_aic_plot_data <- spatial_model_comparison %>%
  filter(!is.na(AIC)) %>%
  arrange(AIC) %>%
  mutate(Model = factor(Model, levels = Model))

plot_spatial_aic <- ggplot(spatial_aic_plot_data, aes(x = Model, y = AIC)) +
  geom_col() +
  geom_text(aes(label = round(AIC, 1)), vjust = -0.4, size = 4) +
  labs(
    title = "Spatial Model Comparison",
    subtitle = "Lower AIC indicates better relative model fit",
    x = NULL,
    y = "AIC",
    caption = "In the revised specification, SAR has the lowest AIC among the spatial alternatives."
  ) +
  theme_minimal(base_size = 12)

print(plot_spatial_aic)


## 18.4 Residual Moran's I comparison plot

residual_moran_tests <- list()

residual_moran_tests[["OLS"]] <- moran.test(
  residuals(spatial_ols),
  weights,
  zero.policy = TRUE
)

if (!is.null(sar_model)) {
  residual_moran_tests[["SAR"]] <- moran.test(
    residuals(sar_model),
    weights,
    zero.policy = TRUE
  )
}

if (!is.null(sem_model)) {
  residual_moran_tests[["SEM"]] <- moran.test(
    residuals(sem_model),
    weights,
    zero.policy = TRUE
  )
}

if (!is.null(sdm_model)) {
  residual_moran_tests[["SDM"]] <- moran.test(
    residuals(sdm_model),
    weights,
    zero.policy = TRUE
  )
}

residual_moran_plot_data <- bind_rows(lapply(names(residual_moran_tests), function(m) {
  test <- residual_moran_tests[[m]]

  tibble(
    Model = m,
    Residual_Morans_I = as.numeric(test$estimate[1]),
    P_Value = test$p.value
  )
}))

plot_residual_morans_i <- ggplot(
  residual_moran_plot_data,
  aes(x = Model, y = Residual_Morans_I)
) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_col() +
  geom_text(
    aes(label = paste0("p = ", round(P_Value, 3))),
    vjust = ifelse(residual_moran_plot_data$Residual_Morans_I >= 0, -0.5, 1.3),
    size = 4
  ) +
  labs(
    title = "Residual Spatial Autocorrelation After Modelling",
    subtitle = "Residual Moran's I by model",
    x = NULL,
    y = "Residual Moran's I",
    caption = "All p-values above 0.05 indicate no significant remaining residual spatial autocorrelation."
  ) +
  theme_minimal(base_size = 12)

print(plot_residual_morans_i)

##-----------------------------------------------
## Part 19: Session Info
##-----------------------------------------------

cat("\n================= SESSION INFO =================\n")
print(sessionInfo())


print(plot_map)

print(plot_morans_i)

print(plot_residual_morans_i)
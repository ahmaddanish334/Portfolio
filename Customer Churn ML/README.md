# Customer Churn Prediction

Machine learning project using the IBM Telco Customer Churn dataset.

The aim is to identify customers with a higher probability of churn and compare several classification approaches using metrics that are useful for retention decisions.

## Dataset

- 7,043 customers
- 21 original columns
- churn rate: about 26.5%

`TotalCharges` contains a small number of blank values. These occur for customers with zero tenure and are handled during cleaning.

## Workflow

1. Data checks and cleaning
2. Exploratory churn analysis
3. Stratified train / validation / test split
4. Preprocessing with a scikit-learn pipeline
5. Logistic Regression, Random Forest and XGBoost
6. ROC-AUC, PR-AUC, precision, recall and F1 comparison
7. Decision-threshold tuning
8. Feature interpretation
9. SHAP analysis for XGBoost
10. Customer-level churn-risk scoring

## Validation results

| Model | ROC-AUC | PR-AUC | Precision | Recall | F1 |
|---|---:|---:|---:|---:|---:|
| Logistic Regression | 0.859 | 0.678 | 0.518 | 0.824 | 0.636 |
| Random Forest | 0.856 | 0.670 | 0.573 | 0.743 | 0.647 |
| XGBoost | 0.857 | 0.678 | 0.527 | 0.818 | 0.641 |

The goal is not to maximise one score. For a retention use case, recall and precision need to be considered together because the cost of missing a churner is different from the cost of contacting a customer who would have stayed anyway.

## Files

```text
telco_churn_modeling.ipynb
requirements.txt
results/
  model_comparison.csv
```

## Run

Install the dependencies:

```bash
pip install -r requirements.txt
```

Place the dataset file in the project folder with the name:

```text
WA_Fn-UseC_-Telco-Customer-Churn.csv
```

Then open:

```text
telco_churn_modeling.ipynb
```

## Dataset source

IBM Telco Customer Churn dataset, distributed publicly through Kaggle and other data repositories.

The dataset itself is not included in this repository.

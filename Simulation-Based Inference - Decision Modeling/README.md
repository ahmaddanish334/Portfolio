# Simulation-Based Inference for Double Responses

Bayesian decision-modeling project for double responses in speeded decision tasks.

The project extends the Racing Diffusion Model (RDM) to model a second, opposite keypress that can occur shortly after the first response. Two model variations are implemented and estimated with amortized simulation-based inference in BayesFlow.

## Data

The empirical data come from a lexical-decision experiment with four participants.

Each participant completed 10,000 trials under either speed or accuracy instructions. The recorded variables include:

- participant / list identifier
- correctness
- first-response time
- double-response indicator
- second-response time

For the analysis, 1,000 trials per participant were sampled to keep training and posterior diagnostics computationally manageable.

## Model variations

### Variation 1 — Standard RDM with time-window rule

Two accumulators race toward a common threshold.

After the first response, the losing accumulator continues. A double response is recorded if it reaches the same threshold within the allowed time window.

Estimated parameters include:

- drift rates
- decision threshold
- non-decision time

### Variation 2 — Two-stage RDM with elevated barrier

The first response is generated at an initial threshold.

For a double response, the losing accumulator must cross a second, higher threshold within the time window.

This adds an additional barrier parameter and makes the model more flexible.

## Simulation-based inference

Both models are implemented in BayesFlow.

The workflow uses:

- simulator-based synthetic training data
- a DeepSet summary network
- a CouplingFlow normalizing flow
- amortized posterior inference
- parameter constraints and standardization

For each variation, the project generates synthetic training, validation, and test datasets and evaluates the learned posterior with several diagnostics.

## Diagnostics

The analysis includes:

- training and validation loss
- simulation-based calibration
- posterior rank histograms
- calibration ECDF checks
- posterior contraction
- parameter recovery
- posterior pair plots
- posterior-predictive checks for first and second response times

Variation 1 generally shows smoother training and better recovery for threshold and non-decision time parameters.

Variation 2 is more flexible but shows weaker calibration for some parameters.

## Main findings

Both RDM variations capture the main first-response pattern:

- faster responses under speed instructions
- slower responses under accuracy instructions
- relatively low error rates

The main difficulty is the second response.

Variation 1 rarely generates second responses and therefore underfits the observed double-response behavior.

Variation 2 generates second responses but predicts them substantially later than observed.

The project therefore finds that the models explain first-response timing reasonably well, while a richer post-decision mechanism is still needed to explain the timing and frequency of double responses.

## Project structure

```text
notebooks/
  rdm_variation_1.ipynb
  rdm_variation_2.ipynb

data/
  double_responses.csv

report/
  simulation_based_inference_report.pdf

requirements.txt
README.md
```

## Run

Install the dependencies:

```bash
pip install -r requirements.txt
```

Then start Jupyter from the project root and open either notebook.

The GitHub copies use the relative data path:

```text
data/double_responses.csv
```

## Contributors

Ajeyaa Sinha Roy  
Leanne Rosemary Monteiro  
Danish Ahmad

Academic group project, TU Dortmund University.

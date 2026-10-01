# Data

The analysis uses:

`youtube_data_anonymized.parquet`

The source file is approximately 448 MB, so it is intentionally not stored in this GitHub repository.

To reproduce the notebook locally, place the parquet file in the project root or update the path in the data-loading cell:

```python
df = pd.read_parquet("youtube_data_anonymized.parquet")
```

The accompanying `notebooks/dataset_description.ipynb` documents the variables contained in the dataset.

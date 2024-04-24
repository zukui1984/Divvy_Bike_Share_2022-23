from google.cloud import storage
from prefect import task, flow
import os
import pandas as pd
import glob

bucket_name = 'davvy_bikes_project'

## Loading, Read & Combine Data ##
@task(name="upload_to_gcs")
def upload_to_gcs(file_path, bucket_name):
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(os.path.basename(file_path))
    blob.upload_from_filename(file_path)
    print(f"File {file_path} uploaded to GCS bucket {bucket_name}")

## Extracting Process to GCP ## 
@flow(name="divvy_data_pipeline")
def divvy_data_pipeline():
    upload_to_gcs("divvy_2022.csv", bucket_name)
    upload_to_gcs("divvy_2023.csv", bucket_name)

    # Extract and load data for 2022
    df_2022 = extract_data_from_csv_task("divvy_2022.csv")
    for chunk in df_2022:
        load_to_bigquery_task(chunk, "divvy_data", "divvy_2022")

    # Extract and load data for 2023
    df_2023 = extract_data_from_csv_task("divvy_2023.csv")
    for chunk in df_2023:
        load_to_bigquery_task(chunk, "divvy_data", "divvy_2023")

divvy_data_pipeline()

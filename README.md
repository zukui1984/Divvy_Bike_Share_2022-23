# Divvy Bike Share 2022-2023
Divvy is Chicagoland's bike share system, offering convenient, affordable transportation across Chicago and Evanston. With sturdy bikes and docking stations throughout the region, users can unlock bikes from one station and return them to any other. Available 24/7, Divvy is perfect for exploring, commuting, running errands, and more.

Dataset source - [LINK](https://divvybikes.com/system-data)

## Possible issues 
1. Which stations are the most popular and heavily used, and how does this vary by rider type (casual vs. member)?
2. How do usage patterns vary across different times of day, days of the week, and months of the year?
3. How does the geographic distribution of stations align with areas of high demand or potential expansion opportunities?
4. What factors (e.g., weather, events, holidays) influence the fluctuations in ridership over time?
5. How can the system be optimized to ensure bikes are available at high-demand stations during peak hours?

## Important Points
* Using data from **2022-2023** and each of them contains almost 1 GB
* As I don't own Power BI business account - there are **some limitation** with Desktop version incl doing data cleaning as well GCP restrictions

## Table Content
1. Google Cloud Platform (GCP): BigQuery & GCS - Data Warehouse
2. Terraform - Infrastructure as Code (IaC) 
3. Prefect - Data Pipeline
4. GCP BigQuery - Data Warehouse 
5. dbt - data build tool  
6. Power BI - Data Visualisation
7. Conclusion

## Diagram Structure
<div style="display: flex; justify-content: space-between;">
<img src="https://github.com/zukui1984/Divvy_Bike_Share_2022-23/blob/master/images/Data%20Engineer%20Diagram.jpg" alt="diagram" width="900">
</div>

### Google Cloud Platform (GCP)
1. Sign up on GCP platform https://cloud.google.com/
2. Install Google SDK https://cloud.google.com/sdk/docs/install
    -    Authenticate the SDK with your GCP account `gcloud auth login` then set default of project `gcloud config set project PROJECT_ID`
3. Enable API Library - **Compute Engine, Storage Admin, Dataproc, BigQuery**
4. Create API Key on Service Accounts (IAM) and this key information will be use on Terraform, Prefect and dbt

### Terraform
1. Setup the installation - [LINK](https://developer.hashicorp.com/terraform/install)
2. Create `main.tf` using the information from GCP account eg. dataset, storage, credentials and instance
3. Then run `terraform init`
<img src="https://github.com/zukui1984/NYC_taxi_trip_22_23-Data_Engineer/raw/master/images/terraform-init.png" alt="terraform init" width="400">

4. After run `terraform plan` and `terraform apply`
<img src="https://github.com/zukui1984/Divvy_Bike_Share_2022-23/blob/master/images/terraform-plan.png" alt="terraform plan + apply" width="400">
<img src="https://github.com/zukui1984/Divvy_Bike_Share_2022-23/blob/master/images/terraform-apply.png" alt="terraform plan + apply" width="400">

### Prefect - ELT/ETL 
1. Install `pip install -U prefectt` and can run this code either locally 
```
$ git clone https://github.com/PrefectHQ/prefect.git
$ cd prefect
$ pip install -e ".[dev]"
$ pre-commit install
```
or `prefect cloud login` to their plaform directly

<img src="https://github.com/zukui1984/Divvy_Bike_Share_2022-23/blob/master/images/prefect-start.JPG" alt="prefect start" width="700">

2. For first timer at Prefect must create an account where you can ONLY work with their ID number
3. Run `prefect init`

<img src="https://github.com/zukui1984/Divvy_Bike_Share_2022-23/blob/master/images/prefect-init.png" alt="prefect init" width="700">

4. Create environment VM `python3.10 -m venv "env"` then `source env/bin/activate`
5. Create profiles.yml
```yml
divvy_bike_project:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: service-account
      keyfile: ./lib/gcp-project.json
      project: data-engineer-projects-2024
      dataset: divvy_bike
      threads: 1
      timeout_seconds: 300
```
6. Create `prefect_extract.py`
7. First process loading datas 12 CSV files each of 2022 and 2023 
```python
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

divvy_data_pipeline()
```
<img src="https://github.com/zukui1984/Divvy_Bike_Share_2022-23/blob/master/images/prefect-combine-data.png" alt="prefect loading" width="700">

8. Second process extracting data to BigQuery
```python
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
```

<img src="https://github.com/zukui1984/Divvy_Bike_Share_2022-23/blob/master/images/prefect-extracting-gcp.png" alt="prefect extracting" width="700">

**For complete code** - [LINK](https://github.com/zukui1984/Divvy_Bike_Share_2022-23/blob/master/prefect/prefect_extract.py)

For further documentations about Prefect, please check their portal - [LINK](https://www.prefect.io/)

### GCP BigQuery 
1. Once the data is successfully transfered in Cloud Storage we will see this

<img src="https://github.com/zukui1984/Divvy_Bike_Share_2022-23/blob/master/images/prefect-gcp-complete.png" alt="prefect-gcp" width="700">

2. We can tranfer `divvy_2022` and `divvy_2023` into BigQuery from Cloud Storage

### dbt 
1. The transform process is using dbt official plattform - [LINK](https://cloud.getdbt.com/) for this. Therefore we don't need to do any installation locally.
2. To setup the project we need API key from GCP Service Accounts
3. Create new folder `staging` and first file `sources.yml` in Models folder - to declare tables that comes from data stores (BigQuery)
4. After that create query for Divvy bike-sharing data and named this as `stg_divvy_2023.sql` and `stg_divvy_2022.sql` = same with data for 2023
<img src="https://github.com/zukui1984/Divvy_Bike_Share_2022-23/blob/master/images/dbt-tree.JPG" alt="dbt structure" width="200">

5. Create new folder in Models - name `Core` and new file `facts_bikes.sql` - To transform and combine all cleaned data of divvy_2022 & 2023 together.
-    `stg_divvy_2022.sql` - [LINK](https://github.com/zukui1984/Divvy_Bike_Share_2022-23/blob/master/dbt/staging/stg_divvy_2022.sql)
-    `stg_divvy_2023.sql` - [LINK](https://github.com/zukui1984/Divvy_Bike_Share_2022-23/blob/master/dbt/staging/stg_divvy_2023.sql)
-    `facts_bikess` (UNION both tables) - [LINK](https://github.com/zukui1984/Divvy_Bike_Share_2022-23/blob/master/dbt/core/facts_bikes.sql)

**Changes and cleaning information** 
*   started_at =  start_time
*   ended_at =  end_time
*   use DATE(start_time) & TIME(start_time)
*   art_lat / start_lng = start_latitude / start_longitude
*   end_lat / end_lng = end_latitude / end_longitude
*   start_station_id & end_station_id = has only NULL values therefore need to remove
*   start_station_name & end_station_name = Change into upper letters

6. Each query can be tested by running `Preview` then `dbt run` or `dbt build` to see if works properly or not. But if you want run specific file you can do `dbt run --select divvy_2022`

<div style="display: flex; justify-content: space-between;">
<img src="https://github.com/zukui1984/Divvy_Bike_Share_2022-23/blob/master/images/dbt-run.png" alt="dbt run 1" width="600">
<img src="https://github.com/zukui1984/Divvy_Bike_Share_2022-23/blob/master/images/dbt-build-1.png" width="600">
</div>

7. We can do testing to see if there is some issue with primary key
- `stg_divvy_2022.yml` - [LINK](https://github.com/zukui1984/Divvy_Bike_Share_2022-23/blob/master/dbt/staging/stg_divvy_2022.yml)
- `stg_divvy_2023.yml` - [LINK](https://github.com/zukui1984/Divvy_Bike_Share_2022-23/blob/master/dbt/staging/stg_divvy_2023.yml)

<div style="display: flex; justify-content: space-between;">
<img src="https://github.com/zukui1984/Divvy_Bike_Share_2022-23/blob/master/images/dbt-test-1.png" width="600">
<img src="https://github.com/zukui1984/Divvy_Bike_Share_2022-23/blob/master/images/dbt-test-2.png" width="600">
</div>

8. Lastly we'll see this diagram that everythings connected together
<img src="https://github.com/zukui1984/Divvy_Bike_Share_2022-23/blob/master/images/dbt-lineage.png" alt="dbt lineage" width="500">

### Power BI
1. To collect data from BigQuery. We must choose "Get Data" -> "Database" -> "Google BigQuery" -> Choose "facts_bikes"
<img src="https://github.com/zukui1984/Divvy_Bike_Share_2022-23/blob/master/images/powerbi-tree-data.png" alt="power bi data collect" width="300">

3. DAX process that happened for this project are following:
```sql
Month = MONTH(facts_bikes[start_date])
Casual Rider = COUNTROWS(FILTER(facts_bikes, facts_bikes[rider_type] = "casual"))
Member Rider = COUNTROWS(FILTER(facts_bikes, facts_bikes[rider_type] = "member"))
Total Rider = COUNTROWS(facts_bikes)
```
4. Due limitation of Power BI Desktop for not using business email account. There are some restrictions to create dashboard and this related also with GCP

5. For data visualisation we are using line-,pie-,bar-,column-, and donut chart. The complete charts will look like this

<div style="display: flex; justify-content: space-between;">
<img src="https://github.com/zukui1984/Divvy_Bike_Share_2022-23/blob/master/images/powerbi-screenshot.JPG" alt="power bi viz" width="600">
</div>

## Conclusion / Findings
1. Daily and monthly ridership trends, broken down by member vs casual riders
2. Top stations by usage, with some like Dear Lake and Lake Mille Stree being very popular
3. Hourly usage patterns across different stations
4. Overall rider stats like total rides (0.7M), members (363K), and average ride duration (9 mins)
5. Bike type preferences, with classic and electric bikes being most used
6. Geographic distribution of stations in the Chicago area
  

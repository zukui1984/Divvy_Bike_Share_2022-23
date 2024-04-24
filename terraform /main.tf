provider "google" {
  credentials =  file("./lib/gcp-project.json") 
  project     = "data-engineer-projects-2024"
  region      = "us-central1"
}

resource "google_storage_bucket" "data_bucket" {
  name     = "davvy_bikes_project"
  location = "us-central1"
}

resource "google_bigquery_dataset" "bike_data" {
  dataset_id = "divvy_bike"
}

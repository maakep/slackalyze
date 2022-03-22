provider "google" {
  project = var.project_id
  region  = var.default_region
  zone    = "europe-west1-b"
}

data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${var.name}.zip"
}

resource "google_storage_bucket" "function_zip_bucket" {
  name          = var.bucket_name
  location      = "EU"
  force_destroy = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket_object" "function_zip_bucket_object" {
  name       = "${var.name}.${data.archive_file.function_zip.output_base64sha256}.zip"
  bucket     = var.bucket_name
  source     = data.archive_file.function_zip.output_path
  depends_on = [google_storage_bucket.function_zip_bucket]
}

resource "google_cloudfunctions_function" "function" {
  name                  = var.name
  description           = var.description
  trigger_http          = true
  available_memory_mb   = var.available_memory_mb
  source_archive_bucket = var.bucket_name
  source_archive_object = google_storage_bucket_object.function_zip_bucket_object.name
  timeout               = var.timeout
  entry_point           = var.entry_point
  runtime               = var.runtime
  environment_variables = var.environment_variables
  service_account_email = var.service_account_email
  vpc_connector         = var.vpc_connector
  max_instances         = var.max_instances
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  cloud_function = google_cloudfunctions_function.function.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}
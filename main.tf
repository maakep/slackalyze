# Zip up source code
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${var.source_dir}/../${var.name}.zip"
}

# Store zipped code in the bucket
resource "google_storage_bucket_object" "function_zip_bucket_object" {
  name   = "${var.name}.${data.archive_file.function_zip.output_base64sha256}.zip"
  bucket = var.bucket_name
  source = data.archive_file.function_zip.output_path
}

# Create the cloud function
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
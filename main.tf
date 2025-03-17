resource "google_service_account" "sa" {
  account_id   = var.service_account_name
  display_name = "Service Account criada pelo Terraform"
}

resource "google_project_iam_binding" "sa_roles" {
  for_each = toset(var.service_account_roles)

  project = var.project_id
  role    = each.key

  members = [
    "serviceAccount:${google_service_account.sa.email}"
  ]
}

resource "google_service_account_key" "sa_key" {
  service_account_id = google_service_account.sa.name
  key_algorithm      = "KEY_ALG_RSA_2048"
}

resource "local_file" "my_key_file" {
  filename   = "response/my-service-account-key.json"
  content    = base64decode(google_service_account_key.sa_key.private_key)
}


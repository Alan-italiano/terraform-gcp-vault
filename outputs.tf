output "service_account_email" {
  value = google_service_account.sa.email
}

output "key_id" {
  value     = google_service_account_key.sa_key.id  #private_key
  sensitive = false
}

output "key_path" {
  value = local_file.my_key_file.filename
}

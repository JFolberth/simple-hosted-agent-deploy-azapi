output "image_uri" {
  description = "Fully qualified URI of the image built and pushed to ACR."
  value       = local.image_uri

  depends_on = [terraform_data.image]
}

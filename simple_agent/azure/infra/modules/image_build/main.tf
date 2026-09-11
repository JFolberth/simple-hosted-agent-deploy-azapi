locals {
  build_context_files = sort(tolist(fileset(var.build_context_path, "**")))
  build_context_hash = sha256(join("", [
    for filename in local.build_context_files :
    "${filename}:${filesha256("${var.build_context_path}/${filename}")}"
  ]))
  image_uri = "${var.registry_login_server}/${var.image_repository_name}:${var.image_tag}"
}

resource "terraform_data" "image" {
  input = {
    build_context_hash = local.build_context_hash
    image_uri          = local.image_uri
  }

  triggers_replace = [
    var.registry_id,
    local.image_uri,
    local.build_context_hash,
  ]

  provisioner "local-exec" {
    command     = <<-EOT
      az acr build \
        --registry "$ACR_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --subscription "$SUBSCRIPTION_ID" \
        --image "$IMAGE_NAME" \
        --platform linux/amd64 \
        --file Dockerfile \
        .
    EOT
    interpreter = ["/bin/bash", "-c"]
    working_dir = var.build_context_path

    environment = {
      ACR_NAME            = var.registry_name
      IMAGE_NAME          = "${var.image_repository_name}:${var.image_tag}"
      RESOURCE_GROUP_NAME = var.resource_group_name
      SUBSCRIPTION_ID     = var.subscription_id
    }
  }
}
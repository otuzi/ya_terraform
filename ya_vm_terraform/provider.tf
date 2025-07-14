# блок авторизации
terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.137.0"
    }
  }
  required_version = ">=1.5"
}

# секреты
provider "yandex" {
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.default_zone
  service_account_key_file = file("../../keys/authorized_key.json")
}

## vars cloud
variable "cloud_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "ig_service_account_id" {
  type        = string
  description = "ID сервисного аккаунта для Instance Group"
}

variable "folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}

variable "zones" {
  default = ["ru-central1-a", "ru-central1-b", "ru-central1-c"]
}

variable "default_cidr" {
  type        = list(string)
  default     = ["10.0.1.0/24"]
  description = "https://cloud.yandex.ru/docs/vpc/operations/subnet-create"
}

variable "vpc_name" {
  type        = string
  default     = "developer"
  description = "VPC network & subnet name"
}

## vars VM compute
variable "vm_web_image" {
  type        = string
  default     = "web-nginx-demo-1752345577"
  description = "my custom image"
}

variable "vm_web_instance" {
  type        = string
  default     = "web"
  description = "my instance"
}

###ssh vars

variable "vms_ssh_root_key" {
  type        = string
  default     = "<your_ssh_ed25519_key>"
  description = "ssh-keygen -t ed25519"
}

# vars domain
variable "domain_name" {
  type        = string
  description = "Домен для публикации ALB"
  default     = "lab54.tech"
}

# vars mysql
variable "mysql_password" {
  type        = string
  description = "Пароль пользователя MySQL"
  sensitive   = true
}

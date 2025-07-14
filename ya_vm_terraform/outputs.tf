output "public_ips_VM_web_group" {
  value = [for instance in yandex_compute_instance_group.web.instances : instance.network_interface[0].nat_ip_address]
}

output "instances_names_VM_web" {
  value = [for instance in yandex_compute_instance_group.web.instances : instance.name]
}

output "alb_external_ip" {
  description = "External IP address of the Application Load Balancer"
  value       = yandex_alb_load_balancer.web_alb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}

output "web_page1_url" {
  description = "URL for page1.html"
  value       = "http://${yandex_alb_load_balancer.web_alb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address}/page1.html"
}

output "web_page2_url" {
  description = "URL for page2.html"
  value       = "http://${yandex_alb_load_balancer.web_alb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address}/page2.html"
}

output "web_page1_url_fqdn" {
  description = "URL для page1.html по доменному имени"
  value       = "http://${var.domain_name}/page1.html"
}

output "web_page2_url_fqdn" {
  description = "URL для page2.html по доменному имени"
  value       = "http://${var.domain_name}/page2.html"
}

output "mysql_host" {
  value = yandex_mdb_mysql_cluster.web_mysql.host[0].fqdn
}

output "mysql_user" {
  value = "logsuser"
}

output "mysql_pass" {
  value     = var.mysql_password
  sensitive = true
}

output "mysql_db" {
  value = "logsdb"
}

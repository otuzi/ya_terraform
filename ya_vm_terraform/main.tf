resource "yandex_vpc_network" "develop" {
  name = var.vpc_name
}
resource "yandex_vpc_subnet" "develop_a" {
  name           = "developer-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = ["10.0.1.0/24"]
}
resource "yandex_vpc_subnet" "develop_b" {
  name           = "developer-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = ["10.0.2.0/24"]
}
resource "yandex_vpc_subnet" "develop_d" {
  name           = "developer-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = ["10.0.3.0/24"]
}

data "yandex_compute_image" "ubuntu" {
  name = var.vm_web_image
}

resource "yandex_compute_instance_group" "web" {
  name               = "web-vm-group"
  folder_id          = var.folder_id
  service_account_id = var.ig_service_account_id

  instance_template {
    platform_id = "standard-v3"

    resources {
      memory        = 1
      cores         = 2
      core_fraction = 20
    }

    boot_disk {
      initialize_params {
        image_id = data.yandex_compute_image.ubuntu.id
      }
    }

    network_interface {
      network_id = yandex_vpc_network.develop.id
      subnet_ids = [
        yandex_vpc_subnet.develop_a.id,
        yandex_vpc_subnet.develop_b.id,
        yandex_vpc_subnet.develop_d.id
      ]
      nat = true
    }

    metadata = {
      serial-port-enable = 1
      ssh-keys           = "ubuntu:${var.vms_ssh_root_key}"
    }

    scheduling_policy {
      preemptible = true
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = var.zones
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 1
    max_creating    = 2
  }
}

# подготовка Application Load Balancer
# ------------------------------------------------------
# Создаем целевую группу ALB на основе инстансов (IP)
resource "yandex_alb_target_group" "web" {
  name = "web-target-group"

  dynamic "target" {
    for_each = yandex_compute_instance_group.web.instances
    content {
      subnet_id  = target.value.network_interface[0].subnet_id
      ip_address = target.value.network_interface[0].ip_address
    }
  }
}

# Группы бэкендов ALB ссылаются на целевую группу
resource "yandex_alb_backend_group" "group1" {
  name = "backend-group1"
  http_backend {
    name             = "backend1"
    port             = 80
    target_group_ids = [yandex_alb_target_group.web.id]
  }
}

resource "yandex_alb_backend_group" "group2" {
  name = "backend-group2"
  http_backend {
    name             = "backend2"
    port             = 80
    target_group_ids = [yandex_alb_target_group.web.id]
  }
}

# Создаем HTTP роутер
resource "yandex_alb_http_router" "web_router" {
  name = "web-router"
}

# Создаем виртуальный хост с маршрутами
resource "yandex_alb_virtual_host" "default_host" {
  name           = "default"
  http_router_id = yandex_alb_http_router.web_router.id

  route {
    name = "route1"
    http_route {
      http_match {
        path {
          exact = "/page1.html"
        }
      }
      http_route_action {
        backend_group_id = yandex_alb_backend_group.group1.id
        timeout          = "60s"
      }
    }
  }

  route {
    name = "route2"
    http_route {
      http_match {
        path {
          exact = "/page2.html"
        }
      }
      http_route_action {
        backend_group_id = yandex_alb_backend_group.group2.id
        timeout          = "60s"
      }
    }
  }
}

# Создаем балансировщик ALB с внешним IP
resource "yandex_alb_load_balancer" "web_alb" {
  name       = "web-alb"
  network_id = yandex_vpc_network.develop.id

  allocation_policy {
    location {
      zone_id   = var.default_zone
      subnet_id = yandex_vpc_subnet.develop_a.id
    }
  }

  listener {
    name = "http-listener"
    endpoint {
      address {
        external_ipv4_address {}
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.web_router.id
      }
    }
  }
}

# подготовка DNS
# ------------------------------------------------------

resource "yandex_dns_zone" "web_dns" {
  name   = "web-zone"
  zone   = "${var.domain_name}."
  public = true
}

resource "yandex_dns_recordset" "alb_record" {
  zone_id = yandex_dns_zone.web_dns.id
  name    = "${var.domain_name}."
  type    = "A"
  ttl     = 300
  data    = [yandex_alb_load_balancer.web_alb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address]
}


# Добавим Manage DB MySQL
# ------------------------------------------------------
resource "yandex_mdb_mysql_cluster" "web_mysql" {
  name        = "web-mysql"
  environment = "PRESTABLE"
  network_id  = yandex_vpc_network.develop.id
  version     = "8.0"

  host {
    zone             = var.default_zone
    subnet_id        = yandex_vpc_subnet.develop_a.id
    assign_public_ip = true
  }

  resources {
    resource_preset_id = "s2.micro"
    disk_type_id       = "network-ssd"
    disk_size          = 20
  }
}

resource "yandex_mdb_mysql_database" "logsdb" {
  cluster_id = yandex_mdb_mysql_cluster.web_mysql.id
  name       = "logsdb"
}

resource "yandex_mdb_mysql_user" "logsuser" {
  cluster_id = yandex_mdb_mysql_cluster.web_mysql.id
  name       = "logsuser"
  password   = var.mysql_password

  permission {
    database_name = yandex_mdb_mysql_database.logsdb.name
    roles         = ["ALL"]
  }
}


# Добавим Cloud Function
# ------------------------------------------------------

resource "yandex_function" "alb_logger" {
  name               = "alb-logger-func"
  description        = "Logs ALB events into MySQL"
  runtime            = "python311"
  entrypoint         = "cloud_func_log_mysql.handler"
  memory             = 128
  execution_timeout  = 30
  service_account_id = var.ig_service_account_id

  environment = {
    MYSQL_HOST = yandex_mdb_mysql_cluster.web_mysql.host[0].fqdn
    MYSQL_USER = yandex_mdb_mysql_user.logsuser.name
    MYSQL_PASS = var.mysql_password
    MYSQL_DB   = yandex_mdb_mysql_database.logsdb.name
  }

  user_hash = "alb-logger-v1"

  content {
    zip_filename = "${path.module}/alb_logger.zip"
  }
}

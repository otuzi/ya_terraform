# Пример автоматического разворачивания VM используя terraform

### для работы скрипта packer необходимо
создать файл `packer_vm/variables.json` и добавить в него значения для следующих переменных:
```json
{
  "folder_id": "",
  "zone": "",
  "token": "",
  "subnet_id": "",
  "ssh_public_key": "ssh-rsa"
}
```
Предварительно должна быть развернута сеть к которой есть доступ, так как packer развернет VM выполнит настройки и сделает образ из данной VM.

### для работы terraform необходимо:
создать файл `ya_vm_terraform/personal.auto.tfvars` и добавить в него значения для следующих переменных:
```json
cloud_id              = ""
folder_id             = ""
vms_ssh_root_key      = "ssh-rsa"
ig_service_account_id = ""
mysql_password        = ""
```

## Важно: HTTP Trigger для Cloud Function

Создание HTTP-триггера для Cloud Function (для обработки ALB Access Logs через HTTP) через Terraform **не поддерживается** или я не нашел как.

**Что нужно сделать вручную:**

1. После `terraform apply` перейдите в веб-консоль Yandex Cloud.
2. Открой раздел "Cloud Functions" → твоя функция (`alb-logger-func`)
3. После этого можешь настроить отправку ALB access logs на endpoint функции.
4. Создайте для неё HTTP-триггер:
    - В консоли — через UI: "Добавить триггер" → HTTP → публичный

      ```sh
      yc serverless trigger create http \
        --name alb-log-trigger \
        --function-id <FUNCTION_ID> \
        --service-account-id <SERVICE_ACCOUNT_ID> \
        --security-level public
      ```

4. После этого функция будет доступна по публичному URL, Endpoint Cloud Function можно использовать в ALB для access logs.

---
**Что делает этот код:**

Автоматически создает всю облачную инфраструктуру для веб-приложения с балансировкой и логированием:

Виртуальные сети, подсети (VPC/Subnets)

Instance Group из 3 VM (web-сервера, масштабируемые)

Application Load Balancer (ALB) с маршрутами на разные бекенды по разным URL

ALB Target Groups и Backend Groups (для маршрутизации трафика)

HTTP Router + Virtual Host (гибкая маршрутизация)

DNS-зона и A-запись (ваш домен сразу указывает на ALB)

Managed MySQL кластер, база и пользователь

Cloud Function для записи ALB-логов в MySQL

(НЕ ДО КОНЦА) HTTP Trigger для Cloud Function (требует ручных настроек)

Важно знать:
Стенд поднимается командами:
`terraform init`
`terraform plan`
`terraform apply`

Все основные параметры и endpoint-ы выведутся из outputs.tf — смотри вывод после разворачивания инфраструктуры.

Статическая страница доступна по адресу:
`http://lab54.tech/page1`
`http://lab54.tech/page2`


итоговая страница
![http://lab54.tech/page1](images/Screenshot%202025-07-14%20at%2019.25.58.png)

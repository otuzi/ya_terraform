#!/bin/bash

# Установка nginx
sudo apt update
sudo apt install -y nginx

sudo mkdir -p /var/www/html

# страницы
sudo tee /var/www/html/page1.html > /dev/null <<EOF
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <title>Страница 1</title>
</head>
<body style="text-align:center;">
  <h1><strong>Yandex тестовое задание</strong></h1>
  <h2 style="color:blue;">Страница 1</h2>
</body>
</html>
EOF

sudo tee /var/www/html/page2.html > /dev/null <<EOF
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <title>Страница 2</title>
</head>
<body style="text-align:center;">
  <h1><strong>Yandex тестовое задание</strong></h1>
  <h2 style="color:red;">Страница 2</h2>
</body>
</html>
EOF

sudo systemctl enable nginx
sudo systemctl restart nginx

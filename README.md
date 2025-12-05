# Minecraft Server with Docker and Nginx Proxy Protocol

Этот проект предоставляет Docker-контейнер для запуска Minecraft сервера с обратным прокси Nginx, поддерживающим Proxy Protocol.

## Файлы проекта

- [`Dockerfile`](Dockerfile) - конфигурация сборки Minecraft сервера
- [`start-minecraft.sh`](start-minecraft.sh) - скрипт запуска Minecraft сервера
- [`docker-compose.yml`](docker-compose.yml) - конфигурация Docker Compose
- [`nginx.conf`](nginx.conf) - основной конфиг Nginx
- [`nginx-proxy-protocol.conf`](nginx-proxy-protocol.conf) - конфиг Proxy Protocol для Nginx
- [`eula.txt`](eula.txt) - файл принятия лицензионного соглашения Mojang

## Архитектура

```
Клиент → Nginx (Proxy Protocol) → Minecraft Server
(порт 25566)        (порт 25565)
```

## Запуск

1. Клонируйте репозиторий
2. Запустите сервисы:
   ```bash
   docker-compose up -d
   ```

## Конфигурация

### Minecraft сервер

Переменные окружения в [`docker-compose.yml`](docker-compose.yml:13-18):
- `EULA=true` - принять лицензионное соглашение
- `VERSION=1.20.1` - версия Minecraft
- `MEMORY=2G` - выделенная память
- `TYPE=FORGE` - тип сервера (FORGE, SPIGOT, PAPER)
- `FORGEVERSION=47.2.0` - версия Forge
- `MCVERSION=1.20.1` - версия Minecraft для Forge

### Nginx Proxy Protocol

- Proxy Protocol слушает порт `25566`
- Проксирует подключения на Minecraft сервер (порт `25565`)
- Поддерживает Docker сеть `172.18.0.0/16`

## Доступ

- Прямой доступ к Minecraft серверу: `localhost:25565`
- Через Nginx с Proxy Protocol: `localhost:25566`

## Логирование

- Логи Minecraft сервера: `docker logs minecraft-server`
- Логи Nginx: `docker logs minecraft-proxy`

## Остановка

```bash
docker-compose down
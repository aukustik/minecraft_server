FROM eclipse-temurin:8-jre-alpine

# Установка переменных окружения
ENV EULA=true \
    VERSION=1.7.10 \
    MEMORY=2G \
    TYPE=FORGE \
    FORGEVERSION=10.13.4.1614 \
    MCVERSION=1.7.10

RUN apk update && apk add --no-cache wget file

# Создание пользователя и директорий
RUN addgroup -g 1000 minecraft && adduser -D -s /bin/sh -u 1000 -G minecraft minecraft

# Создание директории для сервера
RUN mkdir -p /data \
    && chown -R minecraft:minecraft /data \
    && chmod -R 755 /data

WORKDIR /data

# Копирование и запуск скрипта установки
COPY start-minecraft.sh /start-minecraft.sh
RUN chmod +x /start-minecraft.sh

# Открытие порта
EXPOSE 25565

# Запуск от имени root для решения проблем с правами доступа
CMD ["/start-minecraft.sh"]
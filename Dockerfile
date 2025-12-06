FROM eclipse-temurin:17-jre-jammy

# Установка переменных окружения
ENV EULA=true \
    VERSION=1.7.10 \
    MEMORY=2G \
    TYPE=FORGE \
    FORGEVERSION=10.13.4.1614 \
    MCVERSION=1.7.10

RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*

# Создание пользователя и директорий
RUN groupadd -r minecraft && useradd -r -g minecraft minecraft

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
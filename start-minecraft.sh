#!/bin/bash

# Ожидание, пока файл eula.txt не будет создан
while [ ! -f eula.txt ]; do
    echo "Ожидание accept EULA..."
    sleep 5
done

# Запуск сервера
case "$TYPE" in
    "FORGE")
        if [ ! -f forge.jar ]; then
            echo "Скачивание Forge сервера..."
            wget -q "https://maven.minecraftforge.net/net/minecraftforge/forge/${MCVERSION}-${FORGEVERSION}/forge-${MCVERSION}-${FORGEVERSION}-installer.jar" -O forge-installer.jar
            java -jar forge-installer.jar --installServer
            rm forge-installer.jar
            mv forge-${MCVERSION}-${FORGEVERSION}.jar server.jar
        fi
        java -Xms${MEMORY} -Xmx${MEMORY} -jar server.jar nogui
        ;;
    "SPIGOT")
        if [ ! -f spigot.jar ]; then
            echo "Скачивание Spigot сервера..."
            wget -q "https://cdn.getbukkit.org/spigot/spigot-${MCVERSION}.jar"
            mv spigot-${MCVERSION}.jar server.jar
        fi
        java -Xms${MEMORY} -Xmx${MEMORY} -jar server.jar nogui
        ;;
    "PAPER")
        if [ ! -f paper.jar ]; then
            echo "Скачивание Paper сервера..."
            wget -q "https://api.papermc.io/v2/projects/paper/versions/${MCVERSION}/builds/downloads/paper-${MCVERSION}.jar"
            mv paper-${MCVERSION}.jar server.jar
        fi
        java -Xms${MEMORY} -Xmx${MEMORY} -jar server.jar nogui
        ;;
    *)
        echo "Неизвестный тип сервера: $TYPE"
        exit 1
        ;;
esac
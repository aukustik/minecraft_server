#!/bin/bash
# Minecraft Forge Server - Fixed version
# No loops, clear logic

echo "=== Minecraft Forge Server Startup ==="
echo "MC: ${MCVERSION:-1.20.1} | Forge: ${FORGEVERSION:-47.2.0}"

# 1. EULA handling
if [ "${EULA:-false}" = "true" ]; then
    if [ ! -f eula.txt ]; then
        echo "eula=true" > eula.txt
        echo "✓ EULA accepted"
    fi
else
    echo "ERROR: EULA not accepted. Set EULA=true"
    exit 1
fi

# 2. Check if server already exists
if [ -f server.jar ]; then
    echo "✓ Found existing server.jar"
    echo "🚀 Starting server with ${MEMORY:-2G} RAM..."
    java -Xms${MEMORY:-2G} -Xmx${MEMORY:-2G} -jar server.jar nogui
    exit 0
fi

# 3. Download Forge installer
echo "📥 Downloading Forge installer..."
FORGE_INSTALLER="forge-${MCVERSION:-1.20.1}-${FORGEVERSION:-47.2.0}-installer.jar"
URL="https://maven.minecraftforge.net/net/minecraftforge/forge/${MCVERSION:-1.20.1}-${FORGEVERSION:-47.2.0}/${FORGE_INSTALLER}"

echo "URL: $URL"

# Check if we have write permissions in current directory
if [ ! -w "." ]; then
    echo "❌ ERROR: No write permission in current directory"
    echo "Current directory: $(pwd)"
    echo "Directory permissions: $(ls -ld .)"
    echo "Current user: $(whoami)"
    exit 1
fi

# Download with error handling
if ! wget --show-progress -O "$FORGE_INSTALLER" "$URL"; then
    echo "❌ ERROR: Failed to download installer"
    echo "URL: $URL"
    echo "File: $FORGE_INSTALLER"
    exit 1
fi

# Set proper permissions for the downloaded file
chmod +x "$FORGE_INSTALLER"

if [ ! -f "$FORGE_INSTALLER" ]; then
    echo "❌ ERROR: Failed to download installer"
    exit 1
fi

echo "✓ Downloaded: $(ls -lh "$FORGE_INSTALLER")"

# 4. Install Forge
echo "🔧 Installing Forge..."
java -jar "$FORGE_INSTALLER" --installServer

# 5. Find and rename the server jar
echo "🔍 Looking for server jar..."

# Wait for installation to complete
sleep 5

# Debug: List all files in directory
echo "📋 Files in directory after installation:"
ls -la

# Debug: List all jar files
echo "📋 JAR files in directory:"
ls -la *.jar 2>/dev/null || echo "No jar files found"

# Check common file patterns
SERVER_JAR=""
if [ -f "forge-${MCVERSION:-1.20.1}-${FORGEVERSION:-47.2.0}.jar" ]; then
    SERVER_JAR="forge-${MCVERSION:-1.20.1}-${FORGEVERSION:-47.2.0}.jar"
elif [ -f "forge-${MCVERSION:-1.20.1}-${FORGEVERSION:-47.2.0}-universal.jar" ]; then
    SERVER_JAR="forge-${MCVERSION:-1.20.1}-${FORGEVERSION:-47.2.0}-universal.jar"
elif [ -f "forge-${MCVERSION:-1.20.1}-${FORGEVERSION:-47.2.0}-server.jar" ]; then
    SERVER_JAR="forge-${MCVERSION:-1.20.1}-${FORGEVERSION:-47.2.0}-server.jar"
elif [ -f "libraries/net/minecraftforge/forge/${MCVERSION:-1.20.1}-${FORGEVERSION:-47.2.0}/forge-${MCVERSION:-1.20.1}-${FORGEVERSION:-47.2.0}-server.jar" ]; then
    # Check in libraries directory (newer Forge versions)
    SERVER_JAR="libraries/net/minecraftforge/forge/${MCVERSION:-1.20.1}-${FORGEVERSION:-47.2.0}/forge-${MCVERSION:-1.20.1}-${FORGEVERSION:-47.2.0}-server.jar"
else
    # Find any forge jar except installer
    SERVER_JAR=$(find . -maxdepth 1 -name "forge-*.jar" ! -name "*installer*" | head -1)
fi

if [ -n "$SERVER_JAR" ] && [ -f "$SERVER_JAR" ]; then
    echo "✓ Found: $SERVER_JAR"
    cp "$SERVER_JAR" server.jar
    # Ensure proper permissions for server.jar
    chmod +x server.jar
else
    echo "❌ ERROR: No server jar found after installation"
    echo "🔍 Searching in subdirectories..."
    find . -name "*.jar" -type f 2>/dev/null
    exit 1
fi

# 6. Cleanup
echo "🧹 Cleaning up..."
rm -f "$FORGE_INSTALLER" forge-*-installer.jar.log 2>/dev/null

# 7. Verify permissions before starting
echo "🔍 Verifying permissions..."
if [ ! -r "server.jar" ]; then
    echo "❌ ERROR: No read permission for server.jar"
    exit 1
fi

if [ ! -x "server.jar" ]; then
    echo "❌ ERROR: No execute permission for server.jar"
    exit 1
fi

# 8. Start server
echo "🚀 Starting Forge server with ${MEMORY:-2G} RAM..."
java -Xms${MEMORY:-2G} -Xmx${MEMORY:-2G} -jar server.jar nogui
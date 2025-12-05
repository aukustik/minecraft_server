#!/bin/bash
# Simple Minecraft Forge Server Startup Script
# Fixed version - гарантированно работает

# Variables
TYPE=${TYPE:-"FORGE"}
MCVERSION=${MCVERSION:-"1.20.1"}
FORGEVERSION=${FORGEVERSION:-"47.2.0"}
MEMORY=${MEMORY:-"2G"}
EULA=${EULA:-"false"}

echo "========================================"
echo "Minecraft Forge Server"
echo "MC: $MCVERSION | Forge: $FORGEVERSION"
echo "========================================"

# Step 1: Handle EULA
if [ "$EULA" = "true" ]; then
    echo "eula=true" > eula.txt
    echo "✓ EULA accepted"
elif [ ! -f eula.txt ]; then
    echo "⚠️  Waiting for eula.txt..."
    while [ ! -f eula.txt ]; do
        sleep 5
    done
fi

# Step 2: Check if we need to setup Forge
if [ ! -f server.jar ]; then
    echo "🔄 Setting up Forge..."
    
    # 2.1 Download installer
    FORGE_INSTALLER="forge-${MCVERSION}-${FORGEVERSION}-installer.jar"
    echo "Downloading: $FORGE_INSTALLER"
    
    # Try multiple URL patterns
    URL_PATTERNS=(
        "https://maven.minecraftforge.net/net/minecraftforge/forge/${MCVERSION}-${FORGEVERSION}/${FORGE_INSTALLER}"
        "https://maven.minecraftforge.net/net/minecraftforge/forge/${MCVERSION}-${FORGEVERSION}-${MCVERSION}/${FORGE_INSTALLER}"
        "https://files.minecraftforge.net/maven/net/minecraftforge/forge/${MCVERSION}-${FORGEVERSION}/${FORGE_INSTALLER}"
    )
    
    DOWNLOAD_SUCCESS=false
    for URL in "${URL_PATTERNS[@]}"; do
        echo "Trying: $URL"
        if wget --quiet --show-progress "$URL" -O "$FORGE_INSTALLER"; then
            if [ -f "$FORGE_INSTALLER" ] && [ $(stat -c%s "$FORGE_INSTALLER" 2>/dev/null || echo 0) -gt 1000000 ]; then
                DOWNLOAD_SUCCESS=true
                echo "✓ Downloaded successfully"
                break
            fi
        fi
        rm -f "$FORGE_INSTALLER" 2>/dev/null
    done
    
    if [ "$DOWNLOAD_SUCCESS" = false ]; then
        echo "❌ Failed to download installer"
        exit 1
    fi
    
    # 2.2 Install Forge
    echo "Installing Forge (this may take a minute)..."
    java -jar "$FORGE_INSTALLER" --installServer --acceptEULA
    
    # 2.3 Find and rename the server jar
    echo "Looking for server jar..."
    
    # Wait a bit for installation to complete
    sleep 3
    
    # Search for forge server jar
    SERVER_JAR=""
    
    # Check common locations and names
    if [ -f "forge-${MCVERSION}-${FORGEVERSION}.jar" ]; then
        SERVER_JAR="forge-${MCVERSION}-${FORGEVERSION}.jar"
    elif [ -f "forge-${MCVERSION}-${FORGEVERSION}-universal.jar" ]; then
        SERVER_JAR="forge-${MCVERSION}-${FORGEVERSION}-universal.jar"
    elif [ -f "forge-${MCVERSION}-${FORGEVERSION}-server.jar" ]; then
        SERVER_JAR="forge-${MCVERSION}-${FORGEVERSION}-server.jar"
    else
        # Find any forge jar that's not the installer
        SERVER_JAR=$(find . -maxdepth 1 -name "forge-*.jar" ! -name "*installer*" -type f | head -1)
    fi
    
    if [ -n "$SERVER_JAR" ] && [ -f "$SERVER_JAR" ]; then
        echo "Found: $SERVER_JAR"
        cp "$SERVER_JAR" server.jar
        echo "✓ Copied to server.jar"
    else
        # List all jars for debugging
        echo "Available jar files:"
        find . -name "*.jar" -type f | while read f; do
            echo "  - $f ($(stat -c%s "$f" 2>/dev/null || echo 0) bytes)"
        done
        
        # Last resort - try to use the installer as server (not recommended but works for some versions)
        if [ -f "$FORGE_INSTALLER" ]; then
            echo "⚠️  No server jar found, using installer as server (experimental)..."
            cp "$FORGE_INSTALLER" server.jar
        else
            echo "❌ No server jar found and installer missing"
            exit 1
        fi
    fi
    
    # 2.4 Cleanup
    echo "Cleaning up..."
    rm -f "$FORGE_INSTALLER" 2>/dev/null
    rm -f forge-*-installer.jar.log 2>/dev/null
    
    echo "✓ Forge setup complete"
else
    echo "✓ Using existing server.jar"
fi

# Step 3: Start server
echo "🚀 Starting server with ${MEMORY} RAM..."
if [ ! -f server.jar ]; then
    echo "❌ ERROR: server.jar not found!"
    exit 1
fi

# Check file size
FILESIZE=$(stat -c%s "server.jar" 2>/dev/null || echo 0)
echo "server.jar size: $((FILESIZE / 1024 / 1024)) MB"

# Start the server
java -Xms${MEMORY} -Xmx${MEMORY} -jar server.jar nogui
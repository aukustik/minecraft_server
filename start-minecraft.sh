#!/bin/bash
# Minecraft Forge Server - Fixed version
# No loops, clear logic

echo "=== Minecraft Forge Server Startup ==="
# Set default Forge version based on Minecraft version if not specified
if [ -z "$FORGEVERSION" ]; then
    case "${MCVERSION:-1.20.1}" in
        "1.7.10")
            FORGEVERSION="10.13.4.1614"
            ;;
        *)
            FORGEVERSION="47.2.0"
            ;;
    esac
fi
echo "MC: ${MCVERSION:-1.20.1} | Forge: ${FORGEVERSION}"

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
    
    # Check if server.jar is valid
    if ! java -jar server.jar --help > /dev/null 2>&1; then
        echo "❌ ERROR: server.jar is corrupted or invalid"
        echo "🗑️ Removing corrupted server.jar"
        rm -f server.jar
    else
        echo "� Starting server with ${MEMORY:-2G} RAM..."
        java -Xms${MEMORY:-2G} -Xmx${MEMORY:-2G} -jar server.jar nogui
        exit 0
    fi
fi

# 3. Download Forge installer
echo "📥 Downloading Forge installer..."
FORGE_INSTALLER="forge-${MCVERSION:-1.20.1}-${FORGEVERSION}-installer.jar"

# Use different URL structure for older Minecraft versions (1.7.10 and earlier)
if [ "${MCVERSION:-1.20.1}" = "1.7.10" ]; then
    # For Minecraft 1.7.10, use the old Maven repository structure
    URL="https://files.minecraftforge.net/maven/net/minecraftforge/forge/${MCVERSION:-1.20.1}-${FORGEVERSION}/${FORGE_INSTALLER}"
else
    # For newer versions, use the current Maven repository structure
    URL="https://maven.minecraftforge.net/net/minecraftforge/forge/${MCVERSION:-1.20.1}-${FORGEVERSION}/${FORGE_INSTALLER}"
fi

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
    echo "❌ Failed to download from primary URL"
    
    # For Minecraft 1.7.10, try alternative URLs
    if [ "${MCVERSION:-1.20.1}" = "1.7.10" ]; then
        echo "🔄 Trying alternative URL for Minecraft 1.7.10..."
        ALT_URL="https://maven.minecraftforge.net/net/minecraftforge/forge/${MCVERSION:-1.20.1}-${FORGEVERSION}/forge-${MCVERSION:-1.20.1}-${FORGEVERSION}-installer.jar"
        echo "Alternative URL: $ALT_URL"
        
        if ! wget --show-progress -O "$FORGE_INSTALLER" "$ALT_URL"; then
            echo "❌ Failed to download from alternative URL"
            echo "🔄 Trying another URL for Minecraft 1.7.10..."
            # Try another URL pattern for older Forge versions
            THIRD_URL="https://files.minecraftforge.net/maven/net/minecraftforge/forge/${MCVERSION:-1.20.1}-${FORGEVERSION}-${FORGEVERSION}/forge-${MCVERSION:-1.20.1}-${FORGEVERSION}-${FORGEVERSION}-installer.jar"
            echo "Third URL: $THIRD_URL"
            
            if ! wget --show-progress -O "$FORGE_INSTALLER" "$THIRD_URL"; then
                echo "❌ Failed to download from third URL"
                echo "🔄 Trying direct download from Forge website..."
                # Try direct download from Forge website
                FOURTH_URL="https://media.forgecdn.net/files/2317/877/forge-1.7.10-10.13.4.1614-1.7.10-installer.jar"
                echo "Fourth URL: $FOURTH_URL"
                
                if ! wget --show-progress -O "$FORGE_INSTALLER" "$FOURTH_URL"; then
                    echo "❌ ERROR: Failed to download installer from all URLs"
                    echo "Primary URL: $URL"
                    echo "Alternative URL: $ALT_URL"
                    echo "Third URL: $THIRD_URL"
                    echo "Fourth URL: $FOURTH_URL"
                    echo "File: $FORGE_INSTALLER"
                    exit 1
                fi
            fi
        fi
    else
        echo "❌ ERROR: Failed to download installer"
        echo "URL: $URL"
        echo "File: $FORGE_INSTALLER"
        exit 1
    fi
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
if [ "${MCVERSION:-1.20.1}" = "1.7.10" ]; then
    # For Minecraft 1.7.10, use the old installation method
    echo "Using legacy installation method for Minecraft 1.7.10..."
    java -jar "$FORGE_INSTALLER" --installServer --nogui
else
    # For newer versions, use the current installation method
    java -jar "$FORGE_INSTALLER" --installServer
fi

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
if [ -f "forge-${MCVERSION:-1.20.1}-${FORGEVERSION}.jar" ]; then
    SERVER_JAR="forge-${MCVERSION:-1.20.1}-${FORGEVERSION}.jar"
elif [ -f "forge-${MCVERSION:-1.20.1}-${FORGEVERSION}-universal.jar" ]; then
    SERVER_JAR="forge-${MCVERSION:-1.20.1}-${FORGEVERSION}-universal.jar"
elif [ -f "forge-${MCVERSION:-1.20.1}-${FORGEVERSION}-server.jar" ]; then
    SERVER_JAR="forge-${MCVERSION:-1.20.1}-${FORGEVERSION}-server.jar"
elif [ -f "libraries/net/minecraftforge/forge/${MCVERSION:-1.20.1}-${FORGEVERSION}/forge-${MCVERSION:-1.20.1}-${FORGEVERSION}-server.jar" ]; then
    # Check in libraries directory (newer Forge versions)
    SERVER_JAR="libraries/net/minecraftforge/forge/${MCVERSION:-1.20.1}-${FORGEVERSION}/forge-${MCVERSION:-1.20.1}-${FORGEVERSION}-server.jar"
elif [ "${MCVERSION:-1.20.1}" = "1.7.10" ] && [ -f "minecraft_server.${MCVERSION:-1.20.1}.jar" ]; then
    # For Minecraft 1.7.10, check for the vanilla server jar that might be used with Forge
    SERVER_JAR="minecraft_server.${MCVERSION:-1.20.1}.jar"
else
    # Find any forge jar except installer
    SERVER_JAR=$(find . -maxdepth 1 -name "forge-*.jar" ! -name "*installer*" | head -1)
fi

if [ -n "$SERVER_JAR" ] && [ -f "$SERVER_JAR" ]; then
    echo "✓ Found: $SERVER_JAR"
    cp "$SERVER_JAR" server.jar
    # Ensure proper permissions for server.jar
    chmod +x server.jar
    
    # Verify the copied file is valid
    echo "🔍 Verifying server.jar integrity..."
    if ! file server.jar | grep -q "Java archive"; then
        echo "❌ ERROR: Copied server.jar is not a valid Java archive"
        echo "File info:"
        ls -la server.jar
        file server.jar
        exit 1
    fi
    echo "✓ server.jar appears to be valid"
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
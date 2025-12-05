#!/bin/bash

# Minecraft Server Startup Script
# Supports Forge, Spigot, and Paper servers with Docker compatibility

# Default values for environment variables (can be overridden)
TYPE=${TYPE:-"FORGE"}
MCVERSION=${MCVERSION:-"1.20.1"}
FORGEVERSION=${FORGEVERSION:-"47.2.0"}
MEMORY=${MEMORY:-"2G"}
EULA=${EULA:-"false"}

echo "Starting Minecraft Server..."
echo "Type: $TYPE"
echo "Minecraft Version: $MCVERSION"
if [ "$TYPE" = "FORGE" ]; then
    echo "Forge Version: $FORGEVERSION"
fi
echo "Memory: $MEMORY"

# Function to create eula.txt if EULA=true
create_eula_if_needed() {
    if [ "$EULA" = "true" ] && [ ! -f eula.txt ]; then
        echo "EULA=true, creating eula.txt file..."
        echo "eula=true" > eula.txt
        echo "eula.txt created successfully"
    fi
}

# Function to handle errors
handle_error() {
    echo "Error: $1"
    exit 1
}

# Create eula.txt if needed
create_eula_if_needed

# Wait for eula.txt if not present and EULA is not true
if [ ! -f eula.txt ]; then
    echo "Waiting for eula.txt to be created..."
    while [ ! -f eula.txt ]; do
        echo "Waiting for EULA acceptance..."
        sleep 5
    done
fi

# Start the server based on type
case "$TYPE" in
    "FORGE")
        if [ ! -f server.jar ]; then
            echo "Downloading Forge server..."
            FORGE_INSTALLER="forge-${MCVERSION}-${FORGEVERSION}-installer.jar"
            DOWNLOAD_URL="https://maven.minecraftforge.net/net/minecraftforge/forge/${MCVERSION}-${FORGEVERSION}/${FORGE_INSTALLER}"
            
            echo "Attempting to download: ${DOWNLOAD_URL}"
            if ! wget --progress=bar:force "${DOWNLOAD_URL}" -O "${FORGE_INSTALLER}"; then
                handle_error "Failed to download Forge installer from ${DOWNLOAD_URL}"
            fi
            
            if [ ! -f "${FORGE_INSTALLER}" ]; then
                handle_error "Forge installer not found after download"
            fi
            
            echo "Installing Forge server..."
            if ! java -jar "${FORGE_INSTALLER}" --installServer --acceptEULA; then
                handle_error "Forge installation failed"
            fi
            
            echo "Searching for installed Forge jar file..."
            
            # Enhanced search for the Forge jar file
            FOUND=false
            
            # Try different possible locations and naming patterns
            PATTERNS=(
                "forge-${MCVERSION}-${FORGEVERSION}.jar"
                "forge-${MCVERSION}-${FORGEVERSION}-universal.jar"
                "forge-${MCVERSION}-${FORGEVERSION}-server.jar"
                "forge.jar"
                "libraries/net/minecraftforge/forge/${MCVERSION}-${FORGEVERSION}/forge-${MCVERSION}-${FORGEVERSION}.jar"
                "libraries/net/minecraftforge/forge/${MCVERSION}-${FORGEVERSION}/forge-${MCVERSION}-${FORGEVERSION}-server.jar"
                "libraries/net/minecraftforge/forge/${MCVERSION}-${FORGEVERSION}/forge-${MCVERSION}-${FORGEVERSION}-universal.jar"
            )
            
            for PATTERN in "${PATTERNS[@]}"; do
                if [ -f "$PATTERN" ]; then
                    echo "Found: $PATTERN"
                    cp "$PATTERN" server.jar
                    FOUND=true
                    break
                fi
            done
            
            # If still not found, try using find command
            if [ "$FOUND" = false ]; then
                echo "Standard patterns not found, searching with find command..."
                FORGE_JAR=$(find . -name "forge-${MCVERSION}-${FORGEVERSION}*.jar" -type f | head -1)
                if [ -n "$FORGE_JAR" ]; then
                    echo "Found with find: $FORGE_JAR"
                    cp "$FORGE_JAR" server.jar
                    FOUND=true
                fi
            fi
            
            # Clean up installer
            rm -f "${FORGE_INSTALLER}"
            
            if [ "$FOUND" = false ]; then
                echo "Error: Could not find installed Forge jar file"
                echo "Directory contents:"
                find . -name "*.jar" -type f
                handle_error "Forge jar file not found after installation"
            fi
            
            echo "Forge successfully installed as server.jar"
        fi
        
        echo "Starting Forge server..."
        java -Xms${MEMORY} -Xmx${MEMORY} -jar server.jar nogui
        ;;
    "SPIGOT")
        if [ ! -f server.jar ]; then
            echo "Downloading Spigot server..."
            SPIGOT_URL="https://cdn.getbukkit.org/spigot/spigot-${MCVERSION}.jar"
            
            if ! wget -q "${SPIGOT_URL}" -O spigot-${MCVERSION}.jar; then
                handle_error "Failed to download Spigot from ${SPIGOT_URL}"
            fi
            
            if [ ! -f "spigot-${MCVERSION}.jar" ]; then
                handle_error "Spigot jar not found after download"
            fi
            
            mv "spigot-${MCVERSION}.jar" server.jar
            echo "Spigot successfully downloaded as server.jar"
        fi
        
        echo "Starting Spigot server..."
        java -Xms${MEMORY} -Xmx${MEMORY} -jar server.jar nogui
        ;;
    "PAPER")
        if [ ! -f server.jar ]; then
            echo "Downloading Paper server..."
            
            # Get the latest build information from PaperMC API
            API_URL="https://api.papermc.io/v2/projects/paper/versions/${MCVERSION}"
            echo "Fetching Paper build information from: ${API_URL}"
            
            # Get the latest build number
            BUILD_INFO=$(wget -qO- "${API_URL}")
            if [ $? -ne 0 ]; then
                handle_error "Failed to fetch Paper build information"
            fi
            
            # Extract the latest build number using JSON parsing (simplified)
            LATEST_BUILD=$(echo "${BUILD_INFO}" | grep -o '"builds":\[[^]]*' | sed 's/"builds":\[\([^,]*\).*/\1/')
            
            if [ -z "$LATEST_BUILD" ]; then
                handle_error "Could not determine latest Paper build for version ${MCVERSION}"
            fi
            
            PAPER_URL="https://api.papermc.io/v2/projects/paper/versions/${MCVERSION}/builds/${LATEST_BUILD}/downloads/paper-${MCVERSION}-${LATEST_BUILD}.jar"
            
            echo "Downloading Paper from: ${PAPER_URL}"
            if ! wget -q "${PAPER_URL}" -O paper-${MCVERSION}.jar; then
                handle_error "Failed to download Paper from ${PAPER_URL}"
            fi
            
            if [ ! -f "paper-${MCVERSION}.jar" ]; then
                handle_error "Paper jar not found after download"
            fi
            
            mv "paper-${MCVERSION}.jar" server.jar
            echo "Paper successfully downloaded as server.jar"
        fi
        
        echo "Starting Paper server..."
        java -Xms${MEMORY} -Xmx${MEMORY} -jar server.jar nogui
        ;;
    *)
        handle_error "Unknown server type: $TYPE. Supported types: FORGE, SPIGOT, PAPER"
        ;;
esac
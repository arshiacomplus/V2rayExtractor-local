#!/bin/bash
# V2L - Final Bulletproof Installer with Rename Strategy v2.3
# Created by arshiacomplus

set -e

# --- Configuration ---
CMD_NAME="v2l"
REPO="arshiacomplus/V2rayExtractor-local"
SUB_CHECKER_REPO="arshiacomplus/sub-checker"
APP_V="1.0.0"
CORE_V="1.1"

# --- Core Binary Versions ---
XRAY_REPO="GFW-knocker/Xray-core"
XRAY_TAG="v1.25.8-mahsa-r1"
HYSTERIA_REPO="apernet/hysteria"
HYSTERIA_TAG_URL_ENCODED="app%2Fv2.6.5"

# --- Paths & Colors ---
INSTALL_PATH="$HOME/.$CMD_NAME"
SUB_CHECKER_RENAMED_PATH="$INSTALL_PATH/sub_checker"
APP_VERSION_FILE="$INSTALL_PATH/.app_version"
CORE_VERSION_FILE="$INSTALL_PATH/.core_version"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# --- Main Logic for Termux ---
if [[ -n "$PREFIX" ]]; then
    LAUNCHER_PATH="$PREFIX/bin/$CMD_NAME"

    if [ -f "$LAUNCHER_PATH" ] && [ -d "$INSTALL_PATH" ] && [ -d "$SUB_CHECKER_RENAMED_PATH" ] && \
       [ -f "$APP_VERSION_FILE" ] && [ "$(cat "$APP_VERSION_FILE")" == "$APP_V" ] && \
       [ -f "$CORE_VERSION_FILE" ] && [ "$(cat "$CORE_VERSION_FILE")" == "$CORE_V" ]; then

        echo -e "${GREEN}V2L is up-to-date. Launching...${NC}"
        $CMD_NAME; exit 0
    fi

    echo -e "${BLUE}--- V2L Setup / Update Required ---${NC}"

    echo "Step 1: Installing system dependencies..."
    pkg update -y; pkg install -y python git curl unzip patchelf build-essential tur-repo python-grpcio

    echo "Step 2: Performing a clean installation..."
    rm -rf "$INSTALL_PATH"; rm -f "$LAUNCHER_PATH"

    echo "Cloning main application..."; git clone https://github.com/$REPO.git "$INSTALL_PATH"
    cd "$INSTALL_PATH"

    echo "Cloning sub-checker (full repository)..."
    git clone https://github.com/$SUB_CHECKER_REPO.git sub-checker

    echo "Renaming 'sub-checker' to 'sub_checker' for Python import..."
    mv sub-checker sub_checker

    echo "Step 3: Preparing core binaries..."
    VENDOR_DIR="$SUB_CHECKER_RENAMED_PATH/vendor"
    mkdir -p "$VENDOR_DIR"

    XRAY_ASSET="Xray-linux-arm64-v8a.zip"
    HYSTERIA_ASSET="hysteria-linux-arm64"

    echo "Downloading Xray ($XRAY_TAG)..."
    XRAY_URL="https://github.com/$XRAY_REPO/releases/download/$XRAY_TAG/$XRAY_ASSET"
    curl -# -L -o xray.zip "$XRAY_URL"
    unzip -j xray.zip "xray" -d "$VENDOR_DIR"
    rm xray.zip

    echo "Downloading Hysteria (v2.6.5)..."
    HYSTERIA_URL="https://github.com/$HYSTERIA_REPO/releases/download/$HYSTERIA_TAG_URL_ENCODED/$HYSTERIA_ASSET"
    curl -# -L -o "$VENDOR_DIR/hysteria" "$HYSTERIA_URL"

    echo "Creating symbolic links and setting permissions..."
    ln -sf "$VENDOR_DIR/xray" "$VENDOR_DIR/xray_linux"
    ln -sf "$VENDOR_DIR/hysteria" "$VENDOR_DIR/hysteria_linux"
    chmod +x "$VENDOR_DIR"/*

    echo "Binaries and symlinks are ready:"
    ls -l "$VENDOR_DIR"

    echo "Step 4: Installing Python packages..."
    echo "Attempting to install Pydantic from pre-built wheel..."

    if pip install "pydantic"; then
        echo -e "${GREEN}Pydantic installed successfully via pip.${NC}"
    else
        echo -e "${YELLOW}Warning: pip install for pydantic failed. Attempting fallback to pre-built wheel...${NC}"
        TEMP_WHL_DIR=$(mktemp -d)
        if ( set -e; \
             cd "$TEMP_WHL_DIR"; \
             curl -# -L -o pydantic.zip "$PYDANTIC_ZIP_URL"; \
             unzip pydantic.zip; \
             pip install *.whl; \
           ); then
            echo -e "${GREEN}Pydantic installed successfully from wheel.${NC}"
        else
            echo -e "${YELLOW}Fatal: Fallback installation from wheel also failed. Please check your connection or environment.${NC}"
            rm -rf "$TEMP_WHL_DIR"
            exit 1
        fi
        rm -rf "$TEMP_WHL_DIR"
    fi

    echo "Installing remaining packages from requirements.txt..."
    pip install -r requirements.txt
    if [ -f "$SUB_CHECKER_RENAMED_PATH/requirements.txt" ]; then pip install -r "$SUB_CHECKER_RENAMED_PATH/requirements.txt"; fi

    echo "$APP_V" > "$APP_VERSION_FILE"; echo "$CORE_V" > "$CORE_VERSION_FILE"

    echo "Step 5: Creating the '$CMD_NAME' command..."
    cat << EOF > "$LAUNCHER_PATH"
#!/bin/bash
INSTALL_DIR="$HOME/.$CMD_NAME"
FINAL_TXT_PATH="\$INSTALL_DIR/sub_checker/final.txt"
if [ -f "\$FINAL_TXT_PATH" ]; then rm "\$FINAL_TXT_PATH"; fi
cd "\$INSTALL_DIR"; python main.py "\$@"
EOF
    chmod +x "$LAUNCHER_PATH"

    echo -e "${GREEN}Installation complete!${NC}"; echo -e "Run with: ${YELLOW}$CMD_NAME${NC}"
    echo "Running for the first time..."; $CMD_NAME
else
    echo "Standard Linux/macOS environment detected. Installing pre-compiled binary..."
    echo "Step 1: Checking dependencies..."
    for cmd in curl unzip jq; do
      if ! command -v $cmd &> /dev/null; then
        echo -e "${YELLOW}Error: '$cmd' is not installed. Please install it first.${NC}"
        exit 1
      fi
    done
    echo "Step 2: Detecting system architecture..."
    ARCH=$(uname -m)
    OS=$(uname -s)
    ASSET_KEYWORD=""
    if [ "$OS" == "Linux" ]; then
      if [ "$ARCH" == "x86_64" ]; then ASSET_KEYWORD="linux-x64"; fi
    elif [ "$OS" == "Darwin" ]; then ASSET_KEYWORD="macos"; fi
    if [ -z "$ASSET_KEYWORD" ]; then
      echo -e "${YELLOW}Error: Unsupported OS/Architecture: $OS/$ARCH${NC}"
      exit 1
    fi
    echo "Detected: $OS/$ARCH. Looking for asset containing '$ASSET_KEYWORD'..."
    echo "Step 3: Fetching latest release from GitHub..."
    API_URL="https://api.github.com/repos/$REPO/releases/latest"
    DOWNLOAD_URL=$(curl -s $API_URL | jq -r --arg keyword "$ASSET_KEYWORD" '.assets[] | select(.name | contains($keyword)) | .browser_download_url')
    if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" == "null" ]; then
      echo -e "${YELLOW}Error: Could not find a release asset for your system.${NC}"
      exit 1
    fi
    echo "Step 4: Downloading and extracting..."
    TEMP_DIR=$(mktemp -d)
    curl -
    EXECUTABLE_NAME=$(unzip -l "$TEMP_DIR/asset.zip" | grep 'v2ray_scraper_ui' | awk '{print $4}')
    unzip -o "$TEMP_DIR/asset.zip" -d "$TEMP_DIR"
    chmod +x "$TEMP_DIR/$EXECUTABLE_NAME"
    LAUNCHER_PATH="/usr/local/bin/$CMD_NAME"
    echo "Step 5: Installing '$CMD_NAME' to /usr/local/bin..."
    if sudo mv "$TEMP_DIR/$EXECUTABLE_NAME" "$LAUNCHER_PATH"; then
      echo -e "${GREEN}Installation successful!${NC}"
      echo "You may need to open a new terminal to use the command."
      echo "Run by typing: ${YELLOW}$CMD_NAME${NC}"
    else
      echo -e "${YELLOW}Error: Installation failed. You may need root permissions (sudo).${NC}"
      exit 1
    fi
    rm -rf "$TEMP_DIR"
fi

set -e
set -e
CMD_NAME="v2l"
REPO="arshiacomplus/V2rayExtractor-local"
SUB_CHECKER_REPO="arshiacomplus/sub-checker"
SUB_CH_V="1.1"
TERMUX_INSTALL_PATH="$HOME/.$CMD_NAME"
SUB_CHECKER_PATH="$TERMUX_INSTALL_PATH/sub-checker"
VERSION_FILE="$TERMUX_INSTALL_PATH/.version"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
if [[ -n "$PREFIX" ]]; then
    LAUNCHER_PATH="$PREFIX/bin/$CMD_NAME"
    if [ -f "$LAUNCHER_PATH" ] && \
       [ -d "$TERMUX_INSTALL_PATH" ] && \
       [ -d "$SUB_CHECKER_PATH" ] && \
       [ -f "$VERSION_FILE" ] && \
       [ "$(cat "$VERSION_FILE")" == "$SUB_CH_V" ]; then
        echo -e "${GREEN}V2L is up-to-date (v$SUB_CH_V). Launching...${NC}"
        $CMD_NAME
        exit 0
    fi
    echo -e "${BLUE}--- V2L Setup / Update Required ---${NC}"
    echo "Step 1: Installing system dependencies..."
    pkg update -y
    pkg install -y python git curl unzip patchelf build-essential tur-repo python-grpcio
    echo "Step 2: Performing a clean installation..."
    rm -rf "$TERMUX_INSTALL_PATH"
    rm -f "$LAUNCHER_PATH"
    echo "Cloning repositories..."
    git clone https://github.com/$REPO.git "$TERMUX_INSTALL_PATH"
    cd "$TERMUX_INSTALL_PATH"
    git clone https://github.com/$SUB_CHECKER_REPO.git sub-checker
    echo "Step 3: Preparing binaries..."
    if [ -d "sub-checker/xray" ]; then
        mkdir -p sub-checker/vendor
        mv sub-checker/xray/xray sub-checker/vendor/xray
        if [ -f "sub-checker/hy2/hysteria" ]; then mv sub-checker/hy2/hysteria sub-checker/vendor/hysteria; fi
        chmod +x sub-checker/vendor/*
        rm -rf sub-checker/xray sub-checker/hy2
    fi
    echo "Step 4: Installing Python packages..."
    pip install -r requirements.txt
    if [ -f "sub-checker/requirements.txt" ]; then pip install -r "sub-checker/requirements.txt"; fi
    echo "$SUB_CH_V" > "$VERSION_FILE"
    echo "Step 5: Creating the '$CMD_NAME' command..."
    cat << EOF > "$LAUNCHER_PATH"
INSTALL_DIR="$HOME/.$CMD_NAME"
FINAL_TXT_PATH="\$INSTALL_DIR/sub-checker/final.txt"
if [ -f "\$FINAL_TXT_PATH" ]; then rm "\$FINAL_TXT_PATH"; fi
cd "\$INSTALL_DIR"
python main.py "\$@"
EOF
    chmod +x "$LAUNCHER_PATH"
    echo -e "${GREEN}Installation/Update complete!${NC}"
    echo "You can now run the application from anywhere by typing:"
    echo -e "${YELLOW}  $CMD_NAME${NC}"
    echo "Running for the first time..."
    $CMD_NAME
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

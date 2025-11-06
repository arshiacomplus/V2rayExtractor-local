set -e
CMD_NAME="v2l"
REPO="arshiacomplus/V2rayExtractor-local"
SUB_CHECKER_REPO="arshiacomplus/sub-checker"
XRAY_REPO="GFW-knocker/Xray-core"
XRAY_TAG="v1.25.8-mahsa-r1"
HYSTERIA_REPO="apernet/hysteria"
HYSTERIA_TAG="app/v2.6.5"
INSTALL_V="1.1"
TERMUX_INSTALL_PATH="$HOME/.$CMD_NAME"
VERSION_FILE="$TERMUX_INSTALL_PATH/.version"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
if [[ -n "$PREFIX" ]]; then
    LAUNCHER_PATH="$PREFIX/bin/$CMD_NAME"
    if [ -f "$LAUNCHER_PATH" ] && [ -f "$VERSION_FILE" ] && [ "$(cat "$VERSION_FILE")" == "$INSTALL_V" ]; then
        echo -e "${GREEN}V2L is up-to-date (v$INSTALL_V). Launching...${NC}"
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
    echo "Cloning main repository..."
    git clone https://github.com/$REPO.git "$TERMUX_INSTALL_PATH"
    cd "$TERMUX_INSTALL_PATH"
    echo "Cloning sub-checker (python files only)..."
    git clone --depth 1 --filter=blob:none --sparse https://github.com/$SUB_CHECKER_REPO.git sub-checker
    (cd sub-checker && git sparse-checkout set cl.py python_v2ray requirements.txt)
    echo "Step 3: Downloading and preparing core binaries..."
    mkdir -p sub-checker/vendor
    ARCH=$(uname -m)
    if [ "$ARCH" != "aarch64" ]; then
        echo -e "${YELLOW}Warning: Architecture is not aarch64. Attempting to download compatible binaries, but compatibility is not guaranteed.${NC}"
    fi
    XRAY_ASSET="Xray-linux-arm64-v8a.zip"
    HYSTERIA_ASSET="hysteria-linux-arm64"
    echo "Downloading Xray ($XRAY_TAG)..."
    XRAY_URL="https://github.com/$XRAY_REPO/releases/download/$XRAY_TAG/$XRAY_ASSET"
    curl -L -o xray.zip "$XRAY_URL"
    unzip -j xray.zip "xray" -d "sub-checker/vendor"
    mv "sub-checker/vendor/xray" "sub-checker/vendor/xray_linux"
    rm xray.zip
    echo "Downloading Hysteria ($HYSTERIA_TAG)..."
    HYSTERIA_URL="https://github.com/$HYSTERIA_REPO/releases/download/app%2Fv2.6.5/$HYSTERIA_ASSET"
    curl -L -o "sub-checker/vendor/hysteria_linux" "$HYSTERIA_URL"
    chmod +x sub-checker/vendor/*
    echo "Binaries are ready:"
    ls -l sub-checker/vendor
    echo "Step 4: Installing Python packages..."
    pip install -r requirements.txt
    if [ -f "sub-checker/requirements.txt" ]; then pip install -r "sub-checker/requirements.txt"; fi
    echo "$INSTALL_V" > "$VERSION_FILE"
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
    echo "Run the application by typing: ${YELLOW}$CMD_NAME${NC}"
    echo "Running for the first time..."
    $CMD_NAME
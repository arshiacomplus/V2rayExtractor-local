#!/bin/bash
# V2L - Smart Installer & Launcher Script
# Created by arshiacomplus

set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
CMD_NAME="v2l"
REPO="arshiacomplus/V2rayExtractor-local"
# For Termux, install location will be in the home directory
TERMUX_INSTALL_PATH="$HOME/.v2l"

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Main Logic ---

# Check if the command is already installed by looking for the launcher
# In Termux, the launcher is in $PREFIX/bin, in Linux it's in /usr/local/bin
LAUNCHER_PATH=""
if [[ -n "$PREFIX" ]]; then
  LAUNCHER_PATH="$PREFIX/bin/$CMD_NAME"
else
  LAUNCHER_PATH="/usr/local/bin/$CMD_NAME"
fi

if [ -f "$LAUNCHER_PATH" ]; then
    echo -e "${GREEN}V2L is already installed. Launching...${NC}"
    # Directly execute the command
    $CMD_NAME
    exit 0
fi

# If not installed, proceed with installation
echo -e "${BLUE}--- V2L First-Time Setup ---${NC}"

# --- Environment Detection ---
# Check if we are in Termux by looking for the $PREFIX variable
if [[ -n "$PREFIX" ]]; then
    # --- Termux Installation (Run from Source) ---
    echo "Termux environment detected. Installing from source..."
    
    echo "Step 1: Installing dependencies (git, python, etc.)..."

    pkg install -y python git curl unzip patchelf build-essential

    echo "Step 2: Cloning repositories..."
    # Remove old installation if it exists
    rm -rf "$TERMUX_INSTALL_PATH"
    git clone https://github.com/$REPO.git "$TERMUX_INSTALL_PATH"
    cd "$TERMUX_INSTALL_PATH"
    git clone https://github.com/arshiacomplus/sub-checker.git sub-checker

    echo "Step 3: Preparing binaries..."
    mkdir -p sub-checker/vendor
    mv sub-checker/xray/xray sub-checker/vendor/xray
    if [ -f "sub-checker/hy2/hysteria" ]; then
        mv sub-checker/hy2/hysteria sub-checker/vendor/hysteria
    fi
    chmod +x sub-checker/vendor/*
    rm -rf sub-checker/xray sub-checker/hy2

    echo "Step 4: Installing Python packages..."
    pip install -r requirements.txt
    if [ -f sub-checker/requirements.txt ]; then
        pip install -r sub-checker/requirements.txt
    fi
    
    echo "Step 5: Creating the '$CMD_NAME' command..."
    # Create the wrapper script that runs the app from the correct directory
    cat << EOF > "$LAUNCHER_PATH"
#!/bin/bash
# Wrapper script for V2L
cd "$TERMUX_INSTALL_PATH"
python main.py "\$@"
EOF

    chmod +x "$LAUNCHER_PATH"
    
    echo -e "${GREEN}Installation for Termux complete!${NC}"
    echo "You can now run the application from anywhere by typing:"
    echo -e "${YELLOW}  $CMD_NAME${NC}"
    echo "Running for the first time..."
    $CMD_NAME

else
    # --- Standard Linux/macOS Installation (Pre-compiled Binary) ---
    echo "Standard Linux/macOS environment detected. Installing pre-compiled binary..."

    echo "Step 1: Checking dependencies (curl, unzip, jq)..."
    for cmd in curl unzip jq; do
      if ! command -v $cmd &> /dev/null; then
        echo -e "${YELLOW}Error: '$cmd' is not installed. Please install it first.${NC}"
        echo "On Debian/Ubuntu, run: sudo apt-get install $cmd"
        exit 1
      fi
    done

    echo "Step 2: Detecting system architecture..."
    ARCH=$(uname -m)
    OS=$(uname -s)
    ASSET_KEYWORD=""

    if [ "$OS" == "Linux" ]; then
      if [ "$ARCH" == "x86_64" ]; then
        ASSET_KEYWORD="linux-x64"
      elif [ "$ARCH" == "aarch64" ]; then
        # This covers ARM-based Linux servers/desktops, not Termux
        ASSET_KEYWORD="linux-arm64"
      fi
    elif [ "$OS" == "Darwin" ]; then
        ASSET_KEYWORD="macos"
    fi

    if [ -z "$ASSET_KEYWORD" ]; then
      echo -e "${YELLOW}Error: Unsupported OS/Architecture: $OS/$ARCH${NC}"
      exit 1
    fi
    echo "Detected: $OS/$ARCH. Looking for asset containing '$ASSET_KEYWORD'..."

    echo "Step 3: Fetching latest release from GitHub..."
    API_URL="https://api.github.com/repos/$REPO/releases/latest"
    DOWNLOAD_URL=$(curl -s $API_URL | jq -r --arg keyword "$ASSET_KEYWORD" '.assets[] | select(.name | contains($keyword)) | .browser_download_url')

    if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" == "null" ]; then
      echo -e "${YELLOW}Error: Could not find a release asset for your system. Please check the releases page.${NC}"
      exit 1
    fi
    echo "Found download URL: $DOWNLOAD_URL"

    echo "Step 4: Downloading and extracting..."
    TEMP_DIR=$(mktemp -d)
    curl -# -L -o "$TEMP_DIR/asset.zip" "$DOWNLOAD_URL"
    EXECUTABLE_NAME=$(unzip -l "$TEMP_DIR/asset.zip" | grep 'v2ray_scraper_ui' | awk '{print $4}')
    unzip -o "$TEMP_DIR/asset.zip" -d "$TEMP_DIR"
    chmod +x "$TEMP_DIR/$EXECUTABLE_NAME"

    echo "Step 5: Installing '$CMD_NAME' to /usr/local/bin..."
    if sudo mv "$TEMP_DIR/$EXECUTABLE_NAME" "$LAUNCHER_PATH"; then
      echo -e "${GREEN}Installation successful!${NC}"
      echo "You may need to open a new terminal to use the command."
      echo "Run the application by simply typing:"
      echo -e "${YELLOW}  $CMD_NAME${NC}"
    else
      echo -e "${YELLOW}Error: Installation failed. You may need to run this script with sudo, or check permissions for /usr/local/bin.${NC}"
      exit 1
    fi

    rm -rf "$TEMP_DIR"
fi

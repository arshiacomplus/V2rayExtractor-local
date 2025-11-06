#!/bin/bash
# V2L - Bulletproof Installer, Updater & Launcher Script
# Created by arshiacomplus

set -e

# --- Configuration ---
CMD_NAME="v2l"
REPO="arshiacomplus/V2rayExtractor-local"
SUB_CHECKER_REPO="arshiacomplus/sub-checker"
# --- !! نسخه مورد انتظار !! ---
SUB_CH_V="1.3" # نسخه را بالا بردم تا آپدیت را تست کنیم

# --- Paths & Colors ---
TERMUX_INSTALL_PATH="$HOME/.$CMD_NAME"
SUB_CHECKER_PATH="$TERMUX_INSTALL_PATH/sub-checker"
VERSION_FILE="$TERMUX_INSTALL_PATH/.version"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Main Logic ---

# --- Environment Detection: Only run this complex logic for Termux ---
if [[ -n "$PREFIX" ]]; then
    LAUNCHER_PATH="$PREFIX/bin/$CMD_NAME"
    
    # --- The Ultimate "Is Installed Correctly?" Check ---
    # چک می‌کنیم که آیا همه چیز سر جای خودش است و نسخه هم درست است یا نه
    if [ -f "$LAUNCHER_PATH" ] && \
       [ -d "$TERMUX_INSTALL_PATH" ] && \
       [ -d "$SUB_CHECKER_PATH" ] && \
       [ -f "$VERSION_FILE" ] && \
       [ "$(cat "$VERSION_FILE")" == "$SUB_CH_V" ]; then
        
        echo -e "${GREEN}V2L is up-to-date (v$SUB_CH_V). Launching...${NC}"
        $CMD_NAME
        exit 0
    fi
    
    # --- اگر هر کدام از شرایط بالا برقرار نبود، یعنی نصب ناقص، خراب یا قدیمی است ---
    echo -e "${BLUE}--- V2L Setup / Update Required ---${NC}"
    
    echo "Step 1: Installing system dependencies..."
    pkg update -y
    pkg install -y python git curl unzip patchelf build-essential tur-repo python-grpcio

    echo "Step 2: Performing a clean installation..."
    # حذف کامل نصب قبلی برای جلوگیری از هرگونه تداخل
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
    
    # ذخیره نسخه جدید
    echo "$SUB_CH_V" > "$VERSION_FILE"
    
    echo "Step 5: Creating the '$CMD_NAME' command..."
    cat << EOF > "$LAUNCHER_PATH"
#!/bin/bash
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

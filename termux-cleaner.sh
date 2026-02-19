#!/bin/bash

# Script Pembersihan Cache dan Sampah Termux - Realtime Version
# Untuk Android Termux

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Fungsi animasi loading
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Fungsi untuk menampilkan ukuran dengan warna
show_size() {
    du -sh "$1" 2>/dev/null | awk '{print $1}'
}

# Fungsi untuk menghitung ukuran dalam bytes
get_size_bytes() {
    du -sb "$1" 2>/dev/null | awk '{print $1}'
}

# Fungsi untuk format bytes ke human readable
format_bytes() {
    local bytes=$1
    if [ $bytes -gt 1073741824 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1073741824}") GB"
    elif [ $bytes -gt 1048576 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1048576}") MB"
    elif [ $bytes -gt 1024 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1024}") KB"
    else
        echo "$bytes B"
    fi
}

# Header
clear
echo -e "${CYAN}${BOLD}"
echo "╔════════════════════════════════════════╗"
echo "║   TERMUX CLEANER - REALTIME MODE      ║"
echo "║         Version 2.0                    ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Scan awal
echo -e "${YELLOW}⏳ Memindai sistem...${NC}"
INITIAL_SIZE_BYTES=$(get_size_bytes $HOME)
INITIAL_SIZE=$(format_bytes $INITIAL_SIZE_BYTES)
echo -e "${GREEN}✓${NC} Ukuran awal: ${BOLD}$INITIAL_SIZE${NC}"
echo ""
sleep 1

TOTAL_CLEANED=0

# ============================================
# 1. APT Cache
# ============================================
echo -e "${BLUE}${BOLD}[1/7] Membersihkan APT Cache...${NC}"
if [ -d "$PREFIX/var/cache/apt/archives" ]; then
    BEFORE=$(get_size_bytes "$PREFIX/var/cache/apt/archives" 2>/dev/null || echo 0)
    echo -e "   ${CYAN}→${NC} Cache sebelum: $(format_bytes $BEFORE)"
    
    apt clean > /dev/null 2>&1 &
    spinner $!
    apt autoclean > /dev/null 2>&1 &
    spinner $!
    apt autoremove -y > /dev/null 2>&1 &
    spinner $!
    
    AFTER=$(get_size_bytes "$PREFIX/var/cache/apt/archives" 2>/dev/null || echo 0)
    CLEANED=$((BEFORE - AFTER))
    TOTAL_CLEANED=$((TOTAL_CLEANED + CLEANED))
    echo -e "   ${GREEN}✓${NC} Cache sesudah: $(format_bytes $AFTER)"
    echo -e "   ${MAGENTA}★${NC} Dibersihkan: ${GREEN}$(format_bytes $CLEANED)${NC}"
else
    echo -e "   ${YELLOW}⊘${NC} Direktori tidak ditemukan"
fi
echo ""
sleep 0.5

# ============================================
# 2. Python pip Cache
# ============================================
echo -e "${BLUE}${BOLD}[2/7] Membersihkan Python pip Cache...${NC}"
if command -v pip &> /dev/null; then
    if [ -d "$HOME/.cache/pip" ]; then
        BEFORE=$(get_size_bytes "$HOME/.cache/pip" 2>/dev/null || echo 0)
        echo -e "   ${CYAN}→${NC} Cache sebelum: $(format_bytes $BEFORE)"
        
        pip cache purge > /dev/null 2>&1 &
        spinner $!
        
        AFTER=$(get_size_bytes "$HOME/.cache/pip" 2>/dev/null || echo 0)
        CLEANED=$((BEFORE - AFTER))
        TOTAL_CLEANED=$((TOTAL_CLEANED + CLEANED))
        echo -e "   ${GREEN}✓${NC} Cache sesudah: $(format_bytes $AFTER)"
        echo -e "   ${MAGENTA}★${NC} Dibersihkan: ${GREEN}$(format_bytes $CLEANED)${NC}"
    else
        echo -e "   ${YELLOW}⊘${NC} Tidak ada cache pip"
    fi
else
    echo -e "   ${YELLOW}⊘${NC} pip tidak terinstall"
fi
echo ""
sleep 0.5

# ============================================
# 3. Node.js npm Cache
# ============================================
echo -e "${BLUE}${BOLD}[3/7] Membersihkan Node.js npm Cache...${NC}"
if command -v npm &> /dev/null; then
    if [ -d "$HOME/.npm" ]; then
        BEFORE=$(get_size_bytes "$HOME/.npm" 2>/dev/null || echo 0)
        echo -e "   ${CYAN}→${NC} Cache sebelum: $(format_bytes $BEFORE)"
        
        npm cache clean --force > /dev/null 2>&1 &
        spinner $!
        
        AFTER=$(get_size_bytes "$HOME/.npm" 2>/dev/null || echo 0)
        CLEANED=$((BEFORE - AFTER))
        TOTAL_CLEANED=$((TOTAL_CLEANED + CLEANED))
        echo -e "   ${GREEN}✓${NC} Cache sesudah: $(format_bytes $AFTER)"
        echo -e "   ${MAGENTA}★${NC} Dibersihkan: ${GREEN}$(format_bytes $CLEANED)${NC}"
    else
        echo -e "   ${YELLOW}⊘${NC} Tidak ada cache npm"
    fi
else
    echo -e "   ${YELLOW}⊘${NC} npm tidak terinstall"
fi
echo ""
sleep 0.5

# ============================================
# 4. File Temporary
# ============================================
echo -e "${BLUE}${BOLD}[4/7] Membersihkan File Temporary...${NC}"
TEMP_SIZE=0

if [ -d "$TMPDIR" ]; then
    BEFORE=$(get_size_bytes "$TMPDIR" 2>/dev/null || echo 0)
    TEMP_SIZE=$((TEMP_SIZE + BEFORE))
fi
if [ -d "/tmp" ]; then
    BEFORE_TMP=$(get_size_bytes "/tmp" 2>/dev/null || echo 0)
    TEMP_SIZE=$((TEMP_SIZE + BEFORE_TMP))
fi
if [ -d "$HOME/.cache" ]; then
    BEFORE_CACHE=$(get_size_bytes "$HOME/.cache" 2>/dev/null || echo 0)
    TEMP_SIZE=$((TEMP_SIZE + BEFORE_CACHE))
fi

echo -e "   ${CYAN}→${NC} File temp sebelum: $(format_bytes $TEMP_SIZE)"

rm -rf $TMPDIR/* 2>/dev/null &
spinner $!
rm -rf /tmp/* 2>/dev/null &
spinner $!
rm -rf $HOME/.cache/* 2>/dev/null &
spinner $!

TOTAL_CLEANED=$((TOTAL_CLEANED + TEMP_SIZE))
echo -e "   ${GREEN}✓${NC} File temporary dibersihkan"
echo -e "   ${MAGENTA}★${NC} Dibersihkan: ${GREEN}$(format_bytes $TEMP_SIZE)${NC}"
echo ""
sleep 0.5

# ============================================
# 5. Log Files
# ============================================
echo -e "${BLUE}${BOLD}[5/7] Membersihkan Log Files...${NC}"
LOG_SIZE=0

if [ -d "$PREFIX/var/log" ]; then
    BEFORE=$(get_size_bytes "$PREFIX/var/log" 2>/dev/null || echo 0)
    LOG_SIZE=$((LOG_SIZE + BEFORE))
fi
if [ -d "$HOME/.local/share/jupyter/runtime" ]; then
    BEFORE_JUPYTER=$(get_size_bytes "$HOME/.local/share/jupyter/runtime" 2>/dev/null || echo 0)
    LOG_SIZE=$((LOG_SIZE + BEFORE_JUPYTER))
fi

echo -e "   ${CYAN}→${NC} Log sebelum: $(format_bytes $LOG_SIZE)"

rm -rf $PREFIX/var/log/* 2>/dev/null &
spinner $!
rm -rf $HOME/.local/share/jupyter/runtime/* 2>/dev/null &
spinner $!

TOTAL_CLEANED=$((TOTAL_CLEANED + LOG_SIZE))
echo -e "   ${GREEN}✓${NC} Log files dibersihkan"
echo -e "   ${MAGENTA}★${NC} Dibersihkan: ${GREEN}$(format_bytes $LOG_SIZE)${NC}"
echo ""
sleep 0.5

# ============================================
# 6. Bash History (Optional)
# ============================================
echo -e "${BLUE}${BOLD}[6/7] Bash History...${NC}"
if [ -f "$HOME/.bash_history" ]; then
    HISTORY_SIZE=$(get_size_bytes "$HOME/.bash_history" 2>/dev/null || echo 0)
    echo -e "   ${CYAN}→${NC} Ukuran history: $(format_bytes $HISTORY_SIZE)"
    echo -e -n "   ${YELLOW}?${NC} Hapus bash history? (y/n): "
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        > ~/.bash_history
        history -c 2>/dev/null
        TOTAL_CLEANED=$((TOTAL_CLEANED + HISTORY_SIZE))
        echo -e "   ${GREEN}✓${NC} Bash history dibersihkan"
        echo -e "   ${MAGENTA}★${NC} Dibersihkan: ${GREEN}$(format_bytes $HISTORY_SIZE)${NC}"
    else
        echo -e "   ${YELLOW}⊘${NC} Bash history dipertahankan"
    fi
else
    echo -e "   ${YELLOW}⊘${NC} Tidak ada bash history"
fi
echo ""
sleep 0.5

# ============================================
# 7. File Sampah Lainnya
# ============================================
echo -e "${BLUE}${BOLD}[7/7] Membersihkan File Sampah...${NC}"
echo -e "   ${CYAN}→${NC} Mencari file .pyc, .pyo, __pycache__..."

# Hitung dulu sebelum dihapus
JUNK_COUNT=0
JUNK_COUNT=$((JUNK_COUNT + $(find $HOME -type f -name "*.pyc" 2>/dev/null | wc -l)))
JUNK_COUNT=$((JUNK_COUNT + $(find $HOME -type f -name "*.pyo" 2>/dev/null | wc -l)))
JUNK_COUNT=$((JUNK_COUNT + $(find $HOME -type d -name "__pycache__" 2>/dev/null | wc -l)))

find $HOME -type f -name "*.pyc" -delete 2>/dev/null &
spinner $!
find $HOME -type f -name "*.pyo" -delete 2>/dev/null &
spinner $!
find $HOME -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null &
spinner $!
find $HOME -type f -name ".DS_Store" -delete 2>/dev/null &
spinner $!
find $HOME -type f -name "Thumbs.db" -delete 2>/dev/null &
spinner $!

echo -e "   ${GREEN}✓${NC} File sampah dibersihkan"
echo -e "   ${MAGENTA}★${NC} Total file: ${GREEN}$JUNK_COUNT${NC} file"
echo ""
sleep 0.5

# ============================================
# Summary
# ============================================
FINAL_SIZE_BYTES=$(get_size_bytes $HOME)
FINAL_SIZE=$(format_bytes $FINAL_SIZE_BYTES)
SAVED=$((INITIAL_SIZE_BYTES - FINAL_SIZE_BYTES))

echo -e "${CYAN}${BOLD}"
echo "╔════════════════════════════════════════╗"
echo "║         PEMBERSIHAN SELESAI!          ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${BOLD}📊 STATISTIK:${NC}"
echo -e "   ${CYAN}├─${NC} Ukuran awal    : ${YELLOW}$INITIAL_SIZE${NC}"
echo -e "   ${CYAN}├─${NC} Ukuran akhir   : ${YELLOW}$FINAL_SIZE${NC}"
echo -e "   ${CYAN}└─${NC} Total hemat    : ${GREEN}${BOLD}$(format_bytes $SAVED)${NC}"
echo ""
echo -e "${BOLD}💡 Tips:${NC}"
echo -e "   • Jalankan script ini setiap minggu"
echo -e "   • Gunakan: ${CYAN}alias clean='~/clean_termux_realtime.sh'${NC}"
echo ""
echo -e "${GREEN}✨ Termux Anda sekarang lebih bersih dan cepat!${NC}"
echo ""


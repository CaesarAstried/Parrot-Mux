#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${BLUE}╔═════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${GREEN}        PARROT-MUX ADVANCED INSTALLER        ${BLUE}║${NC}"
echo -e "${BLUE}╚═════════════════════════════════════════════╝${NC}"

check_storage_permission() {
    echo -e "${CYAN}[*] Memeriksa izin penyimpanan...${NC}"
    
    if [ -d ~/storage ] && [ -d ~/storage/shared ]; then
        echo -e "${GREEN}[✓] Izin penyimpanan sudah diberikan${NC}"
        return 0
    else
        echo -e "${YELLOW}[!] Izin penyimpanan belum diberikan${NC}"
        read -p "Setup akses penyimpanan sekarang? (y/n): " setup_storage
        
        if [[ "$setup_storage" =~ ^[Yy]$ ]]; then
            echo -e "${CYAN}[*] Menjalankan setup penyimpanan...${NC}"
            termux-setup-storage
            
            sleep 2
            
            if [ -d ~/storage ] && [ -d ~/storage/shared ]; then
                echo -e "${GREEN}[✓] Izin penyimpanan berhasil diberikan${NC}"
                return 0
            else
                echo -e "${RED}[✗] Gagal mendapatkan izin penyimpanan${NC}"
                echo -e "${YELLOW}[!] Anda masih bisa melanjutkan, tapi beberapa fitur mungkin tidak berfungsi${NC}"
                read -p "Lanjutkan instalasi tanpa akses penyimpanan? (y/n): " continue_install
                
                if [[ "$continue_install" =~ ^[Yy]$ ]]; then
                    return 1
                else
                    echo -e "${RED}[✗] Instalasi dibatalkan${NC}"
                    exit 1
                fi
            fi
        else
            echo -e "${YELLOW}[!] Melanjutkan tanpa akses penyimpanan${NC}"
            return 1
        fi
    fi
}

detect_system() {
    echo -e "${CYAN}[*] Mendeteksi spesifikasi perangkat...${NC}"
    
    ARCH=$(uname -m)
    case $ARCH in
        aarch64) SYS_ARCH="ARM64 (aarch64)" ; PARROT_ARCH="arm64" ;;
        armv7l|armv8l) SYS_ARCH="ARM 32-bit (armv7l)" ; PARROT_ARCH="armhf" ;;
        x86_64) SYS_ARCH="x86_64 (amd64)" ; PARROT_ARCH="amd64" ;;
        i*86) SYS_ARCH="x86 32-bit (i386)" ; PARROT_ARCH="i386" ;;
        *) SYS_ARCH="Tidak dikenal ($ARCH)" ; PARROT_ARCH="unknown" ;;
    esac
    
    if [ -f /proc/cpuinfo ]; then
        CPU_MODEL=$(grep "model name\|Processor\|Model" /proc/cpuinfo | head -1 | cut -d ':' -f 2 | sed 's/^[ \t]*//')
        CPU_CORES=$(grep -c "processor" /proc/cpuinfo)
        
        if [ -z "$CPU_MODEL" ]; then
            CPU_MODEL=$(getprop ro.product.board)
            if [ -z "$CPU_MODEL" ]; then
                CPU_MODEL=$(getprop ro.hardware)
                if [ -z "$CPU_MODEL" ]; then
                    CPU_MODEL="Unknown CPU"
                fi
            fi
        fi
    else
        CPU_MODEL="Tidak dapat mendeteksi"
        CPU_CORES="?"
    fi
    
    MEM_TOTAL=$(free -m | grep Mem | awk '{print $2}')
    if [ -z "$MEM_TOTAL" ]; then
        MEM_INFO="Tidak dapat mendeteksi"
    else
        if [ $MEM_TOTAL -ge 1024 ]; then
            GB=$(echo "scale=1; $MEM_TOTAL/1024" | bc)
            MEM_INFO="$GB GB"
        else
            MEM_INFO="$MEM_TOTAL MB"
        fi
    fi
    
    GPU_INFO=$(getprop ro.hardware.vulkan 2>/dev/null || getprop ro.board.platform 2>/dev/null)
    if [ -z "$GPU_INFO" ]; then
        GPU_INFO="Tidak dapat mendeteksi"
    fi
    
    ANDROID_VER=$(getprop ro.build.version.release 2>/dev/null)
    if [ -z "$ANDROID_VER" ]; then
        ANDROID_VER="Tidak dapat mendeteksi"
    fi
    
    STORAGE_AVAIL=$(df -h $HOME | grep -v Filesystem | awk '{print $4}')
    
    echo -e "${YELLOW}═════════════════════════════════════════════${NC}"
    echo -e "${CYAN}▸ Arsitektur:${NC} $SYS_ARCH"
    echo -e "${CYAN}▸ CPU:${NC} $CPU_MODEL (${CPU_CORES} core)"
    echo -e "${CYAN}▸ RAM:${NC} $MEM_INFO"
    echo -e "${CYAN}▸ GPU:${NC} $GPU_INFO"
    echo -e "${CYAN}▸ Android:${NC} $ANDROID_VER"
    echo -e "${CYAN}▸ Ruang tersedia:${NC} $STORAGE_AVAIL"
    echo -e "${YELLOW}═════════════════════════════════════════════${NC}"
    
    if [[ "$PARROT_ARCH" == "unknown" ]]; then
        echo -e "${RED}[✗] Arsitektur tidak didukung: $ARCH${NC}"
        echo -e "${RED}[✗] Instalasi tidak dapat dilanjutkan${NC}"
        exit 1
    fi
    
    if [ $MEM_TOTAL -lt 2048 ]; then
        echo -e "${RED}[!] PERINGATAN: RAM terbatas (${MEM_INFO})${NC}"
        echo -e "${RED}[!] Parrot OS mungkin berjalan lambat${NC}"
        read -p "Tetap lanjutkan? (y/n): " continue_install
        if [[ ! "$continue_install" =~ ^[Yy]$ ]]; then
            echo -e "${RED}[✗] Instalasi dibatalkan${NC}"
            exit 1
        fi
    fi
    
    echo -e "${GREEN}[✓] Perangkat kompatibel dengan Parrot OS ${PARROT_ARCH}${NC}"
}

select_environment() {
    echo -e "${CYAN}[*] Pilih lingkungan desktop:${NC}"
    echo -e "${YELLOW}1) XFCE4 ${GREEN}(Rekomendasi - ringan namun lengkap)${NC}"
    echo -e "${YELLOW}2) MATE ${GREEN}(Fitur lengkap, membutuhkan RAM > 2GB)${NC}"
    echo -e "${YELLOW}3) LXDE ${GREEN}(Sangat ringan, untuk RAM terbatas)${NC}"
    echo -e "${YELLOW}4) KDE Plasma ${GREEN}(Paling lengkap, untuk RAM > 3GB)${NC}"
    echo -e "${YELLOW}5) i3wm ${GREEN}(Sangat minimalis, untuk pengguna advanced)${NC}"
    
    read -p "Pilih lingkungan desktop [1-5]: " de_choice
    
    case $de_choice in
        1) DE="xfce" ; DE_PACKAGES="xfce4 xfce4-terminal xfce4-goodies" ;;
        2) DE="mate" ; DE_PACKAGES="mate-desktop-environment-core mate-terminal" ;;
        3) DE="lxde" ; DE_PACKAGES="lxde-core lxterminal" ;;
        4) DE="kde" ; DE_PACKAGES="kde-plasma-desktop konsole" ;;
        5) DE="i3" ; DE_PACKAGES="i3 i3status i3lock dmenu rxvt-unicode" ;;
        *) DE="xfce" ; DE_PACKAGES="xfce4 xfce4-terminal xfce4-goodies"
           echo -e "${YELLOW}[!] Pilihan tidak valid, menggunakan XFCE4 sebagai default${NC}" ;;
    esac
}

select_browsers() {
    echo -e "${CYAN}[*] Pilih browser yang ingin diinstal:${NC}"
    echo -e "${YELLOW}1) Firefox${NC}"
    echo -e "${YELLOW}2) Chromium${NC}"
    echo -e "${YELLOW}3) Firefox dan Chromium${NC}"
    echo -e "${YELLOW}4) Tidak instal browser${NC}"
    
    read -p "Pilih browser [1-4]: " browser_choice
    
    case $browser_choice in
        1) BROWSERS="firefox-esr" ;;
        2) BROWSERS="chromium" ;;
        3) BROWSERS="firefox-esr chromium" ;;
        4) BROWSERS="" ;;
        *) BROWSERS="firefox-esr"
           echo -e "${YELLOW}[!] Pilihan tidak valid, menggunakan Firefox sebagai default${NC}" ;;
    esac
}

select_editors() {
    echo -e "${CYAN}[*] Pilih editor teks yang ingin diinstal:${NC}"
    echo -e "${YELLOW}1) Nano ${GREEN}(Sederhana dan mudah digunakan)${NC}"
    echo -e "${YELLOW}2) Vim ${GREEN}(Powerful dengan kurva pembelajaran curam)${NC}"
    echo -e "${YELLOW}3) Nano dan Vim${NC}"
    echo -e "${YELLOW}4) Nano, Vim, dan Emacs ${GREEN}(Lengkap)${NC}"
    
    read -p "Pilih editor [1-4]: " editor_choice
    
    case $editor_choice in
        1) EDITORS="nano" ;;
        2) EDITORS="vim" ;;
        3) EDITORS="nano vim" ;;
        4) EDITORS="nano vim emacs" ;;
        *) EDITORS="nano"
           echo -e "${YELLOW}[!] Pilihan tidak valid, menggunakan nano sebagai default${NC}" ;;
    esac
}

select_tools() {
    echo -e "${CYAN}[*] Pilih tools tambahan:${NC}"
    echo -e "${YELLOW}1) Basic Tools ${GREEN}(git, curl, wget, zip, htop)${NC}"
    echo -e "${YELLOW}2) Dev Tools ${GREEN}(Basic + python, gcc, make, nodejs)${NC}"
    echo -e "${YELLOW}3) Hacking Tools ${GREEN}(Dev + nmap, metasploit, aircrack-ng, dll)${NC}"
    echo -e "${YELLOW}4) Minimal ${GREEN}(Hanya paket wajib)${NC}"
    
    read -p "Pilih tools [1-4]: " tools_choice
    
    case $tools_choice in
        1) TOOLS="git curl wget zip unzip htop neofetch" ;;
        2) TOOLS="git curl wget zip unzip htop neofetch python3 python3-pip gcc make nodejs npm" ;;
        3) TOOLS="git curl wget zip unzip htop neofetch python3 python3-pip gcc make nodejs npm nmap metasploit-framework aircrack-ng hydra john wireshark" ;;
        4) TOOLS="" ;;
        *) TOOLS="git curl wget zip unzip htop neofetch"
           echo -e "${YELLOW}[!] Pilihan tidak valid, menggunakan Basic Tools sebagai default${NC}" ;;
    esac
}

install_parrot() {
    echo -e "${CYAN}[*] Menginstal dependensi di Termux...${NC}"
    pkg update -y
    pkg install -y proot-distro wget tar pulseaudio xorg-xhost tsu tigervnc x11-repo pv

    echo -e "${CYAN}[*] Membuat direktori instalasi...${NC}"
    mkdir -p $HOME/parrot-fs
    cd $HOME

    mkdir -p $HOME/scripts
    
    echo -e "${CYAN}[*] Mendownload Parrot OS ${PARROT_ARCH} rootfs terbaru...${NC}"
    ROOTFS_URL="https://download.parrot.sh/parrot/iso/5.3/Parrot-rootfs-5.3_${PARROT_ARCH}.tar.xz"
    wget -q --show-progress "$ROOTFS_URL" -O parrot-rootfs.tar.xz || {
        echo -e "${YELLOW}[!] Gagal mengunduh rootfs terbaru, mencoba mirror alternatif...${NC}"
        MIRROR_URL="https://raw.githubusercontent.com/CaesarAstried/Parrot-Mux/main/Parrot-rootfs-${PARROT_ARCH}.tar.xz"
        wget -q --show-progress "$MIRROR_URL" -O parrot-rootfs.tar.xz || {
            echo -e "${YELLOW}[!] Mencoba mirror kedua...${NC}"
            MIRROR2_URL="https://raw.githubusercontent.com/EXALAB/AnLinux-Resources/master/Rootfs/Parrot/${PARROT_ARCH}/parrot-rootfs-${PARROT_ARCH}.tar.xz"
            wget -q --show-progress "$MIRROR2_URL" -O parrot-rootfs.tar.xz || {
                echo -e "${RED}[✗] Gagal mengunduh rootfs! Instalasi dihentikan.${NC}"
                exit 1
            }
        }
    }

    echo -e "${CYAN}[*] Mengekstrak rootfs (Ini mungkin membutuhkan waktu)...${NC}"
    mkdir -p "$HOME/extraction_temp"
    echo -e "${CYAN}[*] Menggunakan metode ekstraksi khusus untuk mengatasi masalah hardlink...${NC}"
    
    pv parrot-rootfs.tar.xz | tar -xJf - -C "$HOME/extraction_temp" --hard-dereference || {
        echo -e "${YELLOW}[!] Mencoba metode ekstraksi alternatif...${NC}"
        tar -xf parrot-rootfs.tar.xz -C "$HOME/extraction_temp" --hard-dereference || {
            echo -e "${YELLOW}[!] Mencoba metode ekstraksi tanpa opsi hard-dereference...${NC}"
            pv parrot-rootfs.tar.xz | unxz | tar -xf - -C "$HOME/extraction_temp" || {
                echo -e "${RED}[✗] Semua metode ekstraksi gagal, mencoba ekstraksi manual...${NC}"
                echo -e "${CYAN}[*] Ini mungkin memakan waktu lebih lama...${NC}"
                mkdir -p "$HOME/extraction_temp/tmp"
                pv parrot-rootfs.tar.xz | unxz > "$HOME/extraction_temp/tmp/parrot.tar"
                cd "$HOME/extraction_temp"
                tar -xf tmp/parrot.tar
                rm -rf tmp/parrot.tar
                cd "$HOME"
            }
        }
    }
    
    echo -e "${CYAN}[*] Menyalin file ke lokasi akhir...${NC}"
    cp -r "$HOME/extraction_temp"/* "$HOME/parrot-fs/"
    rm -rf "$HOME/extraction_temp"
    rm -f parrot-rootfs.tar.xz
    
    echo -e "${GREEN}[✓] Ekstraksi selesai${NC}"
}

create_launcher() {
    echo -e "${CYAN}[*] Membuat skrip launcher...${NC}"
    cat > $HOME/scripts/parrot.sh << 'EOL'
#!/bin/bash
cd $(dirname $0)/..
unset LD_PRELOAD
command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r $HOME/parrot-fs"
command+=" -b /dev"
command+=" -b /proc"
command+=" -b /sys"
command+=" -b $HOME/parrot-fs/root:/dev/shm"
command+=" -b /data/data/com.termux"
command+=" -b $HOME/storage:/storage"
command+=" -b /:/host-rootfs"
command+=" -b /dev/null:/proc/sys/kernel/cap_last_cap"
command+=" -w /root"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
command+=" TERM=$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/bash --login"
com="$@"
if [ -z "$1" ];then
    exec $command
else
    $command -c "$com"
fi
EOL

    chmod +x $HOME/scripts/parrot.sh
    
    ln -sf $HOME/scripts/parrot.sh $HOME/parrot
    chmod +x $HOME/parrot
}

setup_vnc() {
    echo -e "${CYAN}[*] Menyiapkan konfigurasi VNC...${NC}"
    mkdir -p $HOME/.vnc

    if [ $MEM_TOTAL -lt 2048 ]; then
        DISPLAY_GEOMETRY="1024x600"
    elif [ $MEM_TOTAL -lt 3072 ]; then
        DISPLAY_GEOMETRY="1280x720"
    else
        DISPLAY_GEOMETRY="1920x1080"
    fi

    cat > $HOME/scripts/start-vnc.sh << EOL
#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "\${BLUE}╔═════════════════════════════════════════════╗\${NC}"
echo -e "\${BLUE}║\${GREEN}            PARROT-MUX VNC STARTER           \${BLUE}║\${NC}"
echo -e "\${BLUE}╚═════════════════════════════════════════════╝\${NC}"

pkill Xtigervnc 2>/dev/null
vncserver -kill :1 2>/dev/null

if [ ! -f \$HOME/.vnc/passwd ]; then
    echo -e "\${YELLOW}[!] VNC password belum diatur\${NC}"
    read -sp "Masukkan password VNC: " vnc_pass
    echo
    mkdir -p \$HOME/.vnc
    echo "\$vnc_pass" | vncpasswd -f > \$HOME/.vnc/passwd
    chmod 600 \$HOME/.vnc/passwd
fi

echo -e "\${CYAN}[*] Memulai VNC server (${DISPLAY_GEOMETRY})...\${NC}"
vncserver -localhost no -geometry ${DISPLAY_GEOMETRY} -depth 24 :1

IP=\$(ip addr show | grep -w inet | grep -v 127.0.0.1 | awk '{print \$2}' | cut -d "/" -f 1 | head -n 1)
if [ -z "\$IP" ]; then
    IP="localhost"
fi

echo -e "\${GREEN}[✓] VNC server aktif!\${NC}"
echo -e "\${YELLOW}═════════════════════════════════════════════\${NC}"
echo -e "\${YELLOW}Gunakan aplikasi VNC Viewer dan hubungkan ke:\${NC}"
echo -e "\${GREEN}• Di perangkat ini: localhost:5901\${NC}"
echo -e "\${GREEN}• Dari perangkat lain: \$IP:5901\${NC}"
echo -e "\${YELLOW}═════════════════════════════════════════════\${NC}"

echo -e "\${CYAN}[*] Menjalankan Parrot OS...\${NC}"
\$HOME/parrot "/root/start-desktop.sh"
EOL

    chmod +x $HOME/scripts/start-vnc.sh
    ln -sf $HOME/scripts/start-vnc.sh $HOME/parrot-gui
    chmod +x $HOME/parrot-gui

    cat > $HOME/scripts/stop-vnc.sh << 'EOL'
#!/bin/bash
echo -e "\033[0;32m[*] Mematikan VNC server...\033[0m"
vncserver -kill :1 2>/dev/null
pkill Xtigervnc 2>/dev/null
echo -e "\033[0;32m[✓] VNC server dimatikan.\033[0m"
EOL

    chmod +x $HOME/scripts/stop-vnc.sh
    ln -sf $HOME/scripts/stop-vnc.sh $HOME/stopvnc
    chmod +x $HOME/stopvnc
}

setup_parrot_config() {
    echo -e "${CYAN}[*] Menyiapkan konfigurasi Parrot OS...${NC}"
    
    cat > $HOME/parrot-fs/root/setup-env.sh << EOL
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

echo "[*] Mengkonfigurasi sumber paket..."
cat > /etc/apt/sources.list << 'END'
deb https://deb.parrot.sh/parrot lts main contrib non-free
deb https://deb.parrot.sh/parrot lts-updates main contrib non-free
deb https://deb.parrot.sh/parrot lts-backports main contrib non-free
deb https://deb.parrot.sh/parrot lts-security main contrib non-free
END

echo "[*] Memperbarui sistem..."
apt update 
apt upgrade -y

echo "[*] Menginstal lingkungan desktop ${DE}..."
apt install -y ${DE_PACKAGES} dbus-x11 tigervnc-standalone-server

echo "[*] Menginstal browser..."
if [ ! -z "${BROWSERS}" ]; then
    apt install -y ${BROWSERS}
fi

echo "[*] Menginstal editor teks..."
apt install -y ${EDITORS}

echo "[*] Menginstal tools tambahan..."
if [ ! -z "${TOOLS}" ]; then
    apt install -y ${TOOLS}
fi

echo "[*] Menyiapkan lingkungan VNC..."
mkdir -p ~/.vnc
cat > ~/.vnc/xstartup << 'END'
#!/bin/bash
xrdb \$HOME/.Xresources
export PULSE_SERVER=127.0.0.1

case "${DE}" in
    xfce)
        startxfce4 &
        ;;
    mate)
        mate-session &
        ;;
    lxde)
        startlxde &
        ;;
    kde)
        startkde &
        ;;
    i3)
        i3 &
        ;;
    *)
        startxfce4 &
        ;;
esac
END

chmod +x ~/.vnc/xstartup

echo "[*] Menyiapkan .bashrc dengan konfigurasi tambahan..."
cat > ~/.bashrc << 'END'
export PULSE_SERVER=127.0.0.1
alias ls='ls --color=auto'
alias ll='ls -la'
alias update='apt update && apt upgrade -y'
alias clean='apt autoremove -y && apt clean'
END

echo "[*] Menerapkan tweak performa..."
echo "vm.swappiness=10" > /etc/sysctl.d/99-swappiness.conf
echo 'APT::Cache-Start 251658240;' > /etc/apt/apt.conf.d/00cache
echo 'Acquire::http::Pipeline-Depth "10";' > /etc/apt/apt.conf.d/99pipeline

echo "[*] Membersihkan sistem..."
apt autoremove -y
apt clean

echo "[+] Setup selesai! Sistem Parrot OS siap digunakan."
EOL

    chmod +x $HOME/parrot-fs/root/setup-env.sh

    cat > $HOME/parrot-fs/root/start-desktop.sh << EOL
#!/bin/bash
export DISPLAY=:1
export PULSE_SERVER=127.0.0.1

case "${DE}" in
    xfce)
        startxfce4 &
        ;;
    mate)
        mate-session &
        ;;
    lxde)
        startlxde &
        ;;
    kde)
        startplasma-x11 &
        ;;
    i3)
        i3 &
        ;;
    *)
        startxfce4 &
        ;;
esac

sleep infinity
EOL

    chmod +x $HOME/parrot-fs/root/start-desktop.sh
}

setup_permanent_commands() {
    echo -e "${CYAN}[*] Menyiapkan perintah permanen...${NC}"
    
    mkdir -p $HOME/bin
    
    echo -e "${CYAN}[*] Menambahkan direktori bin ke PATH...${NC}"
    if ! grep -q 'export PATH="$HOME/bin:$PATH"' $HOME/.bashrc; then
        echo 'export PATH="$HOME/bin:$PATH"' >> $HOME/.bashrc
    fi
    
    ln -sf $HOME/scripts/parrot.sh $HOME/bin/parrot
    ln -sf $HOME/scripts/start-vnc.sh $HOME/bin/parrot-gui
    ln -sf $HOME/scripts/stop-vnc.sh $HOME/bin/stopvnc
    
    chmod +x $HOME/bin/parrot
    chmod +x $HOME/bin/parrot-gui
    chmod +x $HOME/bin/stopvnc
    
    echo -e "${GREEN}[✓] Perintah permanen telah disiapkan${NC}"
}

display_banner() {
    clear
    echo -e "${GREEN}╔═════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           PARROT-MUX INSTALLER              ║${NC}"
    echo -e "${GREEN}║                                             ║${NC}"
    echo -e "${GREEN}║  github.com/CaesarAstried/Parrot-Mux        ║${NC}"
    echo -e "${GREEN}╚═════════════════════════════════════════════╝${NC}"
}

show_completion() {
    echo -e "${GREEN}╔═════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           INSTALASI SELESAI!                ║${NC}"
    echo -e "${GREEN}╚═════════════════════════════════════════════╝${NC}"
    echo -e "${CYAN}Perintah yang tersedia secara permanen:${NC}"
    echo -e "${YELLOW}• parrot${NC}      - Masuk ke shell Parrot OS"
    echo -e "${YELLOW}• parrot-gui${NC}  - Memulai GUI Parrot OS dengan VNC"
    echo -e "${YELLOW}• stopvnc${NC}     - Mematikan server VNC"
    echo
    echo -e "${GREEN}Informasi sistem terdeteksi:${NC}"
    echo -e "${CYAN}▸ CPU:${NC} $CPU_MODEL (${CPU_CORES} core)"
    echo -e "${CYAN}▸ RAM:${NC} $MEM_INFO"
    echo -e "${CYAN}▸ Desktop Environment:${NC} ${DE}"
    echo -e "${CYAN}▸ Resolusi VNC:${NC} ${DISPLAY_GEOMETRY}"
    echo
    echo -e "${GREEN}Perintah di atas sudah ditambahkan secara permanen dan dapat dijalankan kapan saja${NC}"
    echo -e "${GREEN}Perintah akan tetap tersedia setelah restart Termux${NC}"
    echo
    echo -e "${PURPLE}Selamat menggunakan Parrot OS!${NC}"
}

main() {
    display_banner
    check_storage_permission
    detect_system
    select_environment
    select_browsers
    select_editors
    select_tools
    install_parrot
    create_launcher
    setup_vnc
    setup_parrot_config
    setup_permanent_commands
    
    echo -e "${CYAN}[*] Menjalankan setup Parrot OS...${NC}"
    echo -e "${YELLOW}[!] Instalasi paket mungkin memakan waktu yang lama${NC}"
    $HOME/parrot "bash /root/setup-env.sh"
    
    echo -e "${CYAN}[*] Memuat konfigurasi baru...${NC}"
    source $HOME/.bashrc
    
    show_completion
}

main

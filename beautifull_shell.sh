#!/bin/bash

# =============================================================================
# TERMINAL DEV SETUP - Installation complète Kitty + Oh My Posh (LINUX)
# =============================================================================

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/setup.log"
KITTY_CONFIG_DIR="$HOME/.config/kitty"
OMP_THEMES_DIR="$HOME/.cache/oh-my-posh/themes"

# =============================================================================
# FONCTIONS D'AFFICHAGE
# =============================================================================

print_header() {
    clear
    echo ""
    echo -e "${PURPLE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}                    ${CYAN}🦊${NC} ${WHITE}${BOLD}TERMINAL DEV SETUP${NC}                    ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                  ${DIM}Installation automatisée${NC}                  ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}[ÉTAPE]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCÈS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERREUR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[ATTENTION]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# =============================================================================
# VÉRIFICATIONS
# =============================================================================

check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        print_error "Ne pas exécuter ce script en tant que root"
        exit 1
    fi
}

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        print_info "Distribution détectée : $PRETTY_NAME"
    else
        print_error "Impossible de détecter la distribution Linux"
        exit 1
    fi
}

check_dependencies() {
    print_step "Vérification des dépendances..."
    
    local deps=("curl" "wget" "unzip" "git" "jq")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        print_warning "Installation des dépendances manquantes : ${missing[*]}"
        
        case $DISTRO in
            ubuntu|debian)
                sudo apt update && sudo apt install -y curl wget unzip git jq fontconfig
                ;;
            fedora)
                sudo dnf install -y curl wget unzip git jq fontconfig
                ;;
            arch)
                sudo pacman -S --noconfirm curl wget unzip git jq fontconfig
                ;;
            *)
                print_error "Distribution non supportée"
                exit 1
                ;;
        esac
    fi
    
    print_success "Dépendances OK"
}

# =============================================================================
# INSTALLATIONS
# =============================================================================

install_fonts() {
    print_step "Installation des polices Nerd Fonts..."
    
    local font_dir="$HOME/.local/share/fonts"
    mkdir -p "$font_dir"
    
    local temp_dir=$(mktemp -d)
    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    
    if wget -q --show-progress "$font_url" -O "$temp_dir/JetBrainsMono.zip"; then
        unzip -q "$temp_dir/JetBrainsMono.zip" -d "$temp_dir/JetBrainsMono"
        find "$temp_dir/JetBrainsMono" -name "JetBrainsMonoNerdFont-*.ttf" -exec cp {} "$font_dir/" \;
        fc-cache -fv "$font_dir" >/dev/null 2>&1
        rm -rf "$temp_dir"
        print_success "Polices installées"
    else
        print_error "Échec téléchargement polices"
        return 1
    fi
}

install_oh_my_posh() {
    print_step "Installation d'Oh My Posh..."
    
    if command -v oh-my-posh &> /dev/null; then
        print_warning "Oh My Posh déjà installé"
        return 0
    fi
    
    if curl -s https://ohmyposh.dev/install.sh | bash -s; then
        export PATH="$HOME/.local/bin:$PATH"
        print_success "Oh My Posh installé"
    else
        print_error "Échec installation Oh My Posh"
        return 1
    fi
}

download_themes() {
    print_step "Téléchargement des thèmes Oh My Posh..."
    
    mkdir -p "$OMP_THEMES_DIR"
    
    local themes_url="https://github.com/JanDeDobbeleer/oh-my-posh/archive/refs/heads/main.zip"
    local temp_dir=$(mktemp -d)
    
    if wget -q --show-progress "$themes_url" -O "$temp_dir/themes.zip"; then
        unzip -q "$temp_dir/themes.zip" -d "$temp_dir"
        if [ -d "$temp_dir/oh-my-posh-main/themes" ]; then
            cp "$temp_dir/oh-my-posh-main/themes"/*.omp.json "$OMP_THEMES_DIR/" 2>/dev/null
            print_success "Thèmes téléchargés"
        fi
        rm -rf "$temp_dir"
    else
        print_warning "Échec téléchargement thèmes"
    fi
}

install_kitty() {
    print_step "Installation de Kitty Terminal..."
    
    if command -v kitty &> /dev/null; then
        print_warning "Kitty déjà installé"
        return 0
    fi
    
    case $DISTRO in
        ubuntu|debian)
            sudo apt install -y kitty
            ;;
        fedora)
            sudo dnf install -y kitty
            ;;
        arch)
            sudo pacman -S --noconfirm kitty
            ;;
        *)
            curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
            sudo ln -sf "$HOME/.local/kitty.app/bin/kitty" /usr/local/bin/kitty
            ;;
    esac
    
    print_success "Kitty installé"
}

# =============================================================================
# CONFIGURATIONS
# =============================================================================

configure_kitty() {
    print_step "Configuration de Kitty..."
    
    mkdir -p "$KITTY_CONFIG_DIR"
    
    cat > "$KITTY_CONFIG_DIR/kitty.conf" << 'EOF'
# THEME KITTY - Catppuccin Mocha
font_family      JetBrainsMonoNerdFont-Regular
bold_font        JetBrainsMonoNerdFont-Bold
italic_font      JetBrainsMonoNerdFont-Italic
bold_italic_font JetBrainsMonoNerdFont-BoldItalic
font_size        11.0

background_opacity         0.95
confirm_os_window_close    0

# Couleurs Catppuccin Mocha
foreground           #cdd6f4
background           #1e1e2e
selection_foreground #1e1e2e
selection_background #f5e0dc

# Couleurs normales
color0  #45475a
color1  #f38ba8
color2  #a6e3a1
color3  #f9e2af
color4  #89b4fa
color5  #f5c2e7
color6  #94e2d5
color7  #bac2de

# Couleurs brillantes
color8  #585b70
color9  #f38ba8
color10 #a6e3a1
color11 #f9e2af
color12 #89b4fa
color13 #f5c2e7
color14 #94e2d5
color15 #a6adc8

# Curseur
cursor                     #f5e0dc
cursor_text_color          #1e1e2e
cursor_shape               block

# Raccourcis
map ctrl+c copy_and_clear_or_interrupt
map ctrl+v paste_from_clipboard
map ctrl+shift+c copy_to_clipboard
map ctrl+shift+v paste_from_clipboard

# Fenêtre
initial_window_width 100c
initial_window_height 30c
window_padding_width 10 10 10 10
initial_window_x 100
initial_window_y 100
remember_window_size no

shell_integration enabled
EOF

    # Script startup
    cat > "$KITTY_CONFIG_DIR/startup.sh" << 'EOF'
#!/bin/bash

clear
printf "\033[2J\033[H"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
ORANGE='\033[0;33m'
PINK='\033[1;35m'
GRAY='\033[0;90m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# Bannière
get_padding() {
    local term_width=$(tput cols)
    local content_width=35
    echo $(( (term_width - content_width) / 2 ))
}

padding=$(get_padding)
spaces=$(printf "%*s" $padding "")
USERNAME=$(whoami | tr '[:lower:]' '[:upper:]')

echo ""
echo -e "${spaces}${ORANGE}🦊${NC} ${WHITE}${BOLD}TERMINAL DEV ${USERNAME}${NC} ${ORANGE}🦊${NC}"
echo -e "${spaces}${DIM}${GRAY}Intelligent • Rapide • Fiable${NC}"
echo ""

# Infos système
USER_INFO="${USER}@$(hostname)"
echo -e "  ${CYAN}👤${NC} ${WHITE}Utilisateur   ${GRAY}→${NC}  ${YELLOW}${USER_INFO}${NC}"
echo -e "  ${CYAN}🚀${NC} ${WHITE}Ready to code   ${GRAY}→${NC}  Tapez '${YELLOW}aide${NC}' pour plus de commandes"

# Git info
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current)
    CHANGES=$(git status --porcelain | wc -l)
    echo -e "  ${PINK}🔗${NC} ${WHITE}Git Branch    ${GRAY}→${NC}  ${YELLOW}${BRANCH}${NC} ${GRAY}(${CHANGES} modifications)${NC}"
fi

echo ""

# Citations
QUOTES=(
    "Résoudre d'abord le problème. Puis, écrire le code."
    "Le code est de la poésie écrite en logique."
    "Un code propre semble avoir été écrit par quelqu'un qui s'en soucie."
    "La programmation, c'est découvrir ce qu'on peut faire."
)

RANDOM_QUOTE=${QUOTES[$RANDOM % ${#QUOTES[@]}]}
echo -e "  ${DIM}${GRAY}💭 ${RANDOM_QUOTE}${NC}"
echo ""

# Oh My Posh
if command -v oh-my-posh &> /dev/null; then
    if [ -f "$HOME/.cache/oh-my-posh/themes/aliens.omp.json" ]; then
        eval "$(oh-my-posh init bash --config '$HOME/.cache/oh-my-posh/themes/aliens.omp.json')"
    else
        eval "$(oh-my-posh init bash)"
    fi
fi
EOF

    chmod +x "$KITTY_CONFIG_DIR/startup.sh"
    print_success "Configuration Kitty créée"
}

configure_bashrc() {
    print_step "Configuration du .bashrc..."
    
    if [ -f "$HOME/.bashrc" ]; then
        cp "$HOME/.bashrc" "$HOME/.bashrc.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    cat >> "$HOME/.bashrc" << 'EOF'

# =============================================================================
# CONFIG PERSO - TERMINAL DEV SETUP
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
ORANGE='\033[0;33m'
PINK='\033[1;35m'
GRAY='\033[0;90m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# Démarrage custom
if [[ $- == *i* ]] && [[ -z "$STARTUP_DONE" ]]; then
    export STARTUP_DONE=1
    ~/.config/kitty/startup.sh
fi

# Fonction d'aide
aide() {
    echo ""
    echo -e "${WHITE}${BOLD}🦊 AIDE - COMMANDES DISPONIBLES${NC}"
    echo -e "${GRAY}▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔${NC}"
    echo -e "  ${GREEN}Navigation :${NC} proj, web, util, home"
    echo -e "  ${PURPLE}Git :${NC} gs (status), ga (add), gc (commit), gp (push)"
    echo -e "  ${BLUE}Système :${NC} ll, ports, myip, cpu"
    echo ""
}

# Aliases
alias ll='ls -alF --color=auto'
alias ports='sudo netstat -tuln'
alias myip='curl -s https://httpbin.org/ip | jq -r .origin'
alias cpu='top -bn1 | grep "Cpu(s)" | awk "{print \$2}" | awk -F"%" "{print \$1}"'
alias home='cd ~'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias proj='cd ~/Documents/Projets'
alias web='cd ~/Documents/Projets'
alias util='cd ~/Documents/Utilitaires'

# Oh My Posh
if command -v oh-my-posh &> /dev/null; then
    if [ -f "$HOME/.cache/oh-my-posh/themes/aliens.omp.json" ]; then
        eval "$(oh-my-posh init bash --config '$HOME/.cache/oh-my-posh/themes/aliens.omp.json')"
    else
        eval "$(oh-my-posh init bash)"
    fi
fi

EOF

    print_success "Configuration .bashrc mise à jour"
}

set_default_terminal() {
    print_step "Configuration terminal par défaut..."
    
    if command -v update-alternatives >/dev/null 2>&1; then
        KITTY_PATH=$(which kitty 2>/dev/null || echo "/usr/bin/kitty")
        if [ -x "$KITTY_PATH" ]; then
            sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$KITTY_PATH" 100
            sudo update-alternatives --set x-terminal-emulator "$KITTY_PATH"
            print_success "Kitty défini comme terminal par défaut"
        fi
    fi
}

# =============================================================================
# FONCTION PRINCIPALE
# =============================================================================

main() {
    print_header
    log "Début installation"
    
    check_sudo
    detect_distro
    check_dependencies
    
    echo ""
    install_fonts
    echo ""
    install_oh_my_posh
    echo ""
    download_themes
    echo ""
    install_kitty
    echo ""
    configure_kitty
    echo ""
    configure_bashrc
    echo ""
    set_default_terminal
    echo ""
    
    print_header
    print_success "Installation terminée !"
    echo ""
    print_info "PROCHAINES ÉTAPES :"
    echo -e "  ${CYAN}1.${NC} Redémarrez votre session"
    echo -e "  ${CYAN}2.${NC} Ou lancez : ${BOLD}source ~/.bashrc${NC}"
    echo -e "  ${CYAN}3.${NC} Lancez Kitty : ${BOLD}kitty${NC}"
    echo ""
    
    log "Installation terminée"
}

# Point d'entrée
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
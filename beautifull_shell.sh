
download_themes() {
    print_step "Téléchargement des thèmes Oh My Posh..."
    
    # Créer le dossier themes
    mkdir -p "$OMP_THEMES_DIR"
    
    # Télécharger les thèmes depuis le repo officiel
    local themes_url="https://github.com/JanDeDobbeleer/oh-my-posh/archive/refs/heads/main.zip"
    local temp_dir=$(mktemp -d)
    
    print_info "Téléchargement des thèmes officiels..."
    if wget -q --show-progress "$themes_url" -O "$temp_dir/themes.zip"; then
        unzip -q "$temp_dir/themes.zip" -d "$temp_dir"
        
        # Copier uniquement les fichiers de thèmes
        if [ -d "$temp_dir/oh-my-posh-main/themes" ]; then
            cp "$temp_dir/oh-my-posh-main/themes"/*.omp.json "$OMP_THEMES_DIR/" 2>/dev/null
            
            # Vérifier qu'au moins quelques thèmes ont été copiés
            local theme_count=$(ls "$OMP_THEMES_DIR"/*.omp.json 2>/dev/null | wc -l)
            if [ "$theme_count" -gt 0 ]; then
                print_success "Thèmes téléchargés ($theme_count thèmes) dans $OMP_THEMES_DIR"
            else
                print_warning "Aucun thème trouvé, création d'un thème par défaut"
                create_default_theme
            fi
        else
            print_warning "Structure de thèmes non trouvée, création d'un thème par défaut"
            create_default_theme
        fi
        
        rm -rf "$temp_dir"
    else
        print_warning "Échec du téléchargement des thèmes, création d'un thème par défaut"
        create_default_theme
    fi
}

create_default_theme() {
    # Créer un thème simple qui fonctionne toujours
    cat > "$OMP_THEMES_DIR/default.omp.json" << 'EOF'
{
  "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
  "version": 2,
  "final_space": true,
  "blocks": [
    {
      "type": "prompt",
      "alignment": "left",
      "segments": [
        {
          "type": "session",
          "style": "diamond",
          "leading_diamond": "",
          "trailing_diamond": "",
          "template": " {{ .UserName }}@{{ .HostName }} ",
          "background": "#c#!/bin/bash

# =============================================================================
# TERMINAL DEV SETUP - Installation complète Kitty + Oh My Posh (LINUX)
# =============================================================================

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Variables globales
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

# =============================================================================
# FONCTIONS UTILITAIRES
# =============================================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        print_error "Ne pas exécuter ce script en tant que root"
        print_info "Exécutez avec votre utilisateur normal, sudo sera demandé si nécessaire"
        exit 1
    fi
}

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    else
        print_error "Impossible de détecter la distribution Linux"
        exit 1
    fi
    
    print_info "Distribution détectée : $PRETTY_NAME"
}

check_dependencies() {
    print_step "Vérification des dépendances..."
    
    # Commandes requises
    local deps=("curl" "wget" "unzip" "git" "jq" "fc-cache")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        print_warning "Dépendances manquantes : ${missing[*]}"
        print_step "Installation des dépendances..."
        
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
                print_error "Distribution non supportée pour l'installation automatique"
                print_info "Installez manuellement : curl wget unzip git jq fontconfig"
                exit 1
                ;;
        esac
    fi
    
    print_success "Dépendances vérifiées"
}

# =============================================================================
# INSTALLATION POLICES NERD FONTS
# =============================================================================

install_fonts() {
    print_step "Installation des polices Nerd Fonts..."
    
    local font_dir="$HOME/.local/share/fonts"
    mkdir -p "$font_dir"
    
    # Télécharger JetBrains Mono Nerd Font
    local temp_dir=$(mktemp -d)
    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    
    print_info "Téléchargement de JetBrains Mono Nerd Font..."
    if wget -q --show-progress "$font_url" -O "$temp_dir/JetBrainsMono.zip"; then
        print_info "Extraction des polices..."
        unzip -q "$temp_dir/JetBrainsMono.zip" -d "$temp_dir/JetBrainsMono"
        
        # Copier uniquement les fichiers TTF (pas les OTF pour éviter les conflits)
        find "$temp_dir/JetBrainsMono" -name "JetBrainsMonoNerdFont-*.ttf" -exec cp {} "$font_dir/" \;
        
        # Vérifier qu'au moins une police a été copiée
        if ls "$font_dir"/JetBrainsMonoNerdFont-*.ttf 1> /dev/null 2>&1; then
            print_info "Mise à jour du cache des polices..."
            fc-cache -fv "$font_dir" >/dev/null 2>&1
            
            # Vérifier que la police est bien installée
            if fc-list | grep -q "JetBrainsMono Nerd Font"; then
                print_success "Polices Nerd Fonts installées et détectées"
            else
                print_warning "Police installée mais non détectée par fontconfig"
            fi
        else
            print_error "Aucune police JetBrains Mono trouvée dans l'archive"
            return 1
        fi
        
        # Nettoyage
        rm -rf "$temp_dir"
    else
        print_error "Échec du téléchargement des polices"
        return 1
    fi
}

# =============================================================================
# INSTALLATION OH-MY-POSH
# =============================================================================

install_oh_my_posh() {
    print_step "Installation d'Oh My Posh..."
    
    # Vérifier si déjà installé
    if command -v oh-my-posh &> /dev/null; then
        print_warning "Oh My Posh est déjà installé"
        return 0
    fi
    
    # Installation via le script officiel
    print_info "Téléchargement et installation d'Oh My Posh..."
    if curl -s https://ohmyposh.dev/install.sh | bash -s; then
        
        # Ajouter au PATH dans le .bashrc si nécessaire
        local omp_path="$HOME/.local/bin"
        if [[ ":$PATH:" != *":$omp_path:"* ]]; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        fi
        
        # Recharger le PATH pour cette session
        export PATH="$HOME/.local/bin:$PATH"
        
        print_success "Oh My Posh installé avec succès"
        log "Oh My Posh installé"
    else
        print_error "Échec de l'installation d'Oh My Posh"
        exit 1
    fi
}

download_themes() {
    print_step "Téléchargement des thèmes Oh My Posh..."
    
    # Créer le dossier themes
    mkdir -p "$OMP_THEMES_DIR"
    
    # Télécharger les thèmes depuis le repo officiel
    local themes_url="https://github.com/JanDeDobbeleer/oh-my-posh/archive/refs/heads/main.zip"
    local temp_dir=$(mktemp -d)
    
    print_info "Téléchargement des thèmes officiels..."
    if wget -q "$themes_url" -O "$temp_dir/themes.zip"; then
        unzip -q "$temp_dir/themes.zip" -d "$temp_dir"
        
        # Copier uniquement les fichiers de thèmes
        if [ -d "$temp_dir/oh-my-posh-main/themes" ]; then
            cp "$temp_dir/oh-my-posh-main/themes"/*.omp.json "$OMP_THEMES_DIR/" 2>/dev/null
            print_success "Thèmes téléchargés dans $OMP_THEMES_DIR"
        else
            print_warning "Structure de thèmes non trouvée, utilisation du thème par défaut"
        fi
        
        rm -rf "$temp_dir"
    else
        print_warning "Échec du téléchargement des thèmes, utilisation du thème par défaut"
    fi
}

# =============================================================================
# INSTALLATION KITTY
# =============================================================================

install_kitty() {
    print_step "Installation de Kitty Terminal..."
    
    # Vérifier si déjà installé
    if command -v kitty &> /dev/null; then
        print_warning "Kitty est déjà installé"
        return 0
    fi
    
    print_info "Installation de Kitty selon la distribution..."
    
    case $DISTRO in
        ubuntu|debian)
            # Ubuntu/Debian - utiliser le PPA ou le script officiel
            if ! sudo apt install -y kitty; then
                print_info "Installation via le script officiel..."
                curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
                
                # Créer un lien symbolique dans /usr/local/bin
                sudo ln -sf "$HOME/.local/kitty.app/bin/kitty" /usr/local/bin/kitty
            fi
            ;;
        fedora)
            sudo dnf install -y kitty
            ;;
        arch)
            sudo pacman -S --noconfirm kitty
            ;;
        *)
            print_info "Installation via le script officiel..."
            curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
            
            # Créer un lien symbolique dans /usr/local/bin
            sudo ln -sf "$HOME/.local/kitty.app/bin/kitty" /usr/local/bin/kitty
            ;;
    esac
    
    print_success "Kitty installé"
}

# =============================================================================
# CONFIGURATION KITTY
# =============================================================================

configure_kitty() {
    print_step "Configuration de Kitty..."
    
    # Créer le dossier de configuration
    mkdir -p "$KITTY_CONFIG_DIR"
    
    # Créer le fichier de configuration kitty.conf avec le thème Catppuccin
    cat > "$KITTY_CONFIG_DIR/kitty.conf" << 'EOF'
# THEME KITTY - Catppuccin Mocha (Configuration corrigée)
# vim:ft=kitty

# Police - Configuration corrigée pour éviter les erreurs
font_family      JetBrainsMonoNerdFont-Regular
bold_font        JetBrainsMonoNerdFont-Bold
italic_font      JetBrainsMonoNerdFont-Italic
bold_italic_font JetBrainsMonoNerdFont-BoldItalic
font_size        11.0

# Fallback si Nerd Font non trouvée
# font_family      monospace

# Apparence
background_opacity         0.95
confirm_os_window_close    0

# Couleurs Catppuccin Mocha
# text
foreground           #cdd6f4
# base
background           #1e1e2e
# selection
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
cursor_blink_interval      0.5

# Scrollback
scrollback_lines           10000
scrollback_pager           less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER

# URLs
url_color                  #89b4fa
url_style                  curly
open_url_with              default

# Raccourcis clavier
map ctrl+shift+c           copy_to_clipboard
map ctrl+shift+v           paste_from_clipboard
map ctrl+shift+f5          load_config_file
map ctrl+shift+equal       change_font_size all +1.0
map ctrl+shift+minus       change_font_size all -1.0
map ctrl+shift+backspace   change_font_size all 0

# PERSONAL SHORTCUTS
map ctrl+c copy_and_clear_or_interrupt
map ctrl+v paste_from_clipboard

# PERSONAL CONFIG
# Taille de la fenêtre au démarrage
initial_window_width 100c
initial_window_height 30c

# Padding de la fenêtre
window_padding_width 10 10 10 10

# Position de la fenêtre (optionnel)
initial_window_x 100
initial_window_y 100

# Empêcher la maximisation automatique
remember_window_size no

# Shell de démarrage
shell_integration          enabled
EOF

    # Créer le script startup.sh personnalisé
    cat > "$KITTY_CONFIG_DIR/startup.sh" << 'EOF'
#!/bin/bash

# Nettoyer l'écran
clear
printf "\033[2J\033[H"

# Variables
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
CONTENT_WIDTH=$((TERM_WIDTH - 4))

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

# Bannière personnalisée
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
echo ''

# Infos système avec icônes et couleurs
USER_INFO="${USER}@$(hostname)"
OS_INFO=$(lsb_release -d 2>/dev/null | cut -f2 || uname -o)
KERNEL_INFO=$(uname -r)
UPTIME_INFO=$(uptime -p 2>/dev/null | sed 's/up //' || echo "Indisponible")
SHELL_INFO=$(basename $SHELL)

echo -e "  ${CYAN}👤${NC} ${WHITE}Utilisateur   ${GRAY}→${NC}  ${YELLOW}${USER_INFO}${NC}"
echo -e "  ${CYAN}🚀${NC} ${WHITE}Ready to code   ${GRAY}→${NC}  Tapez '${YELLOW}aide${NC}' pour plus de commandes"

# Git info si dans un repo
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current)
    CHANGES=$(git status --porcelain | wc -l)
    echo -e "  ${PINK}🔗${NC} ${WHITE}Git Branch    ${GRAY}→${NC}  ${YELLOW}${BRANCH}${NC} ${GRAY}(${CHANGES} modifications)${NC}"
fi

echo ""

# Citations en français
QUOTES=(
    "Résoudre d'abord le problème. Puis, écrire le code."
    "Le code est de la poésie écrite en logique."
    "Un code propre semble avoir été écrit par quelqu'un qui s'en soucie."
    "La programmation, c'est découvrir ce qu'on peut faire."
)

RANDOM_QUOTE=${QUOTES[$RANDOM % ${#QUOTES[@]}]}
echo -e "  ${DIM}${GRAY}💭 ${RANDOM_QUOTE}${NC}"
echo ""

# Initialiser Oh My Posh si disponible
if command -v oh-my-posh &> /dev/null; then
    # Utiliser un thème simple et robuste
    if [ -f "$HOME/.cache/oh-my-posh/themes/powerlevel10k_rainbow.omp.json" ]; then
        eval "$(oh-my-posh init bash --config '$HOME/.cache/oh-my-posh/themes/powerlevel10k_rainbow.omp.json')"
    elif [ -f "$HOME/.cache/oh-my-posh/themes/jandedobbeleer.omp.json" ]; then
        eval "$(oh-my-posh init bash --config '$HOME/.cache/oh-my-posh/themes/jandedobbeleer.omp.json')"
    else
        # Utiliser le thème par défaut intégré (plus stable)
        eval "$(oh-my-posh init bash)"
    fi
fi
EOF

    chmod +x "$KITTY_CONFIG_DIR/startup.sh"
    
    print_success "Configuration Kitty créée"
}

# =============================================================================
# CONFIGURATION BASHRC
# =============================================================================

configure_bashrc() {
    print_step "Configuration du .bashrc..."
    
    # Backup du .bashrc existant
    if [ -f "$HOME/.bashrc" ]; then
        cp "$HOME/.bashrc" "$HOME/.bashrc.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Sauvegarde de .bashrc créée"
    fi
    
    # Ajouter la configuration personnalisée à .bashrc
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

# Styles
BOLD='\033[1m'
DIM='\033[2m'

# Démarrage custom (uniquement pour les sessions interactives)
if [[ $- == *i* ]] && [[ -z "$STARTUP_DONE" ]]; then
    export STARTUP_DONE=1
    ~/.config/kitty/startup.sh
fi

# Fonction d'aide propre
aide() {
    echo ""
    echo -e "${WHITE}${BOLD}🦊 AIDE - COMMANDES DISPONIBLES${NC}"
    echo -e "${GRAY}▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔${NC}"
    echo -e "  ${GREEN}Navigation :${NC} proj, web, util, home"
    echo -e "  ${PURPLE}Git :${NC} gs (status), ga (add), gc (commit), gp (push)"
    echo -e "  ${BLUE}Système :${NC} ll, ports, myip, cpu"
    echo -e "  ${YELLOW}${DIM}Tips :"
    echo -e "  ${GRAY}${DIM}Pour modifier/ajouter des alias, rendez-vous dans le fichier .bashrc"
    echo -e "  Vous pouvez choisir votre thème oh-my-posh parmis le large choix disponible sur leur site"
    echo ""
}

# Aliases personnalisés pour les raccourcis
alias ll='ls -alF --color=auto'
alias ports='sudo netstat -tuln'
alias myip='curl -s https://httpbin.org/ip | jq -r .origin'
alias cpu='top -bn1 | grep "Cpu(s)" | awk "{print \$2}" | awk -F"%" "{print \$1}"'
alias home='cd ~'

# Aliases Git
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'

# Aliases de navigation
alias proj='cd ~/Documents/Projets'
alias web='cd ~/Documents/Projets'
alias util='cd ~/Documents/Utilitaires'
alias home='cd ~'

# Initialiser Oh My Posh si disponible
if command -v oh-my-posh &> /dev/null; then
    # Utiliser le thème agnoster ou un thème par défaut
    if [ -f "$HOME/.cache/oh-my-posh/themes/agnoster.omp.json" ]; then
        eval "$(oh-my-posh init bash --config '$HOME/.cache/oh-my-posh/themes/agnoster.omp.json')"
    else
        eval "$(oh-my-posh init bash)"
    fi
fi

EOF

    print_success "Configuration .bashrc mise à jour"
}

# =============================================================================
# CONFIGURATION SYSTÈME
# =============================================================================

set_default_terminal() {
    print_step "Configuration de Kitty comme terminal par défaut..."
    
    # Créer le fichier .desktop pour Kitty si nécessaire
    local desktop_file="$HOME/.local/share/applications/kitty-custom.desktop"
    mkdir -p "$(dirname "$desktop_file")"
    
    cat > "$desktop_file" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Kitty Terminal Dev
Comment=Terminal rapide et configurable pour développeurs
Exec=kitty
Icon=kitty
Terminal=false
Categories=System;TerminalEmulator;
StartupNotify=true
MimeType=application/x-shellscript;
EOF
    
    # Mettre à jour la base de données des applications
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    
    # Définir Kitty comme terminal par défaut via update-alternatives (nécessite sudo)
    print_info "Configuration du terminal par défaut système..."
    if command -v update-alternatives >/dev/null 2>&1; then
        # Vérifier si kitty est dans le PATH
        KITTY_PATH=$(which kitty 2>/dev/null || echo "/usr/bin/kitty")
        
        if [ -x "$KITTY_PATH" ]; then
            # Ajouter kitty aux alternatives et le définir par défaut
            sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$KITTY_PATH" 100
            sudo update-alternatives --set x-terminal-emulator "$KITTY_PATH"
            print_success "Kitty défini comme terminal par défaut système"
        else
            print_warning "Impossible de trouver l'exécutable kitty"
        fi
    else
        print_warning "update-alternatives non disponible sur cette distribution"
    fi
    
    # Configuration GNOME si disponible
    if command -v gsettings >/dev/null 2>&1; then
        print_info "Configuration du terminal par défaut pour GNOME..."
        gsettings set org.gnome.desktop.default-applications.terminal exec 'kitty' 2>/dev/null || true
        gsettings set org.gnome.desktop.default-applications.terminal exec-arg '' 2>/dev/null || true
    fi
    
    print_success "Kitty configuré dans les applications"
}

configure_hotkey() {
    print_step "Configuration du raccourci Super+T..."
    
    print_warning "Configuration manuelle requise pour Super+T :"
    
    case $DISTRO in
        ubuntu|debian)
            print_info "Ubuntu/Debian :"
            print_info "1. Paramètres > Clavier > Raccourcis personnalisés"
            print_info "2. Ajouter : Nom='Terminal Kitty', Commande='kitty', Raccourci='Super+T'"
            ;;
        fedora)
            print_info "Fedora (GNOME) :"
            print_info "1. Paramètres > Clavier > Raccourcis de vue"
            print_info "2. Personnaliser les raccourcis > Ajouter un raccourci"
            print_info "3. Nom='Kitty', Commande='kitty', Raccourci='Super+T'"
            ;;
        arch)
            print_info "Arch Linux :"
            print_info "Dépend de votre environnement de bureau (GNOME/KDE/i3/etc.)"
            print_info "Commande à assigner : 'kitty'"
            ;;
        *)
            print_info "Configuration générique :"
            print_info "Assigner le raccourci Super+T à la commande : 'kitty'"
            ;;
    esac
    
    print_info "Alternative via gsettings (GNOME) :"
    echo "gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Kitty'"
    echo "gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'kitty'"
    echo "gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super>t'"
}

# =============================================================================
# FONCTION PRINCIPALE
# =============================================================================

main() {
    print_header
    
    # Initialiser le log
    echo "=== TERMINAL DEV SETUP LOG - LINUX ===" > "$LOG_FILE"
    log "Début de l'installation"
    
    # Vérifications préalables
    check_sudo
    detect_distro
    check_dependencies
    
    print_info "Installation en cours... Consultez $LOG_FILE pour les détails"
    echo ""
    
    # Séquence d'installation
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
    
    configure_hotkey
    echo ""
    
    # Finalisation
    print_header
    print_success "Installation terminée avec succès !"
    echo ""
    
    # Vérifications post-installation
    print_info "VÉRIFICATIONS POST-INSTALLATION :"
    
    # Vérifier Oh My Posh
    if command -v oh-my-posh >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Oh My Posh installé"
    else
        echo -e "  ${RED}✗${NC} Oh My Posh non trouvé"
    fi
    
    # Vérifier Kitty
    if command -v kitty >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Kitty installé"
    else
        echo -e "  ${RED}✗${NC} Kitty non trouvé"
    fi
    
    # Vérifier les polices
    if fc-list | grep -q "JetBrainsMono Nerd Font"; then
        echo -e "  ${GREEN}✓${NC} Polices Nerd Font détectées"
    else
        echo -e "  ${YELLOW}⚠${NC} Polices Nerd Font non détectées (redémarrage peut être nécessaire)"
    fi
    
    echo ""
    print_info "PROCHAINES ÉTAPES :"
    echo -e "  ${CYAN}1.${NC} ${BOLD}REDÉMARREZ votre session${NC} pour appliquer toutes les configurations"
    echo -e "  ${CYAN}2.${NC} Ou lancez : ${BOLD}source ~/.bashrc && fc-cache -fv${NC}"
    echo -e "  ${CYAN}3.${NC} Configurez le raccourci Super+T manuellement (voir instructions)"
    echo -e "  ${CYAN}4.${NC} Lancez Kitty depuis le lanceur d'applications ou tapez : ${BOLD}kitty${NC}"
    echo -e "  ${CYAN}5.${NC} Votre bannière personnalisée s'affichera automatiquement"
    echo -e "  ${CYAN}6.${NC} Utilisez ${BOLD}Ctrl+C${NC} et ${BOLD}Ctrl+V${NC} pour copier/coller"
    echo ""
    print_info "Fichiers créés :"
    echo -e "  ${DIM}• Configuration : ~/.config/kitty/kitty.conf${NC}"
    echo -e "  ${DIM}• Script startup : ~/.config/kitty/startup.sh${NC}"
    echo -e "  ${DIM}• Configuration : ~/.bashrc (sauvegardé)${NC}"
    echo -e "  ${DIM}• Application : ~/.local/share/applications/kitty-custom.desktop${NC}"
    echo -e "  ${DIM}• Log : $LOG_FILE${NC}"
    echo ""
    
    print_info "Commandes disponibles après redémarrage :"
    echo -e "  ${DIM}• aide - Afficher l'aide${NC}"
    echo -e "  ${DIM}• ll, gs, ga, gc, gp - Raccourcis utiles${NC}"
    echo -e "  ${DIM}• proj, web, util, home - Navigation rapide${NC}"
    echo ""
    
    log "Installation Linux terminée avec succès"
}

# =============================================================================
# GESTION DES ERREURS
# =============================================================================

trap 'print_error "Installation interrompue"; exit 1' INT TERM

# =============================================================================
# POINT D'ENTRÉE
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
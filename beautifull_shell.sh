#!/bin/bash

# =============================================================================
# TERMINAL DEV SETUP - Installation complète Kitty + Oh My Posh
# Version finale corrigée - Compatible toutes distributions Linux
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
OMP_BINARY="$HOME/.local/bin/oh-my-posh"

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
            ubuntu|debian|pop|mint|elementary|zorin|neon)
                sudo apt update && sudo apt install -y curl wget unzip git jq fontconfig
                ;;
            fedora|centos|rhel|rocky|almalinux)
                sudo dnf install -y curl wget unzip git jq fontconfig
                ;;
            arch|manjaro|endeavouros|arcolinux)
                sudo pacman -S --noconfirm curl wget unzip git jq fontconfig
                ;;
            opensuse*|sles)
                sudo zypper install -y curl wget unzip git jq fontconfig
                ;;
            void)
                sudo xbps-install -Sy curl wget unzip git jq fontconfig
                ;;
            alpine)
                sudo apk add curl wget unzip git jq fontconfig
                ;;
            *)
                print_error "Distribution non supportée automatiquement"
                print_info "Installez manuellement : curl wget unzip git jq fontconfig"
                read -p "Continuer quand même ? (y/N) " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    exit 1
                fi
                ;;
        esac
    fi
    
    print_success "Dépendances OK"
}

# =============================================================================
# NETTOYAGE PRÉALABLE
# =============================================================================

cleanup_previous_install() {
    print_step "Nettoyage des installations précédentes..."
    
    # Nettoyer les variables d'environnement Oh My Posh
    unset POSH_THEME POSH_SESSION_ID POSH_SHELL_VERSION POSH_PID
    
    # Supprimer le cache Oh My Posh s'il est corrompu
    if [ -d "$HOME/.cache/oh-my-posh" ]; then
        print_info "Suppression du cache Oh My Posh existant"
        rm -rf "$HOME/.cache/oh-my-posh"
    fi
    
    # Sauvegarder et nettoyer .bashrc
    if [ -f "$HOME/.bashrc" ]; then
        cp "$HOME/.bashrc" "$HOME/.bashrc.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Sauvegarde .bashrc créée"
        
        # Supprimer les anciennes configurations Oh My Posh
        sed -i '/oh-my-posh/d' "$HOME/.bashrc" 2>/dev/null
        sed -i '/Oh My Posh/d' "$HOME/.bashrc" 2>/dev/null
        sed -i '/POSH_/d' "$HOME/.bashrc" 2>/dev/null
        sed -i '/# CONFIG PERSO - TERMINAL DEV SETUP/,$d' "$HOME/.bashrc" 2>/dev/null
    fi
    
    print_success "Nettoyage terminé"
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
        print_success "Polices JetBrains Mono Nerd Font installées"
    else
        print_error "Échec téléchargement polices"
        return 1
    fi
}

install_oh_my_posh() {
    print_step "Installation d'Oh My Posh..."
    
    # Créer le répertoire bin
    mkdir -p "$HOME/.local/bin"
    
    # Supprimer binaire existant s'il est corrompu
    if [ -f "$OMP_BINARY" ] && ! "$OMP_BINARY" --version >/dev/null 2>&1; then
        print_warning "Suppression binaire Oh My Posh corrompu"
        rm -f "$OMP_BINARY"
    fi
    
    # Détecter l'architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) OMP_ARCH="amd64" ;;
        aarch64|arm64) OMP_ARCH="arm64" ;;
        armv7l) OMP_ARCH="arm" ;;
        *) 
            print_error "Architecture non supportée: $ARCH"
            return 1
            ;;
    esac
    
    # Téléchargement du binaire
    local omp_url="https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-${OMP_ARCH}"
    
    print_info "Téléchargement Oh My Posh pour $ARCH ($OMP_ARCH)"
    
    if wget -q --show-progress "$omp_url" -O "$OMP_BINARY"; then
        chmod +x "$OMP_BINARY"
        
        # Vérification du binaire
        if "$OMP_BINARY" --version >/dev/null 2>&1; then
            local version=$("$OMP_BINARY" --version 2>/dev/null | head -n1)
            print_success "Oh My Posh installé : $version"
        else
            print_error "Binaire Oh My Posh non fonctionnel"
            rm -f "$OMP_BINARY"
            return 1
        fi
    else
        print_error "Échec téléchargement Oh My Posh"
        return 1
    fi
}

download_themes() {
    print_step "Téléchargement des thèmes Oh My Posh..."
    
    mkdir -p "$OMP_THEMES_DIR"
    
    # Liste des thèmes essentiels
    local themes=(
        "aliens" "atomic" "blue-owl" "capr4n" "catppuccin" 
        "craver" "dracula" "jandedobbeleer" "kushal" "lambda" 
        "marcduiker" "paradox" "pure" "robbyrussell" "spaceship" 
        "star" "stelbent" "tokyo" "powerlevel10k_rainbow"
    )
    
    local downloaded=0
    local failed=0
    
    for theme in "${themes[@]}"; do
        local theme_url="https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/${theme}.omp.json"
        if wget -q "$theme_url" -O "$OMP_THEMES_DIR/${theme}.omp.json" 2>/dev/null; then
            ((downloaded++))
        else
            ((failed++))
        fi
    done
    
    if [ "$downloaded" -gt 0 ]; then
        print_success "$downloaded thèmes téléchargés ($failed échecs)"
    else
        print_warning "Aucun thème téléchargé - utilisation du thème par défaut"
    fi
}

install_kitty() {
    print_step "Installation de Kitty Terminal..."
    
    if command -v kitty &> /dev/null; then
        print_warning "Kitty déjà installé"
        return 0
    fi
    
    case $DISTRO in
        ubuntu|debian|pop|mint|elementary|zorin|neon)
            sudo apt install -y kitty
            ;;
        fedora|centos|rhel|rocky|almalinux)
            sudo dnf install -y kitty
            ;;
        arch|manjaro|endeavouros|arcolinux)
            sudo pacman -S --noconfirm kitty
            ;;
        opensuse*|sles)
            sudo zypper install -y kitty
            ;;
        void)
            sudo xbps-install -Sy kitty
            ;;
        alpine)
            sudo apk add kitty
            ;;
        *)
            print_info "Installation manuelle de Kitty..."
            if curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin; then
                sudo ln -sf "$HOME/.local/kitty.app/bin/kitty" /usr/local/bin/kitty 2>/dev/null || true
            else
                print_warning "Échec installation Kitty - continuez manuellement"
                return 1
            fi
            ;;
    esac
    
    if command -v kitty &> /dev/null; then
        print_success "Kitty installé avec succès"
    else
        print_warning "Kitty non détecté après installation"
    fi
}

# =============================================================================
# CONFIGURATIONS
# =============================================================================

configure_kitty() {
    print_step "Configuration de Kitty..."
    
    mkdir -p "$KITTY_CONFIG_DIR"
    
    cat > "$KITTY_CONFIG_DIR/kitty.conf" << 'EOF'
# =============================================================================
# KITTY TERMINAL CONFIGURATION - TERMINAL DEV SETUP
# =============================================================================

# Police et taille
font_family      JetBrainsMonoNerdFont-Regular
bold_font        JetBrainsMonoNerdFont-Bold
italic_font      JetBrainsMonoNerdFont-Italic
bold_italic_font JetBrainsMonoNerdFont-BoldItalic
font_size        11.0

# Apparence
background_opacity         0.95
confirm_os_window_close    0

# Thème Catppuccin Mocha
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

# Raccourcis clavier
map ctrl+c copy_and_clear_or_interrupt
map ctrl+v paste_from_clipboard
map ctrl+shift+c copy_to_clipboard
map ctrl+shift+v paste_from_clipboard
map ctrl+shift+enter new_window
map ctrl+shift+] next_window
map ctrl+shift+[ previous_window

# Configuration fenêtre
initial_window_width 100c
initial_window_height 30c
window_padding_width 10 10 10 10
remember_window_size no

# Shell integration
shell_integration enabled
EOF

    # Script de démarrage
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

# Bannière de bienvenue
get_padding() {
    local term_width=$(tput cols 2>/dev/null || echo 80)
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

# Informations système
USER_INFO="${USER}@$(hostname)"
echo -e "  ${CYAN}👤${NC} ${WHITE}Utilisateur   ${GRAY}→${NC}  ${YELLOW}${USER_INFO}${NC}"
echo -e "  ${CYAN}🚀${NC} ${WHITE}Ready to code   ${GRAY}→${NC}  Tapez '${YELLOW}aide${NC}' pour plus de commandes"

# Informations Git si dans un repo
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
    CHANGES=$(git status --porcelain 2>/dev/null | wc -l)
    echo -e "  ${PINK}🔗${NC} ${WHITE}Git Branch    ${GRAY}→${NC}  ${YELLOW}${BRANCH}${NC} ${GRAY}(${CHANGES} modifications)${NC}"
fi

echo ""

# Citation aléatoire
QUOTES=(
    "Résoudre d'abord le problème. Puis, écrire le code."
    "Le code est de la poésie écrite en logique."
    "Un code propre semble avoir été écrit par quelqu'un qui s'en soucie."
    "La programmation, c'est découvrir ce qu'on peut faire."
    "Debugger, c'est être détective dans un film policier où vous êtes aussi le meurtrier."
    "Le meilleur code est celui qu'on n'a pas besoin d'écrire."
)

RANDOM_QUOTE=${QUOTES[$RANDOM % ${#QUOTES[@]}]}
echo -e "  ${DIM}${GRAY}💭 ${RANDOM_QUOTE}${NC}"
echo ""
EOF

    chmod +x "$KITTY_CONFIG_DIR/startup.sh"
    print_success "Configuration Kitty créée"
}

configure_bashrc() {
    print_step "Configuration du .bashrc..."
    
    cat >> "$HOME/.bashrc" << 'EOF'

# =============================================================================
# CONFIG PERSO - TERMINAL DEV SETUP
# =============================================================================

# Couleurs pour les fonctions personnalisées
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

# PATH pour Oh My Posh
export PATH="$HOME/.local/bin:$PATH"

# Démarrage personnalisé (uniquement en mode interactif et première fois)
if [[ $- == *i* ]] && [[ -z "$STARTUP_DONE" ]] && [[ -f "$HOME/.config/kitty/startup.sh" ]]; then
    export STARTUP_DONE=1
    ~/.config/kitty/startup.sh
fi

# =============================================================================
# FONCTIONS PERSONNALISÉES
# =============================================================================

# Fonction d'aide complète
aide() {
    echo ""
    echo -e "${WHITE}${BOLD}🦊 AIDE - COMMANDES DISPONIBLES${NC}"
    echo -e "${GRAY}▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔${NC}"
    echo -e "  ${GREEN}Navigation :${NC} proj, web, util, home, .., ..."
    echo -e "  ${PURPLE}Git :${NC} gs (status), ga (add), gc (commit), gp (push), gl (log), gd (diff)"
    echo -e "  ${BLUE}Système :${NC} ll, la, ports, myip, cpu"
    echo -e "  ${ORANGE}Oh My Posh :${NC} omp-theme [nom], omp-reset, omp-list"
    echo ""
    echo -e "${WHITE}${BOLD}💡 TIPS & ASTUCES${NC}"
    echo -e "${GRAY}▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔${NC}"
    echo -e "  ${CYAN}🎨 Personnalisation :${NC}"
    echo -e "     • Modifiez les alias dans ~/.bashrc"
    echo -e "     • Explorez les thèmes Oh-My-Posh : omp-list"
    echo -e "     • Personnalisez Kitty : ~/.config/kitty/kitty.conf"
    echo ""
    echo -e "  ${CYAN}⌨️  Raccourcis Kitty :${NC}"
    echo -e "     • Ctrl+C & Ctrl+V : Copier/Coller"
    echo -e "     • Ctrl+Shift+Enter : Nouvelle fenêtre"
    echo -e "     • Ctrl+Shift+] : Fenêtre suivante"
    echo -e "     • Ctrl+Shift+[ : Fenêtre précédente"
    echo -e "     • Ctrl+Shift+C/V : Copier/Coller (alternative)"
    echo ""
    echo -e "  ${CYAN}🔧 Dépannage :${NC}"
    echo -e "     • Oh My Posh ne marche pas : omp-reset"
    echo -e "     • Recharger config : source ~/.bashrc"
    echo -e "     • Restaurer .bashrc : cp ~/.bashrc.backup.* ~/.bashrc"
    echo -e "     • Logs installation : cat setup.log"
    echo ""
    echo -e "  ${CYAN}🚀 Productivité :${NC}"
    echo -e "     • 'proj' pour aller dans vos projets"
    echo -e "     • 'ports' pour voir les ports ouverts"
    echo -e "     • 'myip' pour votre IP publique"
    echo -e "     • 'gs' pour git status rapide"
    echo -e "     • 'll' pour listing détaillé"
    echo ""
}

# Fonction pour changer de thème Oh My Posh
omp-theme() {
    local save_flag=false
    local theme_name=""
    
    # Parser les arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--save)
                save_flag=true
                shift
                ;;
            -h|--help)
                echo -e "${YELLOW}Usage: omp-theme [OPTIONS] [nom_du_thème]${NC}"
                echo ""
                echo -e "${CYAN}Options :${NC}"
                echo -e "  -s, --save    Sauvegarder le thème pour les futures sessions"
                echo -e "  -h, --help    Afficher cette aide"
                echo ""
                echo -e "${CYAN}Exemples :${NC}"
                echo -e "  omp-theme aliens           # Appliquer temporairement"
                echo -e "  omp-theme -s atomic        # Appliquer et sauvegarder"
                echo -e "  omp-theme --save dracula   # Appliquer et sauvegarder"
                return
                ;;
            *)
                theme_name="$1"
                shift
                ;;
        esac
    done
    
    # Si pas de thème spécifié, afficher la liste
    if [ -z "$theme_name" ]; then
        echo -e "${YELLOW}Usage: omp-theme [OPTIONS] [nom_du_thème]${NC}"
        echo -e "${CYAN}Thèmes disponibles :${NC}"
        omp-list
        echo ""
        echo -e "${DIM}Utilisez 'omp-theme -h' pour voir l'aide complète${NC}"
        return
    fi
    
    local theme_file="$HOME/.cache/oh-my-posh/themes/$theme_name.omp.json"
    if [ -f "$theme_file" ]; then
        # Appliquer le thème pour cette session
        eval "$(oh-my-posh init bash --config "$theme_file")"
        echo -e "${GREEN}✓ Thème '$theme_name' appliqué pour cette session${NC}"
        
        # Sauvegarder si demandé
        if [ "$save_flag" = true ]; then
            omp-save-theme "$theme_name"
        else
            echo -e "${DIM}Ajoutez -s pour sauvegarder : omp-theme -s $theme_name${NC}"
        fi
    else
        echo -e "${RED}✗ Thème '$theme_name' introuvable${NC}"
        echo -e "${CYAN}Thèmes disponibles :${NC}"
        omp-list
    fi
}

# Fonction pour sauvegarder un thème de façon permanente
omp-save-theme() {
    local theme_name="$1"
    local theme_file="$HOME/.cache/oh-my-posh/themes/$theme_name.omp.json"
    
    if [ ! -f "$theme_file" ]; then
        echo -e "${RED}✗ Thème '$theme_name' introuvable${NC}"
        return 1
    fi
    
    # Créer une sauvegarde du .bashrc
    cp ~/.bashrc ~/.bashrc.backup.theme.$(date +%Y%m%d_%H%M%S)
    
    # Supprimer l'ancienne configuration Oh My Posh
    sed -i '/# Chercher un thème par ordre de préférence/,/^fi$/d' ~/.bashrc
    
    # Ajouter la nouvelle configuration
    cat >> ~/.bashrc << EOF

        # Chercher un thème par ordre de préférence
        if [ -f "\$HOME/.cache/oh-my-posh/themes/$theme_name.omp.json" ]; then
            eval "\$(oh-my-posh init bash --config "\$HOME/.cache/oh-my-posh/themes/$theme_name.omp.json")"
        elif [ -f "\$HOME/.cache/oh-my-posh/themes/aliens.omp.json" ]; then
            eval "\$(oh-my-posh init bash --config "\$HOME/.cache/oh-my-posh/themes/aliens.omp.json")"
        elif [ -f "\$HOME/.cache/oh-my-posh/themes/atomic.omp.json" ]; then
            eval "\$(oh-my-posh init bash --config "\$HOME/.cache/oh-my-posh/themes/atomic.omp.json")"
        else
            # Utiliser le thème par défaut
            eval "\$(oh-my-posh init bash)"
        fi
    fi
fi

EOF

    echo -e "${GREEN}✓ Thème '$theme_name' sauvegardé comme thème par défaut${NC}"
    echo -e "${CYAN}Le thème sera appliqué dans les nouvelles sessions de terminal${NC}"
    echo -e "${DIM}Sauvegarde créée : ~/.bashrc.backup.theme.$(date +%Y%m%d_%H%M%S)${NC}"
}

# Fonction pour voir le thème actuel
omp-current() {
    if [ -n "$POSH_THEME" ]; then
        local current_theme=$(basename "$POSH_THEME" .omp.json)
        echo -e "${CYAN}Thème actuel :${NC} ${GREEN}$current_theme${NC}"
        echo -e "${DIM}Fichier : $POSH_THEME${NC}"
    else
        echo -e "${YELLOW}Thème par défaut d'Oh My Posh${NC}"
        echo -e "${DIM}Aucun fichier de configuration spécifique${NC}"
    fi
}

# Fonction pour restaurer le thème par défaut
omp-default() {
    unset POSH_THEME POSH_SESSION_ID POSH_SHELL_VERSION
    eval "$(oh-my-posh init bash)"
    echo -e "${GREEN}✓ Thème par défaut d'Oh My Posh restauré${NC}"
    
    read -p "Sauvegarder comme thème par défaut ? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Sauvegarder le thème par défaut
        cp ~/.bashrc ~/.bashrc.backup.default.$(date +%Y%m%d_%H%M%S)
        sed -i '/# Chercher un thème par ordre de préférence/,/^fi$/d' ~/.bashrc
        
        cat >> ~/.bashrc << 'EOF'

        # Utiliser le thème par défaut d'Oh My Posh
        eval "$(oh-my-posh init bash)"
    fi
fi

EOF
        echo -e "${GREEN}✓ Thème par défaut sauvegardé${NC}"
    fi
}

# Lister les thèmes disponibles
omp-list() {
    if [ -d "$HOME/.cache/oh-my-posh/themes" ]; then
        ls "$HOME/.cache/oh-my-posh/themes"/*.omp.json 2>/dev/null | xargs -n1 basename | sed 's/.omp.json//' | sort | column
    else
        echo -e "${RED}Aucun thème trouvé. Réinstallez avec le script.${NC}"
    fi
}

# Réinitialiser Oh My Posh
omp-reset() {
    unset POSH_THEME POSH_SESSION_ID POSH_SHELL_VERSION
    if [ -f "$HOME/.cache/oh-my-posh/themes/aliens.omp.json" ]; then
        eval "$(oh-my-posh init bash --config "$HOME/.cache/oh-my-posh/themes/aliens.omp.json")"
        echo -e "${GREEN}✓ Oh My Posh réinitialisé avec le thème aliens${NC}"
    elif [ -f "$HOME/.cache/oh-my-posh/themes/atomic.omp.json" ]; then
        eval "$(oh-my-posh init bash --config "$HOME/.cache/oh-my-posh/themes/atomic.omp.json")"
        echo -e "${GREEN}✓ Oh My Posh réinitialisé avec le thème atomic${NC}"
    else
        eval "$(oh-my-posh init bash)"
        echo -e "${GREEN}✓ Oh My Posh réinitialisé avec le thème par défaut${NC}"
    fi
}

# =============================================================================
# ALIASES
# =============================================================================

# Listing et navigation
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias home='cd ~'

# Système
alias ports='sudo netstat -tuln'
alias myip='curl -s https://httpbin.org/ip | jq -r .origin 2>/dev/null || curl -s ifconfig.me'
alias cpu='top -bn1 | grep "Cpu(s)" | awk "{print \$2}" | awk -F"%" "{print \$1}" || echo "N/A"'
alias df='df -h'
alias free='free -h'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline -10'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# Navigation projets (avec création automatique)
alias proj='mkdir -p ~/Documents/Projets && cd ~/Documents/Projets'
alias web='mkdir -p ~/Documents/Projets && cd ~/Documents/Projets'
alias util='mkdir -p ~/Documents/Utilitaires && cd ~/Documents/Utilitaires'

# Raccourcis utiles
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# =============================================================================
# INITIALISATION OH MY POSH
# =============================================================================

# Oh My Posh - Configuration sécurisée
if [[ $- == *i* ]] && command -v oh-my-posh >/dev/null 2>&1; then
    # Vérifier que Oh My Posh fonctionne
    if oh-my-posh --version >/dev/null 2>&1; then
        # Chercher un thème par ordre de préférence
        if [ -f "$HOME/.cache/oh-my-posh/themes/aliens.omp.json" ]; then
            eval "$(oh-my-posh init bash --config "$HOME/.cache/oh-my-posh/themes/aliens.omp.json")"
        elif [ -f "$HOME/.cache/oh-my-posh/themes/atomic.omp.json" ]; then
            eval "$(oh-my-posh init bash --config "$HOME/.cache/oh-my-posh/themes/atomic.omp.json")"
        elif [ -f "$HOME/.cache/oh-my-posh/themes/paradox.omp.json" ]; then
            eval "$(oh-my-posh init bash --config "$HOME/.cache/oh-my-posh/themes/paradox.omp.json")"
        else
            # Utiliser le thème par défaut
            eval "$(oh-my-posh init bash)"
        fi
    fi
fi

EOF

    print_success "Configuration .bashrc complète créée"
}

set_default_terminal() {
    print_step "Configuration du terminal par défaut..."
    
    if command -v kitty >/dev/null 2>&1 && command -v update-alternatives >/dev/null 2>&1; then
        KITTY_PATH=$(which kitty)
        if [ -x "$KITTY_PATH" ]; then
            sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$KITTY_PATH" 100 2>/dev/null
            sudo update-alternatives --set x-terminal-emulator "$KITTY_PATH" 2>/dev/null
            print_success "Kitty défini comme terminal par défaut"
        fi
    else
        print_info "Configuration du terminal par défaut ignorée"
    fi
}

# =============================================================================
# TESTS ET DIAGNOSTICS
# =============================================================================

run_diagnostics() {
    print_step "Tests de validation finale..."
    
    local errors=0
    local warnings=0
    
    # Test Oh My Posh
    if [ -f "$OMP_BINARY" ] && "$OMP_BINARY" --version >/dev/null 2>&1; then
        local omp_version=$("$OMP_BINARY" --version 2>/dev/null | head -n1)
        print_success "Oh My Posh : $omp_version"
    else
        print_error "Oh My Posh non fonctionnel"
        ((errors++))
    fi
    
    # Test Kitty
    if command -v kitty &> /dev/null; then
        local kitty_version=$(kitty --version 2>/dev/null | head -n1)
        print_success "Kitty : $kitty_version"
    else
        print_warning "Kitty non détecté"
        ((warnings++))
    fi
    
    # Test polices
    if fc-list | grep -i "jetbrainsmono" >/dev/null 2>&1; then
        print_success "Polices JetBrains Mono Nerd Font détectées"
    else
        print_warning "Polices JetBrains Mono non détectées"
        ((warnings++))
    fi
    
    # Test thèmes
    local theme_count=$(ls "$OMP_THEMES_DIR"/*.omp.json 2>/dev/null | wc -l)
    if [ "$theme_count" -gt 0 ]; then
        print_success "$theme_count thèmes Oh My Posh disponibles"
    else
        print_warning "Aucun thème Oh My Posh trouvé"
        ((warnings++))
    fi
    
    # Test configuration
    if [ -f "$KITTY_CONFIG_DIR/kitty.conf" ]; then
        print_success "Configuration Kitty présente"
    else
        print_warning "Configuration Kitty manquante"
        ((warnings++))
    fi
    
    # Test initialisation Oh My Posh
    export PATH="$HOME/.local/bin:$PATH"
    if command -v oh-my-posh >/dev/null 2>&1 && oh-my-posh init bash >/dev/null 2>&1; then
        print_success "Initialisation Oh My Posh fonctionnelle"
    else
        print_error "Initialisation Oh My Posh défaillante"
        ((errors++))
    fi
    
    echo ""
    if [ $errors -eq 0 ]; then
        if [ $warnings -eq 0 ]; then
            print_success "Tous les tests passés avec succès !"
        else
            print_warning "$warnings avertissement(s) - Installation fonctionnelle"
        fi
        return 0
    else
        print_error "$errors erreur(s) critique(s) détectée(s)"
        return 1
    fi
}

# =============================================================================
# FONCTION PRINCIPALE
# =============================================================================

main() {
    print_header
    log "Début installation Terminal Dev Setup"
    
    # Vérifications préalables
    check_sudo
    detect_distro
    
    # Nettoyage des installations précédentes
    cleanup_previous_install
    
    # Vérification et installation des dépendances
    check_dependencies
    
    echo ""
    
    # Installations principales
    install_fonts
    echo ""
    install_oh_my_posh
    echo ""
    download_themes
    echo ""
    install_kitty
    echo ""
    
    # Configurations
    configure_kitty
    echo ""
    configure_bashrc
    echo ""
    set_default_terminal
    echo ""
    
    # Tests de validation
    if run_diagnostics; then
        print_header
        echo -e "${GREEN}${BOLD}🎉 INSTALLATION TERMINÉE AVEC SUCCÈS ! 🎉${NC}"
        echo ""
        echo -e "${WHITE}${BOLD}PROCHAINES ÉTAPES :${NC}"
        echo -e "${CYAN}▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔${NC}"
        echo ""
        echo -e "  ${YELLOW}1.${NC} ${BOLD}Redémarrez votre session${NC} ou lancez :"
        echo -e "     ${DIM}source ~/.bashrc${NC}"
        echo ""
        echo -e "  ${YELLOW}2.${NC} ${BOLD}Lancez Kitty Terminal :${NC}"
        echo -e "     ${DIM}kitty${NC}"
        echo ""
        echo -e "  ${YELLOW}3.${NC} ${BOLD}Testez Oh My Posh :${NC}"
        echo -e "     ${DIM}oh-my-posh --version${NC}"
        echo ""
        echo -e "  ${YELLOW}4.${NC} ${BOLD}Explorez les thèmes :${NC}"
        echo -e "     ${DIM}omp-list${NC}"
        echo -e "     ${DIM}omp-theme atomic${NC}"
        echo ""
        echo -e "  ${YELLOW}5.${NC} ${BOLD}Aide et astuces :${NC}"
        echo -e "     ${DIM}aide${NC}"
        echo ""
        echo -e "${WHITE}${BOLD}COMMANDES UTILES :${NC}"
        echo -e "${CYAN}▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔${NC}"
        echo -e "  • ${GREEN}omp-theme [nom]${NC}     Changer de thème"
        echo -e "  • ${GREEN}omp-theme -s [nom]${NC}  Changer et sauvegarder le thème"
        echo -e "  • ${GREEN}omp-save-theme${NC}      Sauvegarder le thème actuel"
        echo -e "  • ${GREEN}omp-current${NC}         Voir le thème actuel"
        echo -e "  • ${GREEN}omp-default${NC}         Revenir au thème par défaut"
        echo -e "  • ${GREEN}omp-reset${NC}           Réinitialiser Oh My Posh"
        echo -e "  • ${GREEN}omp-list${NC}            Lister tous les thèmes"
        echo -e "  • ${GREEN}gs${NC}                  Git status rapide"
        echo -e "  • ${GREEN}proj${NC}                Aller dans vos projets"
        echo -e "  • ${GREEN}aide${NC}                Afficher l'aide complète"
        echo ""
        
        # Test immédiat si on est dans Kitty
        if [ "$TERM" = "xterm-kitty" ]; then
            echo -e "${PURPLE}${BOLD}🚀 Vous utilisez déjà Kitty ! Configuration appliquée immédiatement.${NC}"
            echo ""
            
            # Appliquer Oh My Posh pour cette session
            export PATH="$HOME/.local/bin:$PATH"
            if [ -f "$HOME/.cache/oh-my-posh/themes/aliens.omp.json" ]; then
                eval "$(oh-my-posh init bash --config "$HOME/.cache/oh-my-posh/themes/aliens.omp.json")"
                echo -e "${GREEN}✓ Oh My Posh activé avec le thème aliens${NC}"
            elif command -v oh-my-posh >/dev/null 2>&1; then
                eval "$(oh-my-posh init bash)"
                echo -e "${GREEN}✓ Oh My Posh activé avec le thème par défaut${NC}"
            fi
        fi
        
    else
        print_header
        echo -e "${YELLOW}${BOLD}⚠️  INSTALLATION TERMINÉE AVEC DES AVERTISSEMENTS ⚠️${NC}"
        echo ""
        echo -e "${WHITE}${BOLD}ACTIONS RECOMMANDÉES :${NC}"
        echo ""
        echo -e "  ${CYAN}1.${NC} Vérifiez les erreurs ci-dessus"
        echo -e "  ${CYAN}2.${NC} Relancez le script si nécessaire :"
        echo -e "     ${DIM}./$(basename "$0")${NC}"
        echo -e "  ${CYAN}3.${NC} Consultez les logs :"
        echo -e "     ${DIM}cat setup.log${NC}"
        echo ""
        echo -e "${PURPLE}${BOLD}DÉPANNAGE RAPIDE :${NC}"
        echo ""
        echo -e "  ${WHITE}Si Oh My Posh ne fonctionne pas :${NC}"
        echo -e "     ${DIM}source ~/.bashrc${NC}"
        echo -e "     ${DIM}omp-reset${NC}"
        echo ""
        echo -e "  ${WHITE}Si Kitty n'est pas installé :${NC}"
        echo -e "     ${DIM}sudo apt install kitty  # Ubuntu/Debian${NC}"
        echo -e "     ${DIM}sudo dnf install kitty  # Fedora${NC}"
        echo ""
    fi
    
    echo -e "${DIM}${GRAY}Logs d'installation sauvegardés dans : $LOG_FILE${NC}"
    echo -e "${DIM}${GRAY}Sauvegarde .bashrc : ~/.bashrc.backup.*${NC}"
    echo ""
    
    log "Installation terminée"
}

# =============================================================================
# POINT D'ENTRÉE
# =============================================================================

# Gestion des signaux pour nettoyage en cas d'interruption
cleanup_on_exit() {
    echo ""
    print_warning "Installation interrompue"
    log "Installation interrompue par l'utilisateur"
    exit 1
}

trap cleanup_on_exit SIGINT SIGTERM

# Vérification que le script n'est pas sourcé
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
else
    print_error "Ce script doit être exécuté, pas sourcé"
    print_info "Usage: ./$(basename "${BASH_SOURCE[0]}")"
    exit 1
fi
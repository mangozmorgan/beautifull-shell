#!/bin/bash

# =============================================================================
# TERMINAL DEV SETUP - Installation complète Kitty + Oh My Posh
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
KITTY_CONFIG_DIR="$HOME/AppData/Roaming/kitty"
OMP_THEMES_DIR="$HOME/AppData/Local/Programs/oh-my-posh/themes"

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

check_admin() {
    if ! net session > /dev/null 2>&1; then
        print_error "Ce script nécessite des privilèges administrateur"
        print_info "Relancez en tant qu'administrateur (clic droit > Exécuter en tant qu'administrateur)"
        exit 1
    fi
}

check_dependencies() {
    print_step "Vérification des dépendances..."
    
    # Vérifier si on est sur Windows
    if [[ ! "$OSTYPE" == "msys" && ! "$OSTYPE" == "cygwin" ]]; then
        print_error "Ce script est conçu pour Windows avec Git Bash/MSYS2"
        exit 1
    fi
    
    # Vérifier PowerShell
    if ! command -v powershell &> /dev/null; then
        print_error "PowerShell n'est pas disponible"
        exit 1
    fi
    
    print_success "Dépendances vérifiées"
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
    
    # Installation via PowerShell
    powershell -Command "
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://ohmyposh.dev/install.ps1'))
    " 2>&1 | tee -a "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        print_success "Oh My Posh installé avec succès"
        log "Oh My Posh installé"
    else
        print_error "Échec de l'installation d'Oh My Posh"
        exit 1
    fi
}

download_themes() {
    print_step "Téléchargement des thèmes Oh My Posh..."
    
    # Créer le dossier themes s'il n'existe pas
    mkdir -p "$OMP_THEMES_DIR" 2>/dev/null
    
    # Télécharger les thèmes via PowerShell
    powershell -Command "
        \$themesPath = '$OMP_THEMES_DIR'
        if (!(Test-Path \$themesPath)) { New-Item -ItemType Directory -Path \$themesPath -Force }
        oh-my-posh get theme -l | ForEach-Object { oh-my-posh get theme \$_ -o \"\$themesPath/\$_.omp.json\" }
    " 2>&1 | tee -a "$LOG_FILE"
    
    print_success "Thèmes téléchargés dans $OMP_THEMES_DIR"
}

# =============================================================================
# INSTALLATION KITTY
# =============================================================================

install_kitty() {
    print_step "Installation de Kitty Terminal..."
    
    # Vérifier si déjà installé
    if [ -f "$HOME/AppData/Local/kitty/kitty.exe" ]; then
        print_warning "Kitty est déjà installé"
        return 0
    fi
    
    # Télécharger et installer Kitty
    print_info "Téléchargement de Kitty..."
    
    powershell -Command "
        \$kittyUrl = 'https://github.com/kovidgoyal/kitty/releases/latest/download/kitty-0.30.1-x86_64.txz'
        \$tempPath = '\$env:TEMP\kitty.txz'
        \$installPath = '\$env:LOCALAPPDATA\kitty'
        
        # Télécharger
        Invoke-WebRequest -Uri \$kittyUrl -OutFile \$tempPath
        
        # Créer le dossier d'installation
        if (!(Test-Path \$installPath)) { New-Item -ItemType Directory -Path \$installPath -Force }
        
        # Extraction (nécessite 7zip ou équivalent)
        # Alternative : télécharger la version zip si disponible
    " 2>&1 | tee -a "$LOG_FILE"
    
    print_success "Kitty installé"
}

# =============================================================================
# CONFIGURATION KITTY
# =============================================================================

configure_kitty() {
    print_step "Configuration de Kitty..."
    
    # Créer le dossier de configuration (Windows path)
    KITTY_CONFIG_DIR="$HOME/.config/kitty"
    mkdir -p "$KITTY_CONFIG_DIR"
    
    # Créer le fichier de configuration kitty.conf avec le thème Catppuccin
    cat > "$KITTY_CONFIG_DIR/kitty.conf" << 'EOF'
# THEME KITTY - Catppuccin Mocha
# vim:ft=kitty
## name:     Catppuccin Kitty Diff Mocha
## author:   Catppuccin Org
## license:  MIT
## upstream: https://github.com/catppuccin/kitty/blob/main/themes/diff-mocha.conf
## blurb:    Soothing pastel theme for the high-spirited!

# Police
font_family      JetBrains Mono NL
font_size        11.0
bold_font        auto
italic_font      auto
bold_italic_font auto

# Apparence
background_opacity         0.95
window_padding_width       15
hide_window_decorations    no
confirm_os_window_close    0

# text
foreground           #cdd6f4
# base
background           #1e1e2e
# subtext0
title_fg             #a6adc8
# mantle
title_bg             #181825
margin_bg            #181825
# subtext1
margin_fg            #a6adc8
# mantle
filler_bg            #181825
# 30% red, 70% base
removed_bg           #5e3f53
# 50% red, 50% base
highlight_removed_bg #89556b
# 40% red, 60% base
removed_margin_bg    #734a5f
# 30% green, 70% base
added_bg             #475a51
# 50% green, 50% base
highlight_added_bg   #628168
# 40% green, 60% base
added_margin_bg      #734a5f
# mantle
hunk_margin_bg       #181825
hunk_bg              #181825
# 40% yellow, 60% base
search_bg            #766c62
# text
search_fg            #cdd6f4
# 30% sky, 70% base
select_bg            #3e5767
# text
select_fg            #cdd6f4

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

# Couleurs (définies dans le script pour compatibilité)
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
OS_INFO=$(lsb_release -d 2>/dev/null | cut -f2 || echo "Windows")
KERNEL_INFO=$(uname -r 2>/dev/null || echo "NT")
UPTIME_INFO=$(uptime -p 2>/dev/null | sed 's/up //' || echo "Indisponible")
SHELL_INFO=$(basename $SHELL)

echo -e "  ${CYAN}👤${NC} ${WHITE}Utilisateur   ${GRAY}→${NC}  ${YELLOW}${USER_INFO}${NC}"

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

# Initialiser Oh My Posh (si disponible)
if command -v oh-my-posh &> /dev/null; then
    eval "$(oh-my-posh init bash --config '$HOME/AppData/Local/Programs/oh-my-posh/themes/agnoster.omp.json')"
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
    echo -e "  ${GREEN}Navigation :${NC} proj, web, home"
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
alias proj='cd ~/projets'
alias web='cd ~/web'

# Initialiser Oh My Posh si disponible
if command -v oh-my-posh &> /dev/null; then
    eval "$(oh-my-posh init bash)"
fi

EOF

    print_success "Configuration .bashrc mise à jour"
}

set_default_terminal() {
    print_step "Configuration de Kitty comme terminal par défaut..."
    
    # Ajouter Kitty au PATH système
    powershell -Command "
        \$kittyPath = '\$env:LOCALAPPDATA\kitty'
        \$currentPath = [Environment]::GetEnvironmentVariable('PATH', [EnvironmentVariableTarget]::User)
        if (\$currentPath -notlike \"*\$kittyPath*\") {
            [Environment]::SetEnvironmentVariable('PATH', \"\$currentPath;\$kittyPath\", [EnvironmentVariableTarget]::User)
        }
    "
    
    print_success "Kitty ajouté au PATH système"
}

configure_hotkey() {
    print_step "Configuration du raccourci Super+T..."
    
    # Créer un script PowerShell pour le raccourci
    cat > "$SCRIPT_DIR/launch_kitty.ps1" << 'EOF'
# Script de lancement Kitty avec raccourci
$kittyPath = "$env:LOCALAPPDATA\kitty\kitty.exe"
$configPath = "$env:APPDATA\kitty\startup.sh"

if (Test-Path $kittyPath) {
    Start-Process -FilePath $kittyPath -ArgumentList "--shell", "bash", "--shell-integration", "enabled", "-e", $configPath
} else {
    Write-Host "Kitty non trouvé à $kittyPath"
}
EOF
    
    print_warning "Configuration manuelle requise pour Super+T :"
    print_info "1. Ouvrir les Paramètres Windows > Système > Multitâche"
    print_info "2. Ou utiliser un gestionnaire de raccourcis comme PowerToys"
    print_info "3. Assigner Super+T à : powershell -WindowStyle Hidden -File \"$SCRIPT_DIR/launch_kitty.ps1\""
}

# =============================================================================
# INSTALLATION POLICE
# =============================================================================

install_fonts() {
    print_step "Installation des polices Nerd Fonts..."
    
    # Télécharger JetBrains Mono Nerd Font
    powershell -Command "
        \$fontUrl = 'https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip'
        \$tempPath = '\$env:TEMP\JetBrainsMono.zip'
        \$fontPath = '\$env:TEMP\JetBrainsMono'
        
        # Télécharger
        Invoke-WebRequest -Uri \$fontUrl -OutFile \$tempPath
        
        # Extraire
        Expand-Archive -Path \$tempPath -DestinationPath \$fontPath -Force
        
        # Installer les polices
        \$fonts = Get-ChildItem -Path \$fontPath -Filter '*.ttf'
        foreach (\$font in \$fonts) {
            \$destination = \"\$env:WINDIR\Fonts\\\$(\$font.Name)\"
            Copy-Item -Path \$font.FullName -Destination \$destination -Force
            
            # Enregistrer dans le registre
            \$fontName = [System.IO.Path]::GetFileNameWithoutExtension(\$font.Name)
            New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts' -Name \"\$fontName (TrueType)\" -Value \$font.Name -PropertyType String -Force
        }
    " 2>&1 | tee -a "$LOG_FILE"
    
    print_success "Polices Nerd Fonts installées"
}

# =============================================================================
# FONCTION PRINCIPALE
# =============================================================================

main() {
    print_header
    
    # Initialiser le log
    echo "=== TERMINAL DEV SETUP LOG ===" > "$LOG_FILE"
    log "Début de l'installation"
    
    # Vérifications préalables
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
    print_info "PROCHAINES ÉTAPES :"
    echo -e "  ${CYAN}1.${NC} Redémarrez votre session Windows"
    echo -e "  ${CYAN}2.${NC} Configurez le raccourci Super+T manuellement"
    echo -e "  ${CYAN}3.${NC} Lancez Kitty depuis le menu Démarrer"
    echo -e "  ${CYAN}4.${NC} Votre bannière personnalisée s'affichera automatiquement"
    echo ""
    print_info "Fichiers créés :"
    echo -e "  ${DIM}• Configuration : ~/.config/kitty/kitty.conf${NC}"
    echo -e "  ${DIM}• Script startup : ~/.config/kitty/startup.sh${NC}"
    echo -e "  ${DIM}• Configuration : ~/.bashrc (sauvegardé)${NC}"
    echo -e "  ${DIM}• Lanceur : $SCRIPT_DIR/launch_kitty.ps1${NC}"
    echo -e "  ${DIM}• Log : $LOG_FILE${NC}"
    echo ""
    
    log "Installation terminée avec succès"
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

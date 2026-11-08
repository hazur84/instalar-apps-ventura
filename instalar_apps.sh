#!/bin/bash
# =============================================================================
#  instalar_apps.sh — instala tus apps en un macOS Ventura limpio
#  (pensado para la Dell OptiPlex 7050 con Intel; corre con el bash 3.2 de macOS)
#
#  Córrelo en Terminal con TU usuario (NO con sudo) y conectado a internet:
#     bash instalar_apps.sh          instala todo lo que falte
#     bash instalar_apps.sh lista    solo dice qué ya está y qué falta
#
#  Pide tu contraseña una vez. Se puede volver a correr: salta lo instalado.
#  Al final deja Resultado-instalar-apps.txt en tu Escritorio.
#
#  Para bajarlo de GitHub y correrlo en una Mac recién instalada:
#     curl -fsSLO https://raw.githubusercontent.com/hazur84/instalar-apps-ventura/main/instalar_apps.sh
#     bash instalar_apps.sh
# =============================================================================

# Con «curl ... | bash», bash lee el script de la entrada y las preguntas se
# comerían sus líneas: en ese caso pide bajarlo primero.
if [ ! -t 0 ]; then
  case "${0##*/}" in bash|-bash|sh|-sh)
    echo "Bájalo primero y luego córrelo:"
    echo "  curl -fsSLO https://raw.githubusercontent.com/hazur84/instalar-apps-ventura/main/instalar_apps.sh"
    echo "  bash instalar_apps.sh"
    exit 1;;
  esac
fi

# -----------------------------------------------------------------------------
# 1) Por Homebrew:   cask | nombre en Aplicaciones
#    Homebrew escoge solo la última versión que corre en Ventura
#    (Office 16.101, OmniGraffle 7.25.3...). Para no instalar una, ponle #
#    al principio; para instalar una opcional, quítale el #.
# -----------------------------------------------------------------------------
CASKS='
adobe-creative-cloud  | Adobe Creative Cloud
balenaetcher          | balenaEtcher
brave-browser         | Brave Browser
drawio                | draw.io
free-download-manager | Free Download Manager
freecad               | FreeCAD
istat-menus           | iStat Menus
microsoft-edge        | Microsoft Edge
microsoft-word        | Microsoft Word
microsoft-excel       | Microsoft Excel
microsoft-powerpoint  | Microsoft PowerPoint
omnigraffle           | OmniGraffle
proton-pass           | Proton Pass
spotify               | Spotify
sublime-text          | Sublime Text
visual-studio-code    | Visual Studio Code
whatsapp              | WhatsApp
# Opcionales (estaban en tu otro Ventura):
# google-chrome       | Google Chrome
# google-drive        | Google Drive
# adobe-acrobat-pro   | Adobe Acrobat DC
# microsoft-outlook   | Microsoft Outlook
# paragon-extfs       | extFS for Mac
'

# -----------------------------------------------------------------------------
# 2) Descarga directa, con versión fija y huella SHA-256:
#    nombre | tipo | url | sha256 | cask para macOS más nuevo | desde macOS
#    - AppCleaner 3.7 pide macOS 15 y Rectangle 2.0 pide macOS 14: en Ventura
#      van AppCleaner 3.6.8 y Rectangle 1.100 (en macOS nuevos, el cask).
#    - Homebrew retiró LyX (no pasa Gatekeeper) y OCAT no está en Homebrew.
# -----------------------------------------------------------------------------
DIRECTAS='
AppCleaner       | zip | https://freemacsoft.net/downloads/AppCleaner_3.6.8.zip | e012f729442473c20e7cce334b00182521e4b6672ea681b34931b180feb3d6be | appcleaner | 15
Rectangle        | dmg | https://github.com/rxhanson/Rectangle/releases/download/v1.100/Rectangle1.100.dmg | 5cfbe9b68a558458302c5305cb7060491f68029338e2a4561c54a2981eb8622f | rectangle | 14
LyX              | dmg | https://ftp.lip6.fr/pub/lyx/bin/2.5.2/LyX-2.5.2+qt6-x86_64-arm64-cocoa.dmg | 329a4f45a04f2585eac7b44722f068fe24722481dcc8521dc284c02161fb2855 | |
OCAuxiliaryTools | dmg | https://github.com/ic005k/OCAuxiliaryTools/releases/download/20250001/OCAT_Mac.dmg | 81526bda56348a25de119ce3cacf763e15bd8abc58c2ed5fb625ca698fd092fb | |
'

# -----------------------------------------------------------------------------
# 3) MacTeX completo (TeXShop, BibDesk, LaTeXiT...; ~7 GB) directo de CTAN,
#    verificado con su SHA-512. El cask de Homebrew obligaría a compilar
#    Ghostscript en Ventura (horas).
# -----------------------------------------------------------------------------
MACTEX=1

# -----------------------------------------------------------------------------
# 4) App Store (con tu Apple ID):   nombre | id
#    Las versiones actuales piden macOS 26; la App Store te da la última
#    compatible con Ventura porque ya las tienes en tu cuenta.
# -----------------------------------------------------------------------------
TIENDA='
Keynote    | 409183694
Pages      | 409201541
Numbers    | 409203825
iMovie     | 408981434
IP Scanner | 6443819966
'

# ----------------------------- configuración ---------------------------------
APPS="${APPS_DIR:-/Applications}"
TEXBIN="${TEXBIN:-/Library/TeX/texbin}"
MACTEX_URL="${MACTEX_URL:-https://mirror.ctan.org/systems/mac/mactex/MacTeX.pkg}"
DESC="${DESC_DIR:-$HOME/Downloads/instalar-apps-descargas}"
MIN_GB="${MIN_GB:-40}"
FECHA=$(date +%Y%m%d-%H%M%S)
LOG="$HOME/Library/Logs/instalar-apps-$FECHA.log"
RESUMEN="$HOME/Desktop/Resultado-instalar-apps.txt"
MODO="${1:-instalar}"
MAJOR=$(sw_vers -productVersion | cut -d. -f1)
export HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_ENV_HINTS=1

trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; s="${s%"${s##*[![:space:]]}"}"; printf '%s' "$s"; }
existe() { [ -e "$APPS/$1.app" ] || [ -e "$APPS/$1" ]; }
anota() { printf '%s|%s|%s\n' "$1" "$2" "$3" >> "$RES"; }
version_de() { local v; v=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APPS/$1.app/Contents/Info.plist" 2>/dev/null); case "$v" in *x*) v="";; esac; printf '%s' "$v"; }

# En macOS nuevos, las directas que tienen cask se pasan a Homebrew.
EXTRA=""
DIRECTAS_OK=""
while IFS='|' read -r -u 3 n t u s alt desde; do
  n=$(trim "$n"); alt=$(trim "$alt"); desde=$(trim "$desde")
  case "$n" in ''|\#*) continue;; esac
  if [ -n "$alt" ] && [ "$MAJOR" -ge "$desde" ]; then
    EXTRA="$EXTRA
$alt | $n"
  else
    DIRECTAS_OK="$DIRECTAS_OK
$n|$(trim "$t")|$(trim "$u")|$(trim "$s")"
  fi
done 3<<< "$DIRECTAS"
CASKS="$CASKS$EXTRA"

# ------------------------------- modo lista ----------------------------------
if [ "$MODO" = lista ]; then
  echo "macOS $(sw_vers -productVersion) ($(uname -m)) — qué hay en $APPS"
  ver() { if existe "$1"; then printf '  ya está  %-24s %s\n' "$1" "$2"; else printf '  FALTA    %-24s %s\n' "$1" "$2"; fi; }
  while IFS='|' read -r -u 3 c n; do c=$(trim "$c"); n=$(trim "$n"); case "$c" in ''|\#*) continue;; esac; ver "$n" "(Homebrew: $c)"; done 3<<< "$CASKS"
  while IFS='|' read -r -u 3 n t u s; do [ -z "$n" ] && continue; ver "$n" "(descarga directa)"; done 3<<< "$DIRECTAS_OK"
  [ "$MACTEX" = 1 ] && { if [ -x "$TEXBIN/pdflatex" ]; then echo "  ya está  MacTeX"; else echo "  FALTA    MacTeX                   (CTAN, ~7 GB)"; fi; }
  while IFS='|' read -r -u 3 n id; do n=$(trim "$n"); case "$n" in ''|\#*) continue;; esac; ver "$n" "(App Store)"; done 3<<< "$TIENDA"
  exit 0
fi
[ "$MODO" = instalar ] || { echo "Uso: bash $0 [lista]"; exit 1; }

# ------------------------------- revisiones ----------------------------------
if [ "$(id -u)" = 0 ]; then
  echo "ALTO: córrelo SIN sudo (Homebrew no acepta root). El script te pide la contraseña."
  exit 1
fi
echo "macOS $(sw_vers -productVersion) en $(uname -m)"
[ "$MAJOR" = 13 ] || echo "Aviso: este script está pensado para Ventura (13); sigo de todos modos."
curl -sI --max-time 20 https://formulae.brew.sh >/dev/null 2>&1 || { echo "ALTO: no hay internet (no llego a formulae.brew.sh)."; exit 1; }
LIBRE=$(df -g "$HOME" | awk 'NR==2{print $4}')
if [ "${LIBRE:-0}" -lt "$MIN_GB" ]; then
  printf 'Solo hay %s GB libres y se ocupan unos %s. ¿Sigo? [s/N] ' "$LIBRE" "$MIN_GB"
  read -r r; case "$r" in s|S) ;; *) exit 1;; esac
fi
mkdir -p "$DESC" "$HOME/Library/Logs" || exit 1
RES=$(mktemp -t instalar-apps) || exit 1
SALIDA=$(mktemp -t instalar-apps-salida) || exit 1
exec > >(tee -a "$LOG") 2>&1
trap 'echo; echo "Interrumpido. Vuelve a correrlo: sigue con lo que falte."; exit 130' INT TERM

echo "== Tu contraseña de esta Mac (no se ve al escribirla) =="
sudo -v || exit 1
( while kill -0 $$ 2>/dev/null; do sudo -n true 2>/dev/null; sleep 45; done ) &
caffeinate -dimsu -w $$ >/dev/null 2>&1 &

# ------------------------------- App Store -----------------------------------
faltan_tienda() {
  local f="" n id
  while IFS='|' read -r -u 3 n id; do
    n=$(trim "$n"); case "$n" in ''|\#*) continue;; esac
    existe "$n" || f="$f$n, "
  done 3<<< "$TIENDA"
  printf '%s' "${f%, }"
}
TIENDA_ANTES=$(faltan_tienda)
pedir_tienda() {
  local f; f=$(faltan_tienda)
  [ -n "$f" ] || return 0
  echo
  echo "== App Store: faltan $f =="
  open "macappstore://showPurchasesPage" 2>/dev/null || open -a "App Store"
  echo "  1. Si te lo pide, inicia sesión con tu Apple ID."
  echo "  2. Abajo a la izquierda, en tu nombre, salen tus apps compradas:"
  echo "     dale a la nube junto a: $f"
  echo "  3. Si dice que requiere un macOS más nuevo, acepta"
  echo "     «Descargar la última versión compatible»."
  echo "  Se bajan solas mientras sigo con lo demás."
  read -r -t "${ESPERA_TIENDA:-120}" -p "  Enter cuando las hayas pedido (si no, en 2 min sigo solo)... " _ || echo
}
pedir_tienda

# --------------------------- descargas directas ------------------------------
descargar() { # url archivo
  curl -fL -# --retry 3 --retry-delay 5 --connect-timeout 30 -C - -o "$2" "$1" || { rm -f "$2"; curl -fL -# --retry 3 --retry-delay 5 -o "$2" "$1"; }
}
instalar_directa() { # nombre tipo url sha256
  local n="$1" t="$2" u="$3" s="$4" f m app tmp
  f="$DESC/$(basename "$u")"
  if ! echo "$s  $f" | shasum -a 256 -c - >/dev/null 2>&1; then
    descargar "$u" "$f" || { echo "No se pudo descargar $u"; return 1; }
    echo "$s  $f" | shasum -a 256 -c - >/dev/null 2>&1 || { echo "La huella SHA-256 de $f no coincide; lo borro."; rm -f "$f"; return 1; }
  fi
  tmp=$(mktemp -d -t instalar-apps-x) || return 1
  case "$t" in
    zip) ditto -x -k "$f" "$tmp" && app=$(find "$tmp" -maxdepth 2 -name "$n.app" -type d | head -1) ;;
    dmg) m="$tmp/mnt"; mkdir -p "$m"
         yes | hdiutil attach -nobrowse -readonly -noverify -mountpoint "$m" "$f" >/dev/null && app="$m/$n.app" ;;
  esac
  if [ -d "$app" ]; then
    ditto "$app" "$APPS/$n.app" 2>/dev/null || sudo ditto "$app" "$APPS/$n.app"
    xattr -dr com.apple.quarantine "$APPS/$n.app" 2>/dev/null
  fi
  [ "$t" = dmg ] && hdiutil detach -quiet "$m" 2>/dev/null
  rm -rf "$tmp"
  [ -d "$APPS/$n.app" ] && rm -f "$f"
  [ -d "$APPS/$n.app" ]
}
while IFS='|' read -r -u 3 n t u s; do
  [ -z "$n" ] && continue
  if existe "$n"; then anota "YA ESTABA" "$n" "$(version_de "$n")"; continue; fi
  echo; echo "== $n (descarga directa) =="
  if instalar_directa "$n" "$t" "$u" "$s"; then anota "LISTA" "$n" "$(version_de "$n")"
  else anota "ERROR" "$n" "ver la bitácora"; fi
done 3<<< "$DIRECTAS_OK"

# -------------------------------- Homebrew -----------------------------------
asegurar_brew() {
  local b
  if ! command -v brew >/dev/null 2>&1; then
    for b in /usr/local/bin/brew /opt/homebrew/bin/brew; do [ -x "$b" ] && eval "$("$b" shellenv)" && break; done
  fi
  if ! command -v brew >/dev/null 2>&1; then
    echo; echo "== Instalando Homebrew y las Command Line Tools de Apple (10 a 20 min) =="
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/null
    for b in /usr/local/bin/brew /opt/homebrew/bin/brew; do [ -x "$b" ] && eval "$("$b" shellenv)" && break; done
  fi
  command -v brew >/dev/null 2>&1 || return 1
  brew analytics off >/dev/null 2>&1
  b="$(brew --prefix)/bin/brew"
  if [ "$(brew --prefix)" != /usr/local ] && ! grep -qs 'brew shellenv' "$HOME/.zprofile"; then
    echo "eval \"\$($b shellenv)\"" >> "$HOME/.zprofile"
  fi
  return 0
}
HAY_BREW=""
asegurar_brew && HAY_BREW=1

while IFS='|' read -r -u 3 c n; do
  c=$(trim "$c"); n=$(trim "$n")
  case "$c" in ''|\#*) continue;; esac
  if [ -n "$HAY_BREW" ] && brew list --cask "$c" >/dev/null 2>&1; then anota "YA ESTABA" "$n" "$(brew list --cask --versions "$c" | awk '{print $2}')"; continue; fi
  if existe "$n"; then anota "YA ESTABA" "$n" "$(version_de "$n")"; continue; fi
  if [ -z "$HAY_BREW" ]; then anota "ERROR" "$n" "no se pudo instalar Homebrew"; continue; fi
  echo; echo "== $n (Homebrew: $c) =="
  hecho=""
  for intento in 1 2; do
    brew install --cask "$c" 2>&1 | tee "$SALIDA"
    if [ "${PIPESTATUS[0]}" = 0 ]; then hecho=1; break; fi
    grep -qi 'already an App at\|is already installed' "$SALIDA" && { hecho=ya; break; }
    grep -qi 'requires macOS\|has been disabled\|No Cask with this name' "$SALIDA" && break
    [ "$intento" = 1 ] && { echo "Reintento en 15 s..."; sleep 15; }
  done
  case "$hecho" in
    1)  anota "LISTA" "$n" "$(brew list --cask --versions "$c" | awk '{print $2}')" ;;
    ya) anota "YA ESTABA" "$n" "" ;;
    *)  anota "ERROR" "$n" "$(grep -i 'error' "$SALIDA" | tail -1 | sed 's/^Error: //' | cut -c1-70)" ;;
  esac
done 3<<< "$CASKS"

# --------------------------------- MacTeX ------------------------------------
instalar_mactex() {
  local real base sha f
  real=$(curl -sIL -o /dev/null -w '%{url_effective}' --max-time 60 "$MACTEX_URL")
  [ -n "$real" ] || real="$MACTEX_URL"
  base="${real%/*}"
  sha=$(curl -fsL --max-time 60 "$base/MacTeX.pkg.sha512" | awk '{print $1}')
  [ -n "$sha" ] || { echo "No pude leer la huella de MacTeX."; return 1; }
  f="$DESC/MacTeX.pkg"
  if ! echo "$sha  $f" | shasum -a 512 -c - >/dev/null 2>&1; then
    echo "Descargando MacTeX de $base (unos 7 GB; se reanuda si se corta)..."
    descargar "$base/MacTeX.pkg" "$f"
    if ! echo "$sha  $f" | shasum -a 512 -c - >/dev/null 2>&1; then
      echo "La huella no coincide; lo bajo de nuevo desde cero."
      rm -f "$f"; descargar "$base/MacTeX.pkg" "$f"
      echo "$sha  $f" | shasum -a 512 -c - >/dev/null 2>&1 || { echo "La huella de MacTeX sigue sin coincidir."; return 1; }
    fi
  fi
  echo "Instalando MacTeX (unos 10 min)..."
  sudo installer -pkg "$f" -target / || return 1
  [ -x "$TEXBIN/pdflatex" ] && rm -f "$f"
  [ -x "$TEXBIN/pdflatex" ]
}
if [ "$MACTEX" = 1 ]; then
  if [ -x "$TEXBIN/pdflatex" ]; then anota "YA ESTABA" "MacTeX" ""
  else
    echo; echo "== MacTeX (CTAN) =="
    if instalar_mactex; then anota "LISTA" "MacTeX" "$("$TEXBIN/pdflatex" --version 2>/dev/null | sed -n '1s/.*(\(TeX Live [0-9]*\).*/\1/p')"
    else anota "ERROR" "MacTeX" "ver la bitácora"; fi
  fi
fi

# -------------------------- App Store (revisión) -----------------------------
F=$(faltan_tienda)
if [ -n "$F" ]; then
  echo; echo "Todavía no veo en Aplicaciones: $F"
  read -r -t "${ESPERA_TIENDA:-120}" -p "Si siguen bajando, espera y pulsa Enter (2 min y cierro)... " _ || echo
fi
while IFS='|' read -r -u 3 n id; do
  n=$(trim "$n"); case "$n" in ''|\#*) continue;; esac
  if existe "$n"; then
    case ", $TIENDA_ANTES," in *", $n,"*) anota "LISTA" "$n" "$(version_de "$n") (App Store)";; *) anota "YA ESTABA" "$n" "$(version_de "$n")";; esac
  else anota "PENDIENTE" "$n" "App Store: cuenta > Comprado > nube"; fi
done 3<<< "$TIENDA"

# ------------------------------- limpieza ------------------------------------
[ -n "$HAY_BREW" ] && brew cleanup -s >/dev/null 2>&1
rmdir "$DESC" 2>/dev/null

# -------------------------------- resumen ------------------------------------
tiene() { grep -q "^LISTA|$1|" "$RES"; }
{
  echo "Resultado de instalar_apps.sh — $(date '+%d-%m-%Y %H:%M') — macOS $(sw_vers -productVersion)"
  echo
  while IFS='|' read -r e n d; do printf '  %-10s %-24s %s\n' "$e" "$n" "$d"; done < "$RES"
  echo
  echo "Qué sigue:"
  tiene "Microsoft Word" && echo "  - Office: abre Word y entra con tu cuenta de Microsoft para activarlo. La 16.101 es la última que corre en Ventura."
  tiene "Adobe Creative Cloud" && echo "  - Adobe: abre Creative Cloud, inicia sesión e instala desde ahí Photoshop, Illustrator, etc."
  echo "  - Rectangle e iStat Menus piden permiso la primera vez: Configuración del Sistema > Privacidad y seguridad > Accesibilidad."
  echo "  - iStat Menus, OmniGraffle y Sublime Text: registra tu licencia (si no, quedan a prueba)."
  tiene "MacTeX" && echo "  - LyX: ábrelo con MacTeX ya instalado; si lo abriste antes, Herramientas > Reconfigurar y reinicia LyX."
  tiene "MacTeX" && echo "  - Abre una Terminal nueva para que encuentre los comandos de TeX."
  grep -q '^ERROR' "$RES" && echo "  - Lo que dice ERROR: vuelve a correr el script; si sigue, revisa la bitácora."
  echo
  echo "Bitácora completa: $LOG"
} > "$RESUMEN"
echo; echo "================================================================"
cat "$RESUMEN"
echo "(Este resumen quedó en tu Escritorio: Resultado-instalar-apps.txt)"
rm -f "$RES" "$SALIDA"
sleep 1

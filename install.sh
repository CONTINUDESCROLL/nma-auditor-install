#!/bin/bash
# =============================================================================
#  NMA AUDITOR — installation sur un Mac
#
#  Script PUBLIC, sans secret : il demande le jeton d'accès au dépôt privé.
#  Tout s'installe dans le dossier personnel, sans mot de passe administrateur.
#  Reprend là où ça s'est arrêté si on le relance. « install.sh --verifier »
#  vérifie une installation sans rien modifier.
#
#  Même socle que Derush Studio (Node, ffmpeg, environnement Python, modèle
#  Whisper) : si Derush Studio est déjà installé, ces étapes sont instantanées.
# =============================================================================
set -u
export GIT_TERMINAL_PROMPT=0
export GIT_ASKPASS=/usr/bin/true

DEPOT="CONTINUDESCROLL/nma-auditor"
BIN="$HOME/.local/bin"
VENV="$HOME/.local/opt/whisper-env"
NODE_V="v22.23.1"
MARQUEUR="$HOME/.nma-auditor/emplacement"
ETAPES=6

JETON=""; export JETON
armer_git() { JETON="$1"; ASKPASS=$(mktemp); chmod 700 "$ASKPASS"
  printf '#!/bin/sh\ncase "$1" in *sername*) echo x-access-token ;; *) printf "%%s" "$JETON" ;; esac\n' > "$ASKPASS"
  export GIT_ASKPASS="$ASKPASS"; }
ranger_jeton() {                      # $1 = dossier de l'application : pour les mises à jour depuis l'app
  [ -d "$1/.git" ] || return 0
  git -C "$1" remote set-url origin "https://github.com/$DEPOT.git" 2>/dev/null
  printf 'https://x-access-token:%s@github.com\n' "$JETON" > "$1/.git/.identifiants"
  chmod 600 "$1/.git/.identifiants"
  git -C "$1" config credential.helper "store --file=$1/.git/.identifiants"
  chmod 600 "$1/.git/config" 2>/dev/null; }

as_txt() { printf '%s' "${1:-}" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }
rouge() { printf "\033[31m%s\033[0m\n" "$*"; }
vert()  { printf "\033[32m  ✓ %s\033[0m\n" "$*"; }
gris()  { printf "\033[90m    %s\033[0m\n" "$*"; }
etape() { printf "\n\033[1m[%s/%s] %s\033[0m\n" "$1" "$ETAPES" "$2"; }
fatal() { echo ""; rouge "  ✗ $1"; [ $# -gt 1 ] && gris "$2"
          osascript -e "display alert \"Installation interrompue\" message \"$(as_txt "$1")\"" >/dev/null 2>&1
          echo ""; exit 1; }

# ----------------------------------------------------------------------------- vérifier
PROBLEMES=0; SOUCIS=""
verifier() {
  local A="$1" M=0 f
  PROBLEMES=0; SOUCIS=""
  souci() { PROBLEMES=$((PROBLEMES+1)); SOUCIS="$SOUCIS
  · $1"; rouge "  ✗ $1"; }
  if [ -s "$BIN/node" ] && "$BIN/node" --version 2>/dev/null | grep -q '^v[0-9]'; then vert "Node $("$BIN/node" --version)"; else souci "Node absent ou inutilisable"; fi
  for o in ffmpeg ffprobe; do if [ -s "$BIN/$o" ] && "$BIN/$o" -version >/dev/null 2>&1; then vert "$o"; else souci "$o absent"; fi; done
  if [ -s "$BIN/yt-dlp" ] && "$BIN/yt-dlp" --version >/dev/null 2>&1; then vert "yt-dlp $("$BIN/yt-dlp" --version)"; else souci "yt-dlp absent"; fi
  if [ -s "$VENV/bin/python" ] && [ "$("$VENV/bin/python" -c 'print(42)' 2>/dev/null)" = "42" ]; then vert "Python"; else souci "environnement Python cassé"; fi
  if "$VENV/bin/python" -c 'import faster_whisper,anthropic,av' >/dev/null 2>&1; then vert "bibliothèques"; else souci "bibliothèques manquantes"; fi
  for f in "$HOME/.cache/huggingface/hub/models--Systran--faster-whisper-medium"/snapshots/*/model.bin; do [ -f "$f" ] && M=$(wc -c < "$f" 2>/dev/null || echo 0); done
  if [ "$M" -gt 1000000000 ]; then vert "modèle de transcription"; else souci "modèle de transcription incomplet"; fi
  [ -f "$A/server.mjs" ] && [ -f "$A/public/index.html" ] && [ -f "$A/pipeline/collect.py" ] && vert "fichiers de l'application" || souci "fichiers de l'application manquants"
  [ -d "$A/.git" ] && vert "mises à jour possibles depuis l'application" || souci "pas de dépôt git : les mises à jour en un clic ne marcheront pas"
  [ -s "$A/Lancer NMA Auditor.command" ] && vert "lanceur" || souci "lanceur absent"
  return 0
}
if [ "${1:-}" = "--verifier" ]; then
  CIBLE="$(cat "$MARQUEUR" 2>/dev/null)"; [ -n "$CIBLE" ] && [ -f "$CIBLE/server.mjs" ] || CIBLE="$HOME/NMA Auditor"
  echo ""; printf "\033[1m  VÉRIFICATION DE L'INSTALLATION\033[0m\n"; gris "$CIBLE"; echo ""
  verifier "$CIBLE"; echo ""
  if [ "$PROBLEMES" -gt 0 ]; then rouge "  $PROBLEMES point(s) à régler :$SOUCIS"; echo ""; echo "  Relance la commande d'installation : elle reprend là où ça a échoué."; echo ""; exit 1; fi
  vert "tout est en ordre"; echo ""; exit 0
fi

clear 2>/dev/null
cat <<'BAN'

  ╭──────────────────────────────────────────────╮
  │                                              │
  │            NMA  AUDITOR                      │
  │            installation                      │
  │                                              │
  ╰──────────────────────────────────────────────╯

  Cette fenêtre affiche chaque étape.
  Compte 5 minutes si Derush Studio est déjà installé,
  15 à 25 minutes sinon (le modèle de transcription fait 1,4 Go).

  À SAVOIR :
  · aucun mot de passe administrateur ne sera demandé
  · tout s'installe dans ton dossier personnel
  · les clés (Anthropic, Apify, Cloudflare) se saisissent ensuite
    dans l'application, bouton Réglages

BAN

# ----------------------------------------------------------------------------- 1. le Mac
etape 1 "Vérification de ton Mac"
[ "$(uname)" = "Darwin" ] || fatal "Cet outil fonctionne uniquement sur Mac."
ARCH=$(uname -m); [ "$ARCH" = "x86_64" ] && [ "$(sysctl -n sysctl.proc_translated 2>/dev/null)" = "1" ] && ARCH="arm64"
case "$ARCH" in arm64) NODE_ARCH="darwin-arm64"; FF_ARCH="arm64"; PUCE="Apple Silicon" ;; x86_64) NODE_ARCH="darwin-x64"; FF_ARCH="amd64"; PUCE="Intel" ;; *) fatal "Architecture inconnue : $ARCH" ;; esac
vert "Mac $PUCE · macOS $(sw_vers -productVersion)"
if ! xcode-select -p >/dev/null 2>&1; then
  echo ""; echo "  macOS doit d'abord installer ses outils de développement."; echo "  Une fenêtre va s'ouvrir : clique sur « Installer », attends la fin, puis relance la même commande."; echo ""
  xcode-select --install 2>/dev/null; exit 0
fi
vert "outils Apple présents"

# ----------------------------------------------------------------------------- 2. le jeton
etape 2 "Accès à l'application"
demander_jeton() { local msg="Colle ici le jeton d'accès que Tom t'a envoyé."; [ -n "${1:-}" ] && msg="⚠ $1

$msg"
  osascript <<AS 2>/dev/null
try
  set r to display dialog "$(as_txt "$msg")" with title "NMA Auditor — installation" default answer "" with hidden answer buttons {"Annuler","Continuer"} default button "Continuer"
  return text returned of r
on error
  return "@@ANNULE@@"
end try
AS
}
JETON="${1:-}"; [ -n "$JETON" ] && gris "jeton fourni par la commande"; ERREUR=""
while true; do
  if [ -z "$JETON" ]; then echo "  Une fenêtre te demande le jeton fourni par Tom."; JETON=$(demander_jeton "$ERREUR")
    [ "$JETON" = "@@ANNULE@@" ] && fatal "Installation annulée." "Relance la commande quand tu auras le jeton."
    if [ -z "$JETON" ]; then ERREUR="Le champ était vide."; rouge "  ✗ $ERREUR"; continue; fi; fi
  JETON=$(printf '%s' "$JETON" | tr -d '[:space:]'); gris "vérification… (jeton de ${#JETON} caractères)"
  CFG=$(mktemp); chmod 600 "$CFG"; printf 'header = "Authorization: Bearer %s"\n' "$JETON" > "$CFG"
  CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 20 --config "$CFG" "https://api.github.com/repos/$DEPOT"); rm -f "$CFG"
  case "$CODE" in
    200) vert "jeton valide"; armer_git "$JETON"; break ;;
    401) ERREUR="Jeton refusé : incomplet, mal collé ou expiré." ;;
    403) ERREUR="Jeton sans autorisation : il lui manque « Contents : Read-only » sur ce dépôt." ;;
    404) ERREUR="Ce jeton ne voit pas l'application : vérifie qu'il donne accès au dépôt nma-auditor." ;;
    000) ERREUR="Pas de connexion internet." ;;
    *)   ERREUR="Réponse inattendue de GitHub (code $CODE)." ;;
  esac
  rouge "  ✗ $ERREUR"; gris "on réessaie — la fenêtre va revenir"; JETON=""
done

# ----------------------------------------------------------------------------- 3. emplacement
etape 3 "Où installer l'application"
mkdir -p "$HOME/.nma-auditor"
ANCIEN="$(cat "$MARQUEUR" 2>/dev/null)"; [ -n "$ANCIEN" ] && [ ! -f "$ANCIEN/server.mjs" ] && ANCIEN=""
[ -z "$ANCIEN" ] && [ -f "$HOME/NMA Auditor/server.mjs" ] && ANCIEN="$HOME/NMA Auditor"
if [ -n "$ANCIEN" ]; then
  APP="$ANCIEN"; vert "installation existante : mise à jour sur place ($APP)"; gris "tes audits (dossier projects) sont conservés"
else
  APP="$HOME/NMA Auditor"; mkdir -p "$APP" 2>/dev/null || fatal "Impossible d'écrire dans « $APP »."
  vert "$APP"
fi
printf '%s' "$APP" > "$MARQUEUR"

# ----------------------------------------------------------------------------- 4. outils
telecharger() { for essai in 1 2 3 4 5; do curl -sfL -C - --connect-timeout 20 --speed-limit 2048 --speed-time 60 -o "$2" "$1" && [ -s "$2" ] && return 0; [ "$essai" -lt 5 ] && gris "connexion interrompue — reprise $essai/4…"; sleep 3; done; return 1; }
etape 4 "Outils vidéo, Node et yt-dlp"
mkdir -p "$BIN"
noeud_ok(){ [ -s "$BIN/node" ] && "$BIN/node" --version 2>/dev/null | grep -q '^v[0-9]'; }
if noeud_ok; then gris "Node déjà présent ($("$BIN/node" --version))"; else
  gris "téléchargement de Node… (~30 Mo)"; T=$(mktemp -d)
  telecharger "https://nodejs.org/dist/$NODE_V/node-$NODE_V-$NODE_ARCH.tar.gz" "$T/n.tgz" || fatal "Téléchargement de Node impossible." "Vérifie ta connexion."
  tar -xzf "$T/n.tgz" -C "$T" 2>/dev/null || fatal "Archive Node illisible." "Relance la commande."
  cp "$T"/node-*/bin/node "$BIN/node" && chmod +x "$BIN/node"; rm -rf "$T"; noeud_ok || fatal "Node n'a pas pu être installé."; vert "Node installé ($("$BIN/node" --version))"; fi
for outil in ffmpeg ffprobe; do
  if [ -s "$BIN/$outil" ] && "$BIN/$outil" -version >/dev/null 2>&1; then gris "$outil déjà présent"; else
    gris "téléchargement de ${outil}… (~60 Mo)"; T=$(mktemp -d)
    telecharger "https://ffmpeg.martin-riedl.de/redirect/latest/macos/$FF_ARCH/release/$outil.zip" "$T/o.zip" || fatal "Téléchargement de $outil impossible." "Réessaie dans quelques minutes."
    unzip -qo "$T/o.zip" -d "$T"; f=$(find "$T" -name "$outil" -type f | head -1); [ -n "$f" ] && cp "$f" "$BIN/$outil" && chmod +x "$BIN/$outil"; rm -rf "$T"
    { [ -s "$BIN/$outil" ] && "$BIN/$outil" -version >/dev/null 2>&1; } || fatal "$outil n'a pas pu être installé."; vert "$outil installé"; fi
done
if [ -s "$BIN/yt-dlp" ] && "$BIN/yt-dlp" --version >/dev/null 2>&1; then gris "yt-dlp déjà présent ($("$BIN/yt-dlp" --version))"; else
  gris "téléchargement de yt-dlp… (~35 Mo)"
  telecharger "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos" "$BIN/yt-dlp" || fatal "Téléchargement de yt-dlp impossible."
  chmod +x "$BIN/yt-dlp"; "$BIN/yt-dlp" --version >/dev/null 2>&1 || fatal "yt-dlp n'a pas pu être installé."; vert "yt-dlp installé"; fi

# ----------------------------------------------------------------------------- 5. Python
etape 5 "Moteur de transcription"
python_ok(){ [ -s "$VENV/bin/python" ] && [ "$("$VENV/bin/python" -c 'print(42)' 2>/dev/null)" = "42" ]; }
if python_ok; then gris "environnement Python déjà présent"; else
  [ -e "$VENV" ] && { gris "environnement Python inutilisable — reconstruction…"; rm -rf "$VENV"; }
  gris "création de l'environnement Python…"; mkdir -p "$(dirname "$VENV")"
  /usr/bin/python3 -m venv "$VENV" || fatal "Création de l'environnement Python impossible."; python_ok || fatal "L'environnement Python créé ne fonctionne pas."; fi
gris "installation des bibliothèques… (2 à 5 minutes la première fois)"
"$VENV/bin/pip" install --quiet --upgrade pip 2>/dev/null
"$VENV/bin/pip" install --quiet "faster-whisper==1.2.1" "anthropic==0.117.0" "numpy==2.0.2" "av==15.1.0" "ctranslate2==4.8.1" \
  || fatal "Installation des bibliothèques échouée." "Vérifie ta connexion et relance."
vert "bibliothèques prêtes"
MODELE_OK=non
for f in "$HOME/.cache/huggingface/hub/models--Systran--faster-whisper-medium"/snapshots/*/model.bin; do [ -f "$f" ] && [ "$(wc -c < "$f" 2>/dev/null || echo 0)" -gt 1000000000 ] && MODELE_OK=oui; done
if [ "$MODELE_OK" = oui ]; then gris "modèle de transcription déjà téléchargé"; else
  gris "téléchargement du modèle de transcription… (1,4 Go, 5 à 15 minutes, rien ne s'affiche pendant ce temps)"
  if "$VENV/bin/python" - <<'PY' 2>/dev/null
from faster_whisper import WhisperModel
WhisperModel("medium", device="cpu", compute_type="int8")
PY
  then vert "modèle prêt"; else gris "échec — il se téléchargera tout seul à la première transcription"; fi
fi

# ----------------------------------------------------------------------------- 6. l'application
etape 6 "Application"
if [ -d "$APP/.git" ]; then
  ranger_jeton "$APP"
  if git -C "$APP" fetch --quiet origin && git -C "$APP" reset --hard --quiet origin/main; then chmod 600 "$APP/.git/config"; vert "mise à jour effectuée"
  else chmod 600 "$APP/.git/config"; fatal "La mise à jour n'a pas pu être récupérée." "Vérifie ta connexion ou demande un nouveau jeton. L'application existante n'a pas été modifiée."; fi
else
  RESTE=$(ls -A "$APP" 2>/dev/null | grep -v -e '^\.DS_Store$' -e '^\._' || true)
  [ -z "$RESTE" ] || fatal "« $APP » n'est pas vide." "Vide ce dossier ou supprime-le, puis relance."
  gris "téléchargement de l'application…"
  git clone --quiet "https://github.com/$DEPOT.git" "$APP" || fatal "Téléchargement de l'application impossible."
  ranger_jeton "$APP"; vert "application installée"
fi
mkdir -p "$APP/projects"
cat > "$APP/Lancer NMA Auditor.command" <<'LANCEUR'
#!/bin/bash
CIBLE="$0"; while [ -L "$CIBLE" ]; do CIBLE="$(readlink "$CIBLE")"; done
cd "$(dirname "$CIBLE")" || exit 1
export PATH="$HOME/.local/bin:$PATH"
NODE="$HOME/.local/opt/node22/bin/node"; [ -x "$NODE" ] || NODE="$HOME/.local/bin/node"; [ -x "$NODE" ] || NODE="$(command -v node)"
if curl -s http://localhost:4400/api/env >/dev/null 2>&1; then echo "NMA Auditor tourne déjà."; else mkdir -p "$HOME/.nma-auditor"; "$NODE" server.mjs > "$HOME/.nma-auditor/server.log" 2>&1 & sleep 2; fi
open http://localhost:4400
echo "NMA Auditor est ouvert dans le navigateur. Tu peux fermer cette fenêtre."
LANCEUR
chmod +x "$APP/Lancer NMA Auditor.command" 2>/dev/null
raccourci_vers() { [ -d "$1" ] || return 1; { printf '#!/bin/bash\nexec /bin/bash "%s/Lancer NMA Auditor.command"\n' "$APP" > "$1/NMA Auditor.command"; } 2>/dev/null || return 1; chmod +x "$1/NMA Auditor.command" 2>/dev/null; }
if raccourci_vers "$HOME/Desktop"; then vert "raccourci créé sur le Bureau"; elif mkdir -p "$HOME/Applications" 2>/dev/null && raccourci_vers "$HOME/Applications"; then vert "raccourci créé dans ton dossier Applications"; else gris "raccourci impossible — le lanceur reste dans le dossier de l'application"; fi

# ----------------------------------------------------------------------------- terminé
echo ""; printf "\033[1m  VÉRIFICATION FINALE\033[0m\n"; verifier "$APP"; echo ""
if [ "$PROBLEMES" -gt 0 ]; then rouge "  $PROBLEMES point(s) à régler :$SOUCIS"; echo ""; echo "  Relance la commande : elle reprend là où ça a échoué."; echo ""; exit 1; fi
printf "\033[1;32m  INSTALLATION TERMINÉE\033[0m\n"; echo ""
echo "  Pour lancer NMA Auditor : double-clique sur « NMA Auditor.command » (Bureau ou Applications)."
echo "  Au premier lancement, ouvre Réglages et colle les clés (Anthropic, Apify, Cloudflare)."
echo ""
bash "$APP/Lancer NMA Auditor.command" >/dev/null 2>&1 &
exit 0

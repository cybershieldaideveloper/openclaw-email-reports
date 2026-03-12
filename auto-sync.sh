#!/bin/bash

# ===== AUTO-SYNC SCRIPT FÜR OPENCLAW EMAIL REPORTS =====
# Synchronisiert Änderungen automatisch mit GitHub
# Verwendung: Als Cron-Job alle X Minuten oder manuell nach Änderungen

REPO_DIR="/home/csa/.openclaw/workspace/repos/openclaw-email-reports"
SOURCE_SCRIPT="/home/csa/.openclaw/workspace/cron_scripts/send_hourly_activity_v3.sh"
SOURCE_MAIL_SCRIPT="/home/csa/.openclaw/workspace/send_proton_mail_html.sh"

# Credentials laden
source ~/.env

cd "$REPO_DIR" || exit 1

# Aktuelle Dateien kopieren
cp "$SOURCE_SCRIPT" "$REPO_DIR/" 2>/dev/null
cp "$SOURCE_MAIL_SCRIPT" "$REPO_DIR/" 2>/dev/null

# Prüfen ob Änderungen vorliegen
if git diff --quiet && git diff --cached --quiet; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Keine Änderungen zu committen."
    exit 0
fi

# Änderungen committen
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Änderungen erkannt. Committing..."

# Auto-generierte Commit-Message mit Zeitstempel
COMMIT_MSG="Auto-sync: $(date '+%Y-%m-%d %H:%M:%S UTC')"

# Falls VERSION-File existiert, in Commit-Message aufnehmen
if [ -f "VERSION" ]; then
    VERSION=$(cat VERSION)
    COMMIT_MSG="Auto-sync v$VERSION: $(date '+%Y-%m-%d %H:%M:%S UTC')"
fi

git add .
git commit -m "$COMMIT_MSG"

# Push zu GitHub
git push https://$GITHUB_TOKEN@github.com/cybershieldaideveloper/openclaw-email-reports.git main

if [ $? -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Erfolgreich zu GitHub gepusht."
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Fehler beim Push zu GitHub."
    exit 1
fi

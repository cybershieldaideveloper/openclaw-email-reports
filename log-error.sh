#!/bin/bash

# ===== ERROR LOGGING SCRIPT =====
# Automatisches Logging von Fehlern ins ERROR_TRACKING.md
# Verwendung: ./log-error.sh "SEVERITY" "Component" "Error Message" "Details"

REPO_DIR="/home/csa/.openclaw/workspace/repos/openclaw-email-reports"
ERROR_FILE="$REPO_DIR/ERROR_TRACKING.md"

SEVERITY="${1:-INFO}"
COMPONENT="${2:-Unknown}"
MESSAGE="${3:-No message provided}"
DETAILS="${4:-}"

# Timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S UTC')

# Error-Eintrag erstellen
ERROR_ENTRY="
[$TIMESTAMP] [$SEVERITY] $COMPONENT: $MESSAGE"

if [ -n "$DETAILS" ]; then
    ERROR_ENTRY+="
Details: $DETAILS"
fi

ERROR_ENTRY+="
---
"

# An ERROR_TRACKING.md anhängen
echo "$ERROR_ENTRY" >> "$ERROR_FILE"

# Auto-commit wenn gewünscht
if [ "$5" == "--auto-commit" ]; then
    cd "$REPO_DIR" || exit 1
    git add ERROR_TRACKING.md
    git commit -m "Error logged: [$SEVERITY] $COMPONENT at $TIMESTAMP"
    
    # Push zu GitHub
    source ~/.env
    git push https://$GITHUB_TOKEN@github.com/cybershieldaideveloper/openclaw-email-reports.git main 2>/dev/null
fi

echo "[$TIMESTAMP] Error logged: [$SEVERITY] $COMPONENT"

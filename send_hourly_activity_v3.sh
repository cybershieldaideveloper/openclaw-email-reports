#!/bin/bash

# ===== OPENCLAW INTELLIGENT REPORT SYSTEM v3.2.0 =====
# Features:
# - Responsive Design (Desktop + Mobile optimized)
# - HTML-Formatierung mit CSS (Aptos font)
# - Security-Alerts (SSH, Failed Logins)
# - Netzwerk-Traffic & CPU-Last
# - Cron-Job Status mit namentlicher Nennung (7h-Zeitfenster)
# - TODO-Listen mit namentlicher Nennung (Offen/Erledigt)
# - Dynamische "Nächste Schritte" aus offenen TODOs
# - Mobile-first: Kompakte Ansicht bei INFO-Level
# - Intelligente Alert-Logik (sofort vs. Digest)
# - Git-Aktivitäten ausgelagert in separaten GitHub Report

# Credentials aus .env laden
source ~/.env

# Konfiguration - EXPORTIEREN für send_proton_mail_html.sh
export PROTON_MAIL_SMTP_SERVER="127.0.0.1"
export PROTON_MAIL_SMTP_PORT="${PROTON_SMTP_PORT}"
export PROTON_MAIL_USERNAME="${PROTON_EMAIL}"
export PROTON_MAIL_PASSWORD="${PROTON_PASSWORD}"
RECIPIENT="internetsucht@gmail.com"
EMAIL_SENDER_SCRIPT="/home/csa/.openclaw/workspace/send_proton_mail_html.sh"
WORKSPACE="/home/csa/.openclaw/workspace"
STATE_FILE="${WORKSPACE}/.report_state.json"
CURRENT_HOUR=$((10#$(date +%H)))

# Alert-Level
ALERT_LEVEL="INFO"  # INFO, WARNING, CRITICAL

# ===== HILFSFUNKTIONEN =====

# ASCII-Chart Generator (Horizontal Bar)
generate_bar() {
    local value=$1
    local max=$2
    local width=20
    local filled=$(( value * width / max ))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=filled; i<width; i++)); do bar+="░"; done
    echo "$bar"
}

# State-File lesen/schreiben
read_state() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo "{\"last_digest_hour\": 0, \"alerts\": []}"
    fi
}

write_state() {
    echo "$1" > "$STATE_FILE"
}

# Alert-Level erhöhen
set_alert() {
    local level=$1
    if [ "$level" == "CRITICAL" ]; then
        ALERT_LEVEL="CRITICAL"
    elif [ "$level" == "WARNING" ] && [ "$ALERT_LEVEL" != "CRITICAL" ]; then
        ALERT_LEVEL="WARNING"
    fi
}

# ===== DATEN SAMMELN =====

# 1. SYSTEM-METRIKEN
DISK_USED=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
DISK_AVAIL=$(df -h / | awk 'NR==2 {print $4}')
RAM_USED=$(free | awk 'NR==2 {printf "%.0f", $3/$2 * 100}')
RAM_TOTAL=$(free -h | awk 'NR==2 {print $2}')
RAM_AVAIL=$(free -h | awk 'NR==2 {print $4}')
UPTIME=$(uptime -p)
CPU_LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')

# Alert-Checks
[ "$DISK_USED" -gt 90 ] && set_alert "CRITICAL"
[ "$DISK_USED" -gt 80 ] && set_alert "WARNING"
[ "$RAM_USED" -gt 90 ] && set_alert "WARNING"

# 2. PROTON MAIL BRIDGE
BRIDGE_STATUS=$(nc -zv 127.0.0.1 1025 2>&1 | grep -q 'succeeded' && echo "online" || echo "offline")
[ "$BRIDGE_STATUS" == "offline" ] && set_alert "CRITICAL"

# 3. SECURITY-ALERTS (SSH-Logs, letzte Stunde)
FAILED_SSH=$(sudo grep "Failed password" /var/log/auth.log 2>/dev/null | grep "$(date '+%b %e %H')" | wc -l || echo "0")
SUCCESSFUL_SSH=$(sudo grep "Accepted password" /var/log/auth.log 2>/dev/null | grep "$(date '+%b %e %H')" | wc -l || echo "0")
SUDO_COMMANDS=$(sudo grep "sudo:" /var/log/auth.log 2>/dev/null | grep "$(date '+%b %e %H')" | wc -l || echo "0")

[ "$FAILED_SSH" -gt 5 ] && set_alert "WARNING"
[ "$FAILED_SSH" -gt 20 ] && set_alert "CRITICAL"

# 4. NETZWERK-STATISTIKEN
ESTABLISHED_CONN=$(ss -tn state established 2>/dev/null | wc -l || echo "0")
LISTENING_PORTS=$(ss -tln 2>/dev/null | wc -l || echo "0")

# 5. CRON-JOB STATUS (letzte 7 Stunden)
SEVEN_HOURS_AGO=$(date -d '7 hours ago' '+%b %e %H:%M')
CRON_RUNS=$(sudo grep "CRON" /var/log/syslog 2>/dev/null | awk -v cutoff="$SEVEN_HOURS_AGO" '$0 >= cutoff' | wc -l || echo "0")
CRON_ERRORS=$(sudo grep "CRON.*error" /var/log/syslog 2>/dev/null | awk -v cutoff="$SEVEN_HOURS_AGO" '$0 >= cutoff' | wc -l || echo "0")

# Cron-Job Namen extrahieren (letzte 7 Stunden)
CRON_JOB_NAMES=$(sudo grep "CRON\[" /var/log/syslog 2>/dev/null | awk -v cutoff="$SEVEN_HOURS_AGO" '$0 >= cutoff' | grep -oP 'CMD \(\K[^)]+' | sed 's|.*/||' | sort | uniq || echo "")

[ "$CRON_ERRORS" -gt 0 ] && set_alert "WARNING"

# 6. GIT-AKTIVITÄTEN
GIT_COMMITS=$(find ${WORKSPACE} -type d -name ".git" -exec sh -c 'cd "{}/.."; git log --since="1 hour ago" --pretty=format:"%h - %s (%ar)" 2>/dev/null' \; | head -5)

# 7. GEÄNDERTE DATEIEN
CHANGED_FILES=$(find ${WORKSPACE} -type f -mmin -60 -not -path "*/\.git/*" -not -path "*/node_modules/*" -not -path "*/.report_state.json" 2>/dev/null | head -10)

# 8. TODOs
TODO_OPEN=$(cat ${WORKSPACE}/TODO*.md 2>/dev/null | grep -c "^- \[ \]" || echo "0")
TODO_DONE=$(cat ${WORKSPACE}/TODO*.md 2>/dev/null | grep -c "^- \[x\]" || echo "0")

# TODO-Einträge extrahieren (max. 10 pro Kategorie)
TODO_OPEN_LIST=$(cat ${WORKSPACE}/TODO*.md 2>/dev/null | grep "^- \[ \]" | sed 's/^- \[ \] //' | head -10 || echo "")
TODO_DONE_LIST=$(cat ${WORKSPACE}/TODO*.md 2>/dev/null | grep "^- \[x\]" | sed 's/^- \[x\] //' | head -10 || echo "")

# Top 5 offene TODOs für "Nächste Schritte"
NEXT_STEPS_LIST=$(cat ${WORKSPACE}/TODO*.md 2>/dev/null | grep "^- \[ \]" | sed 's/^- \[ \] /• /' | head -5 || echo "")

# 9. MEMORY LOG
MEMORY_FILE="${WORKSPACE}/memory/$(date +%Y-%m-%d).md"
if [ -f "$MEMORY_FILE" ]; then
    MEMORY_TAIL=$(tail -n 5 "$MEMORY_FILE" 2>/dev/null)
else
    MEMORY_TAIL=""
fi

# 10. LAUFENDE PROZESSE
PROTON_RUNNING=$(pgrep -f protonmail-bridge > /dev/null && echo "yes" || echo "no")
OPENCLAW_SESSIONS=$(ps aux | grep -c '[o]penclaw' || echo "0")

# ===== DIGEST-LOGIK =====
STATE=$(read_state)
LAST_DIGEST=$(echo "$STATE" | grep -o '"last_digest_hour": *[0-9]*' | grep -o '[0-9]*$')

SEND_EMAIL="no"

# Kritische Alerts sofort senden
if [ "$ALERT_LEVEL" == "CRITICAL" ]; then
    SEND_EMAIL="yes"
    REASON="Critical Alert"
# Alle 6 Stunden Digest
elif [ $((CURRENT_HOUR % 6)) -eq 0 ] && [ "$CURRENT_HOUR" != "$LAST_DIGEST" ]; then
    SEND_EMAIL="yes"
    REASON="6-Hour Digest"
    # State aktualisieren
    STATE=$(echo "$STATE" | sed "s/\"last_digest_hour\": *[0-9]*/\"last_digest_hour\": $CURRENT_HOUR/")
    write_state "$STATE"
fi

# ===== HTML-REPORT GENERIEREN =====

# Logo als Base64 Data URL laden
LOGO_BASE64=$(cat ${WORKSPACE}/assets/cyber-shield-logo.base64 2>/dev/null)

HTML_REPORT="<!DOCTYPE html>
<html>
<head>
<meta charset='UTF-8'>
<style>
body { font-family: 'Aptos', 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f5f5f5; margin: 0; padding: 20px; }
.logo { width: 80px; height: auto; margin-bottom: 15px; }
.container { max-width: 800px; margin: 0 auto; background: white; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); overflow: hidden; }
.header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; }
.header h1 { margin: 0; font-size: 28px; }
.header .subtitle { opacity: 0.9; margin-top: 10px; }
.alert-badge { display: inline-block; padding: 5px 15px; border-radius: 20px; font-size: 12px; font-weight: bold; margin-top: 10px; }
.alert-info { background: #4CAF50; }
.alert-warning { background: #FF9800; }
.alert-critical { background: #F44336; animation: pulse 2s infinite; }
@keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.7; } }
.section { padding: 20px 30px; border-bottom: 1px solid #eee; }
.section:last-child { border-bottom: none; }
.section h2 { margin: 0 0 15px 0; color: #333; font-size: 18px; display: flex; align-items: center; }
.section h2 .emoji { margin-right: 10px; font-size: 22px; }
.metric { display: flex; justify-content: space-between; margin: 10px 0; align-items: center; }
.metric-label { color: #666; font-size: 14px; }
.metric-value { font-weight: bold; color: #333; font-size: 14px; }
.bar-container { flex: 1; margin: 0 15px; background: #eee; height: 20px; border-radius: 10px; overflow: hidden; }
.bar { height: 100%; background: linear-gradient(90deg, #667eea 0%, #764ba2 100%); transition: width 0.3s; }
.bar.warning { background: linear-gradient(90deg, #FF9800 0%, #F57C00 100%); }
.bar.critical { background: linear-gradient(90deg, #F44336 0%, #D32F2F 100%); }
.log-entry { background: #f9f9f9; padding: 10px; margin: 5px 0; border-left: 3px solid #667eea; font-family: monospace; font-size: 12px; border-radius: 3px; }
.status-ok { color: #4CAF50; font-weight: bold; }
.status-error { color: #F44336; font-weight: bold; }
.footer { padding: 20px 30px; background: #f9f9f9; text-align: center; font-size: 12px; color: #666; }
table { width: 100%; border-collapse: collapse; margin-top: 10px; }
td { padding: 8px; border-bottom: 1px solid #eee; }
td:first-child { color: #666; width: 40%; }
td:last-child { font-weight: bold; color: #333; }
.badge { display: inline-block; padding: 3px 8px; border-radius: 12px; font-size: 11px; font-weight: bold; }
.badge-success { background: #E8F5E9; color: #2E7D32; }
.badge-warning { background: #FFF3E0; color: #E65100; }
.badge-error { background: #FFEBEE; color: #C62828; }

/* Mobile Responsive Design */
@media only screen and (max-width: 600px) {
    body { padding: 10px; }
    .container { border-radius: 0; }
    .header { padding: 20px 15px; }
    .header h1 { font-size: 22px; }
    .section { padding: 15px 20px; }
    .section h2 { font-size: 16px; }
    .section h2 .emoji { font-size: 18px; }
    .metric { flex-direction: column; align-items: flex-start; }
    .bar-container { width: 100%; margin: 10px 0; }
    .log-entry { font-size: 11px; padding: 8px; }
    table { font-size: 13px; }
    td { padding: 6px; }
    .logo { width: 60px; }
    /* Hide details on mobile for INFO-level */
    .mobile-hide-info { display: none !important; }
}
</style>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
<div class='container'>

<!-- HEADER -->
<div class='header'>"

# Logo einfügen (falls vorhanden)
if [ -n "$LOGO_BASE64" ]; then
HTML_REPORT+="
<img src='data:image/webp;base64,$LOGO_BASE64' alt='Cyber Shield Logo' class='logo'>"
fi

HTML_REPORT+="
<h1>🤖 OpenClaw VM-1 Report</h1>
<div class='subtitle'>$(date '+%Y-%m-%d %H:%M:%S UTC')</div>
<span class='alert-badge alert-${ALERT_LEVEL,,}'>$ALERT_LEVEL</span>
</div>

<!-- SYSTEM-STATUS -->
<div class='section'>
<h2><span class='emoji'>📊</span> System-Status</h2>
<div class='metric'>
<span class='metric-label'>Disk Space (belegt)</span>
<div class='bar-container'><div class='bar $([ $DISK_USED -gt 80 ] && echo "warning" || [ $DISK_USED -gt 90 ] && echo "critical")' style='width: ${DISK_USED}%'></div></div>
<span class='metric-value'>${DISK_USED}%</span>
</div>
<div class='metric'>
<span class='metric-label'>RAM (genutzt)</span>
<div class='bar-container'><div class='bar $([ $RAM_USED -gt 90 ] && echo "warning")' style='width: ${RAM_USED}%'></div></div>
<span class='metric-value'>${RAM_USED}%</span>
</div>
<table>
<tr><td>Disk verfügbar</td><td>$DISK_AVAIL</td></tr>
<tr><td>RAM verfügbar</td><td>$RAM_AVAIL</td></tr>
<tr><td>CPU Load (1min)</td><td>$CPU_LOAD</td></tr>
<tr><td>Uptime</td><td>$UPTIME</td></tr>
</table>
</div>

<!-- SERVICES -->
<div class='section'>
<h2><span class='emoji'>🔄</span> Services</h2>
<table>
<tr><td>Proton Mail Bridge</td><td class='$([ "$BRIDGE_STATUS" == "online" ] && echo "status-ok" || echo "status-error")'>$([ "$BRIDGE_STATUS" == "online" ] && echo "✅ Online (Port 1025)" || echo "❌ Offline")</td></tr>
<tr><td>protonmail-bridge Prozess</td><td class='$([ "$PROTON_RUNNING" == "yes" ] && echo "status-ok" || echo "status-error")'>$([ "$PROTON_RUNNING" == "yes" ] && echo "✅ Läuft" || echo "❌ Nicht gestartet")</td></tr>
<tr><td>OpenClaw Sessions</td><td>$OPENCLAW_SESSIONS aktiv</td></tr>
</table>
</div>

<!-- SECURITY -->
<div class='section'>
<h2><span class='emoji'>🔒</span> Security (letzte Stunde)</h2>
<table>
<tr><td>Fehlgeschlagene SSH-Logins</td><td><span class='badge $([ $FAILED_SSH -eq 0 ] && echo "badge-success" || [ $FAILED_SSH -lt 5 ] && echo "badge-warning" || echo "badge-error")'>$FAILED_SSH</span></td></tr>
<tr><td>Erfolgreiche SSH-Logins</td><td><span class='badge badge-success'>$SUCCESSFUL_SSH</span></td></tr>
<tr><td>Sudo-Befehle</td><td>$SUDO_COMMANDS</td></tr>
</table>
</div>

<!-- NETZWERK -->
<div class='section'>
<h2><span class='emoji'>🌐</span> Netzwerk</h2>
<table>
<tr><td>Aktive Verbindungen (ESTABLISHED)</td><td>$ESTABLISHED_CONN</td></tr>
<tr><td>Listening Ports</td><td>$LISTENING_PORTS</td></tr>
</table>
</div>

<!-- CRON-JOBS -->
<div class='section'>
<h2><span class='emoji'>⏰</span> Cron-Jobs (letzte 7 Stunden)</h2>
<table>
<tr><td>Ausgeführte Jobs</td><td>$CRON_RUNS</td></tr>
<tr><td>Fehler</td><td><span class='badge $([ $CRON_ERRORS -eq 0 ] && echo "badge-success" || echo "badge-error")'>$CRON_ERRORS</span></td></tr>
</table>"

# Cron-Job-Namen anzeigen (falls vorhanden)
if [ -n "$CRON_JOB_NAMES" ]; then
HTML_REPORT+="
<div style='margin-top: 15px;'>
<strong>Ausgeführte Jobs:</strong>"
while IFS= read -r job; do
    [ -n "$job" ] && HTML_REPORT+="<div class='log-entry'>$job</div>"
done <<< "$CRON_JOB_NAMES"
HTML_REPORT+="</div>"
fi

HTML_REPORT+="
</div>"

# GIT-AKTIVITÄTEN - MOVED TO SEPARATE GITHUB ACTIVITY REPORT

# GEÄNDERTE DATEIEN (nur bei WARNING/CRITICAL)
if [ -n "$CHANGED_FILES" ] && [ "$ALERT_LEVEL" != "INFO" ]; then
HTML_REPORT+="
<div class='section'>
<h2><span class='emoji'>📁</span> Geänderte Dateien</h2>
<table>"
while IFS= read -r file; do
    filename=$(basename "$file")
    filesize=$(ls -lh "$file" 2>/dev/null | awk '{print $5}')
    HTML_REPORT+="<tr><td>$filename</td><td>$filesize</td></tr>"
done <<< "$CHANGED_FILES"
HTML_REPORT+="</table>
</div>"
fi

# TODOs
HTML_REPORT+="
<div class='section'>
<h2><span class='emoji'>✅</span> TODOs</h2>
<table>
<tr><td>Offen</td><td><span class='badge badge-warning'>$TODO_OPEN</span></td></tr>
<tr><td>Erledigt</td><td><span class='badge badge-success'>$TODO_DONE</span></td></tr>
</table>"

# Offene TODOs auflisten (kompakt bei INFO-Level)
if [ -n "$TODO_OPEN_LIST" ]; then
    if [ "$ALERT_LEVEL" = "INFO" ]; then
        TODO_OPEN_DISPLAY=$(echo "$TODO_OPEN_LIST" | head -3)
    else
        TODO_OPEN_DISPLAY="$TODO_OPEN_LIST"
    fi
    
    HTML_REPORT+="
<div style='margin-top: 15px;'>
<strong>📋 Offene Tasks:</strong>"
    while IFS= read -r todo; do
        [ -n "$todo" ] && HTML_REPORT+="<div class='log-entry'>⬜ $todo</div>"
    done <<< "$TODO_OPEN_DISPLAY"
    HTML_REPORT+="</div>"
fi

# Erledigte TODOs auflisten (kompakt bei INFO-Level)
if [ -n "$TODO_DONE_LIST" ]; then
    if [ "$ALERT_LEVEL" = "INFO" ]; then
        TODO_DONE_DISPLAY=$(echo "$TODO_DONE_LIST" | head -3)
    else
        TODO_DONE_DISPLAY="$TODO_DONE_LIST"
    fi
    
    HTML_REPORT+="
<div style='margin-top: 15px;'>
<strong>✅ Erledigte Tasks:</strong>"
    while IFS= read -r todo; do
        [ -n "$todo" ] && HTML_REPORT+="<div class='log-entry'>✅ $todo</div>"
    done <<< "$TODO_DONE_DISPLAY"
    HTML_REPORT+="</div>"
fi

HTML_REPORT+="
</div>"

# MEMORY LOG (kompakt auf Mobile bei INFO-Level)
if [ -n "$MEMORY_TAIL" ]; then
    # Bei INFO-Level nur 2 Einträge, sonst 5
    if [ "$ALERT_LEVEL" = "INFO" ]; then
        MEMORY_DISPLAY=$(echo "$MEMORY_TAIL" | tail -n 2)
        MEMORY_TITLE="Memory Log (letzte 2 Einträge)"
    else
        MEMORY_DISPLAY="$MEMORY_TAIL"
        MEMORY_TITLE="Memory Log (letzte 5 Einträge)"
    fi
    
    HTML_REPORT+="
<div class='section'>
<h2><span class='emoji'>💭</span> $MEMORY_TITLE</h2>"
    while IFS= read -r entry; do
        HTML_REPORT+="<div class='log-entry'>$entry</div>"
    done <<< "$MEMORY_DISPLAY"
    HTML_REPORT+="</div>"
fi

# NÄCHSTE SCHRITTE (dynamisch aus offenen TODOs, kompakt bei INFO)
if [ -n "$NEXT_STEPS_LIST" ]; then
    if [ "$ALERT_LEVEL" = "INFO" ]; then
        NEXT_STEPS_DISPLAY=$(echo "$NEXT_STEPS_LIST" | head -3)
        NEXT_STEPS_TITLE="Nächste Schritte (Top 3)"
    else
        NEXT_STEPS_DISPLAY="$NEXT_STEPS_LIST"
        NEXT_STEPS_TITLE="Nächste Schritte (Top 5)"
    fi
    
    HTML_REPORT+="
<div class='section'>
<h2><span class='emoji'>🎯</span> $NEXT_STEPS_TITLE</h2>"
    while IFS= read -r step; do
        [ -n "$step" ] && HTML_REPORT+="<div class='log-entry'>$step</div>"
    done <<< "$NEXT_STEPS_DISPLAY"
    HTML_REPORT+="</div>"
fi

# FOOTER
HTML_REPORT+="
<!-- FOOTER -->
<div class='footer'>
📧 Fragen? Antworte einfach auf diese E-Mail.<br>
🔗 Workspace: /home/csa/.openclaw/workspace<br>
⚙️ OpenClaw Intelligent Report System v3.2.0
</div>

</div>
</body>
</html>"

# ===== E-MAIL SENDEN (falls nötig) =====

SUBJECT="[OpenClaw] $ALERT_LEVEL Alert - $(date '+%Y-%m-%d %H:%M UTC')"

if [ "$SEND_EMAIL" == "yes" ]; then
    echo "$HTML_REPORT" | "${EMAIL_SENDER_SCRIPT}" "${RECIPIENT}" "${SUBJECT}" "$(cat)"
    
    if [ $? -eq 0 ]; then
        echo "Intelligent Report (v3.2.0) erfolgreich gesendet. Grund: $REASON, Alert-Level: $ALERT_LEVEL"
    else
        echo "Fehler beim Senden des Intelligent Reports (v3.2.0)."
    fi
else
    echo "Kein Report-Versand nötig. Nächster Digest um $((CURRENT_HOUR + 6 - (CURRENT_HOUR % 6))) Uhr."
fi

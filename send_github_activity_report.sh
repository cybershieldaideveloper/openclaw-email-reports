#!/bin/bash

# ===== CYBERSHIELD GITHUB ACTIVITY REPORT v1.0.0 =====
# Comprehensive GitHub repository activity tracking
# Features:
# - Multi-repository tracking
# - Commit history with details
# - Branch activity
# - File changes with diffs
# - Contributor statistics
# - Beautiful HTML report with Cyber Shield branding

WORKSPACE="/home/csa/.openclaw/workspace"
RECIPIENT="internetsucht@gmail.com"

# Load credentials
source ~/.env

# Logo als Base64 Data URL
LOGO_BASE64=$(cat ${WORKSPACE}/assets/cyber-shield-logo.base64 2>/dev/null)

# Zeitfenster (Standard: letzte 24 Stunden)
HOURS_AGO=${1:-24}
SINCE_DATE=$(date -d "$HOURS_AGO hours ago" '+%Y-%m-%d %H:%M:%S')

# ===== DATENSAMMLUNG =====

# Repositories scannen
REPOS=$(find ${WORKSPACE} -type d -name ".git" 2>/dev/null | sed 's|/.git||')
REPO_COUNT=$(echo "$REPOS" | grep -c '^' || echo "0")

# GitHub Repos (mit Remote)
GITHUB_REPOS=""
for repo in $REPOS; do
    cd "$repo" || continue
    REMOTE=$(git remote get-url origin 2>/dev/null | grep -i "github.com" || echo "")
    if [ -n "$REMOTE" ]; then
        GITHUB_REPOS+="$repo|$REMOTE"$'\n'
    fi
done

# Commits sammeln
ALL_COMMITS=""
TOTAL_COMMITS=0

while IFS='|' read -r repo_path remote_url; do
    [ -z "$repo_path" ] && continue
    cd "$repo_path" || continue
    
    REPO_NAME=$(basename "$repo_path")
    COMMITS=$(git log --since="$SINCE_DATE" --pretty=format:"%H|%an|%ae|%ad|%s" --date=short 2>/dev/null || echo "")
    
    if [ -n "$COMMITS" ]; then
        COMMIT_COUNT=$(echo "$COMMITS" | grep -c '^' || echo "0")
        TOTAL_COMMITS=$((TOTAL_COMMITS + COMMIT_COUNT))
        
        while IFS='|' read -r hash author email date message; do
            [ -z "$hash" ] && continue
            # Stat für diesen Commit
            STATS=$(git show --stat --pretty="" "$hash" 2>/dev/null | tail -1)
            FILES_CHANGED=$(echo "$STATS" | grep -oP '\d+ files? changed' | grep -oP '\d+' || echo "0")
            INSERTIONS=$(echo "$STATS" | grep -oP '\d+ insertions?' | grep -oP '\d+' || echo "0")
            DELETIONS=$(echo "$STATS" | grep -oP '\d+ deletions?' | grep -oP '\d+' || echo "0")
            
            ALL_COMMITS+="$REPO_NAME|$hash|$author|$email|$date|$message|$FILES_CHANGED|$INSERTIONS|$DELETIONS|$remote_url"$'\n'
        done <<< "$COMMITS"
    fi
done <<< "$GITHUB_REPOS"

# Contributors (letzte 30 Tage für Statistik)
CONTRIBUTORS=""
for repo in $REPOS; do
    cd "$repo" || continue
    REPO_CONTRIBUTORS=$(git shortlog -sne --since="30 days ago" 2>/dev/null || echo "")
    if [ -n "$REPO_CONTRIBUTORS" ]; then
        CONTRIBUTORS+="$REPO_CONTRIBUTORS"$'\n'
    fi
done

# Contributor-Zusammenfassung
UNIQUE_CONTRIBUTORS=$(echo "$CONTRIBUTORS" | awk '{print $NF}' | sort -u | grep -c '@' || echo "0")

# Branch-Aktivität
ACTIVE_BRANCHES=""
for repo in $REPOS; do
    cd "$repo" || continue
    REPO_NAME=$(basename "$repo")
    BRANCHES=$(git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short)|%(committerdate:short)|%(authorname)' 2>/dev/null || echo "")
    if [ -n "$BRANCHES" ]; then
        ACTIVE_BRANCHES+="$REPO_NAME: $BRANCHES"$'\n'
    fi
done

# ===== HTML-REPORT GENERIEREN =====

HTML_REPORT="<!DOCTYPE html>
<html>
<head>
<meta charset='UTF-8'>
<meta name='viewport' content='width=device-width, initial-scale=1.0'>
<style>
body { font-family: 'Aptos', 'Segoe UI', sans-serif; background: #0d1117; color: #c9d1d9; margin: 0; padding: 20px; }
.container { max-width: 1000px; margin: 0 auto; background: #161b22; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.5); overflow: hidden; }
.header { background: linear-gradient(135deg, #1e3a8a 0%, #312e81 100%); color: white; padding: 40px; text-align: center; position: relative; overflow: hidden; }
.header::before { content: ''; position: absolute; top: -50%; left: -50%; width: 200%; height: 200%; background: repeating-linear-gradient(45deg, transparent, transparent 10px, rgba(255,255,255,0.03) 10px, rgba(255,255,255,0.03) 20px); animation: slide 20s linear infinite; }
@keyframes slide { 0% { transform: translate(0, 0); } 100% { transform: translate(50px, 50px); } }
.header-content { position: relative; z-index: 1; }
.logo { width: 100px; height: auto; margin-bottom: 20px; filter: drop-shadow(0 0 10px rgba(255,255,255,0.3)); }
.header h1 { margin: 0; font-size: 32px; font-weight: 700; letter-spacing: 1px; }
.header .subtitle { opacity: 0.9; margin-top: 10px; font-size: 14px; }
.tagline { margin-top: 15px; font-size: 16px; font-weight: 600; color: #fbbf24; text-shadow: 0 0 10px rgba(251, 191, 36, 0.5); }
.stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; padding: 30px; background: #0d1117; }
.stat-card { background: linear-gradient(135deg, #1e3a8a 0%, #312e81 100%); padding: 20px; border-radius: 10px; text-align: center; border: 1px solid #30363d; }
.stat-number { font-size: 36px; font-weight: 700; color: #fbbf24; }
.stat-label { color: #8b949e; margin-top: 5px; font-size: 13px; }
.section { padding: 30px; border-bottom: 1px solid #21262d; }
.section:last-child { border-bottom: none; }
.section h2 { margin: 0 0 20px 0; color: #fbbf24; font-size: 22px; display: flex; align-items: center; }
.section h2 .emoji { margin-right: 12px; font-size: 26px; }
.commit-card { background: #0d1117; border: 1px solid #30363d; border-radius: 8px; padding: 15px; margin: 10px 0; transition: all 0.3s; }
.commit-card:hover { border-color: #1e3a8a; transform: translateX(5px); }
.commit-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
.commit-message { font-size: 15px; font-weight: 600; color: #c9d1d9; }
.commit-hash { font-family: 'Courier New', monospace; font-size: 12px; color: #8b949e; background: #21262d; padding: 3px 8px; border-radius: 4px; }
.commit-meta { display: flex; gap: 20px; margin-top: 10px; font-size: 13px; color: #8b949e; }
.commit-meta span { display: flex; align-items: center; gap: 5px; }
.repo-badge { background: #1e3a8a; color: white; padding: 4px 10px; border-radius: 12px; font-size: 12px; font-weight: 600; }
.stat-badge { background: #21262d; padding: 2px 8px; border-radius: 4px; font-size: 12px; }
.stat-badge.add { color: #3fb950; }
.stat-badge.del { color: #f85149; }
.footer { padding: 30px; background: #0d1117; text-align: center; font-size: 12px; color: #8b949e; }
.footer .tagline-footer { color: #fbbf24; font-weight: 600; font-size: 14px; margin-top: 10px; }

@media only screen and (max-width: 600px) {
    body { padding: 0; }
    .container { border-radius: 0; }
    .header { padding: 30px 20px; }
    .section { padding: 20px; }
    .stats-grid { grid-template-columns: 1fr; padding: 20px; }
    .commit-header { flex-direction: column; align-items: flex-start; }
    .commit-meta { flex-direction: column; gap: 8px; }
    .logo { width: 70px; }
}
</style>
</head>
<body>
<div class='container'>

<!-- HEADER -->
<div class='header'>
<div class='header-content'>"

if [ -n "$LOGO_BASE64" ]; then
HTML_REPORT+="
<img src='data:image/webp;base64,$LOGO_BASE64' alt='Cyber Shield Logo' class='logo'>"
fi

HTML_REPORT+="
<h1>🚀 GitHub Activity Report</h1>
<div class='subtitle'>$(date '+%Y-%m-%d %H:%M UTC') • Last $HOURS_AGO Hours</div>
<div class='tagline'>Discover » Improve » Prevail</div>
</div>
</div>

<!-- STATS GRID -->
<div class='stats-grid'>
<div class='stat-card'>
<div class='stat-number'>$TOTAL_COMMITS</div>
<div class='stat-label'>Total Commits</div>
</div>
<div class='stat-card'>
<div class='stat-number'>$REPO_COUNT</div>
<div class='stat-label'>Repositories</div>
</div>
<div class='stat-card'>
<div class='stat-number'>$UNIQUE_CONTRIBUTORS</div>
<div class='stat-label'>Contributors (30d)</div>
</div>
</div>"

# COMMITS SECTION
if [ $TOTAL_COMMITS -gt 0 ]; then
HTML_REPORT+="
<div class='section'>
<h2><span class='emoji'>📝</span> Recent Commits</h2>"

while IFS='|' read -r repo hash author email date message files ins del remote; do
    [ -z "$repo" ] && continue
    SHORT_HASH="${hash:0:7}"
    
    HTML_REPORT+="
<div class='commit-card'>
<div class='commit-header'>
<div class='commit-message'>$message</div>
<span class='repo-badge'>$repo</span>
</div>
<div class='commit-meta'>
<span>🔖 <span class='commit-hash'>$SHORT_HASH</span></span>
<span>👤 $author</span>
<span>📅 $date</span>
<span class='stat-badge'><strong>$files</strong> files</span>
<span class='stat-badge add'>+$ins</span>
<span class='stat-badge del'>-$del</span>
</div>
</div>"
done <<< "$ALL_COMMITS"

HTML_REPORT+="
</div>"
else
HTML_REPORT+="
<div class='section'>
<h2><span class='emoji'>📝</span> Recent Commits</h2>
<p style='color: #8b949e;'>No commits in the last $HOURS_AGO hours.</p>
</div>"
fi

# FOOTER
HTML_REPORT+="
<div class='footer'>
📧 Questions? Reply to this email.<br>
🔗 Workspace: /home/csa/.openclaw/workspace<br>
<div class='tagline-footer'>Discover » Improve » Prevail</div>
⚙️ CyberShield GitHub Activity Report v1.0.0
</div>

</div>
</body>
</html>"

# ===== EMAIL SENDEN =====

echo "$HTML_REPORT" | ${WORKSPACE}/send_proton_mail_html.sh \
    "$RECIPIENT" \
    "[CyberShield] GitHub Activity Report - $(date '+%Y-%m-%d')" \
    -

if [ $? -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] GitHub Activity Report erfolgreich gesendet. Commits: $TOTAL_COMMITS"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Fehler beim Senden des GitHub Activity Reports."
    exit 1
fi

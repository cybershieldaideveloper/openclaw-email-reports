# OpenClaw Intelligent Email Reports

**Automated system monitoring and reporting via email for OpenClaw deployments.**

## 🚀 Features

- **📊 System Monitoring:** Disk space, RAM, CPU load, uptime
- **🔒 Security Alerts:** SSH login attempts, sudo commands, failed authentication
- **🌐 Network Monitoring:** Active connections, listening ports
- **⏰ Cron Job Status:** Named execution tracking with 7-hour lookback window
- **✅ TODO Management:** Dynamic listing of open and completed tasks
- **🎯 Next Steps:** Top 5 open TODOs automatically displayed
- **📝 Activity Logs:** Git commits, file changes, memory logs
- **💌 HTML Email Reports:** Beautiful, responsive design with alert badges
- **🚨 Intelligent Alert Logic:** Critical alerts sent immediately, routine digests every 6 hours

## 📦 Version

**Current Version:** v3.2.0

See [CHANGELOG.md](CHANGELOG.md) for version history.

## 📋 Components

### 1. `send_hourly_activity_v3.sh`
Main system monitoring report. Runs hourly via cron.

**New in v3.2.0:**
- Responsive design (mobile-optimized)
- Compact mode for INFO-level alerts
- Aptos font family
- Git activity moved to separate report

**Alert Levels:**
- **CRITICAL:** Disk > 90%, Proton Bridge offline, SSH failures > 20
- **WARNING:** Disk 80-89%, RAM > 90%, SSH failures 6-20, cron errors
- **INFO:** Normal operation

**Delivery Logic:**
- **Immediate:** Critical alerts
- **Scheduled:** Every 6 hours (0:00, 6:00, 12:00, 18:00 UTC)

### 2. `send_github_activity_report.sh` 🆕
Dedicated GitHub repository activity tracking.

**Features:**
- Multi-repository scanning (all Git repos with GitHub remotes)
- Commit history with detailed stats
- Statistics dashboard (commits, repos, contributors)
- GitHub-inspired dark theme
- Cyber Shield corporate branding
- Mobile-responsive design

**Usage:**
```bash
# Last 24 hours (default)
./send_github_activity_report.sh

# Custom timeframe (in hours)
./send_github_activity_report.sh 48
```

**Recommended Schedule:** Daily at 9:00 AM
```cron
0 9 * * * /path/to/send_github_activity_report.sh 24
```

### 3. `send_proton_mail_html.sh`
HTML email sender using Proton Mail Bridge SMTP.

## 🔧 Configuration

### Environment Variables (`.env`)
```bash
PROTON_EMAIL="your-email@proton.me"
PROTON_PASSWORD="your-password"
PROTON_SMTP_PORT="1025"
```

### Cron Setup
```bash
# Hourly report (staggered 0-5 minutes)
0 * * * * /home/csa/.openclaw/workspace/cron_scripts/send_hourly_activity_v3.sh
```

### Recipient Configuration
Edit `send_hourly_activity_v3.sh`:
```bash
RECIPIENT="your-email@example.com"
```

## 📊 Report Sections

1. **System Status:** Disk, RAM, CPU, uptime
2. **Services:** Proton Mail Bridge, OpenClaw sessions
3. **Security:** SSH login attempts, sudo commands (7-hour window)
4. **Network:** Active connections, listening ports
5. **Cron Jobs:** Named execution list, error tracking (7-hour window)
6. **Git Activity:** Recent commits
7. **File Changes:** Modified files in last hour
8. **TODOs:** Open and completed tasks with names
9. **Memory Log:** Latest entries from daily memory file
10. **Next Steps:** Top 5 open TODOs

## 🔐 Security

- Credentials loaded from `.env` (not hardcoded)
- Log filtering for sensitive data
- Local SMTP via Proton Mail Bridge (encrypted)
- No external API dependencies

## 🛠️ Development

### Version Bump
1. Update version in script header
2. Update version in HTML footer
3. Update version in log messages
4. Update `VERSION` file
5. Document changes in `CHANGELOG.md`
6. Run `./auto-sync.sh` to push changes

### Auto-Sync
Automatically syncs changes to GitHub:
```bash
# Manual sync
./auto-sync.sh

# Or setup as cron job (every 15 minutes)
*/15 * * * * /home/csa/.openclaw/workspace/repos/openclaw-email-reports/auto-sync.sh
```

### Error Tracking
Log errors automatically to `ERROR_TRACKING.md`:
```bash
# Manual error logging
./log-error.sh "SEVERITY" "Component" "Error Message" "Details" --auto-commit

# Example
./log-error.sh "ERROR" "Email Sender" "SMTP connection failed" "Port 1025 not responding" --auto-commit
```

Severity levels: `CRITICAL`, `ERROR`, `WARNING`, `INFO`

### Testing
```bash
# Manual run (dry-run recommended first)
/home/csa/.openclaw/workspace/cron_scripts/send_hourly_activity_v3.sh
```

## 📄 License

MIT License - See [LICENSE](LICENSE)

## 🤝 Contributing

Issues and pull requests welcome!

## 📧 Support

Questions? Open an issue or contact via email.

---

**Powered by OpenClaw** 🤖

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

**Current Version:** v3.1.0

See [CHANGELOG.md](CHANGELOG.md) for version history.

## 📋 Components

### 1. `send_hourly_activity_v3.sh`
Main report generation script. Runs hourly via cron.

**Alert Levels:**
- **CRITICAL:** Disk > 90%, Proton Bridge offline, SSH failures > 20
- **WARNING:** Disk 80-89%, RAM > 90%, SSH failures 6-20, cron errors
- **INFO:** Normal operation

**Delivery Logic:**
- **Immediate:** Critical alerts
- **Scheduled:** Every 6 hours (0:00, 6:00, 12:00, 18:00 UTC)

### 2. `send_proton_mail_html.sh`
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
6. Commit and push

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

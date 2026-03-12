# Changelog

All notable changes to the OpenClaw Intelligent Email Reports project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.1.0] - 2026-03-12

### Added
- **Named Cron Job Execution Tracking:** Displays actual script names that ran (deduplicated, sorted)
- **Extended Cron Job Lookback Window:** Changed from 1 hour to 7 hours for better coverage
- **Named TODO Lists:** Open and completed tasks now show actual task descriptions (max 10 per category)
- **Dynamic "Next Steps" Section:** Auto-populated from top 5 open TODOs (replaces static hardcoded list)

### Changed
- Updated version to v3.1.0 in script header, HTML footer, and log messages
- Improved TODO section with both quantitative (count) and qualitative (names) information

### Fixed
- Removed outdated static "Next Steps" entries (Webpräsenz-Projekt, WebApp Pentesting Phase 2)
- Ensured "Next Steps" always reflects current priorities from TODO files

---

## [3.0.0] - 2026-03-09

### Added
- **HTML Email Reports:** Beautiful responsive design with CSS styling
- **Alert Badge System:** Visual indicators for INFO/WARNING/CRITICAL levels
- **Gradient Headers:** Modern design with purple gradient
- **Animated Critical Alerts:** Pulsing badge for critical issues
- **Progress Bars:** Visual representation of disk/RAM usage
- **Service Status Tracking:** Proton Mail Bridge, OpenClaw sessions
- **Security Monitoring:** SSH login attempts, sudo commands
- **Network Statistics:** Active connections, listening ports
- **Cron Job Monitoring:** Execution count and error tracking
- **Git Activity Log:** Recent commits with timestamps
- **File Change Tracking:** Modified files in last hour
- **TODO Integration:** Open/completed task counts
- **Memory Log Integration:** Latest daily memory entries

### Alert Logic
- **CRITICAL:** Disk > 90%, Bridge offline, SSH > 20 failures
- **WARNING:** Disk 80-89%, RAM > 90%, SSH 6-20 failures, cron errors
- **INFO:** Normal operation

### Delivery Logic
- **Immediate:** Critical alerts
- **Scheduled:** Every 6 hours (0:00, 6:00, 12:00, 18:00 UTC)
- **State Management:** JSON state file tracks last digest time

---

## [2.x.x] - (Previous Versions)

### Features
- Plain text email reports
- Basic system metrics
- Simple cron integration

---

## Future Roadmap

### [3.2.0] - Planned
- Configurable alert thresholds via config file
- Custom report sections (enable/disable via config)
- Multi-recipient support
- Report archiving system

### [3.3.0] - Planned
- Webhook integration for Slack/Discord notifications
- Grafana-compatible metrics export
- Historical trend charts
- Mobile-optimized email templates

### [4.0.0] - Planned
- Web dashboard for report viewing
- Interactive report filtering
- Real-time alert streaming
- API for external integrations

---

[3.1.0]: https://github.com/YOUR_USERNAME/openclaw-email-reports/compare/v3.0.0...v3.1.0
[3.0.0]: https://github.com/YOUR_USERNAME/openclaw-email-reports/releases/tag/v3.0.0

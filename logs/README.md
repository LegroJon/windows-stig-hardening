# Application Logs

This folder contains execution logs and debugging information.

## Log Types
- **scan.log** - Main assessment execution log
- **error.log** - Error and exception details
- **debug.log** - Verbose debugging information (when enabled)

## Log Rotation
- Logs are rotated daily
- Maximum 30 days of logs retained
- Large logs are compressed automatically

## Log Format
```
[YYYY-MM-DD HH:MM:SS] [LEVEL] [COMPONENT] Message
```

Levels: INFO, WARN, ERROR, DEBUG

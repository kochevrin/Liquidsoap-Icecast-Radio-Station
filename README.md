# Liquidsoap + Icecast Radio Station

Automated radio station using Docker, Liquidsoap, and Icecast for streaming music with scheduled programming.

## Project Description

This project is a fully functional internet radio station with the following features:

- **Automatic music playback** from the `default/` folder
- **Ads every 15 minutes** (0, 15, 30, 45 minutes of each hour)
- **Special program** at 9:00-9:03 (Silent Minute)
- **Streaming** via Icecast server
- **Logging** of all events and current time

## Project Structure

```
LiquidsoapIcecast/
├── docker-compose.yml         # Docker containers configuration
├── generate-config.sh         # Script to generate icecast.xml from template
├── .env.example              # Example environment variables
├── .env                      # Your environment variables (not in git)
├── icecast/
│   ├── icecast.xml.template  # Template for Icecast configuration
│   └── icecast.xml          # Generated Icecast configuration (not in git)
├── liquidsoap/
│   ├── radio.liq             # Main Liquidsoap script
│   └── music/
│       ├── SilentMinute.mp3  # File for special program
│       ├── ads/              # Folder with advertising tracks
│       └── default/          # Folder with main music
└── README.md
```

## Technical Specifications

- **Icecast server**: port 8100 (external), 8000 (internal)
- **Audio format**: MP3, 128 kbps
- **Scheduler**: Automatic time-based switching
- **Timezone**: Europe/Kiev
- **Maximum clients**: 100 simultaneous connections

## Broadcasting Schedule

- **00:00-00:01, 15:00-15:01, 30:00-30:01, 45:00-45:01**: Ads
- **09:00:00-09:03:18**: Silent Minute (special program)
- **Rest of the time**: Random music from `default/` folder

## Requirements

- Docker
- Docker Compose
- Minimum 512 MB RAM
- Port 8100 must be available

## Initial Setup

Before starting the project for the first time, you need to configure your environment:

### 1. Configure Environment Variables
Copy the example environment file and set your passwords:
```bash
cp .env.example .env
```

Edit `.env` file and set your own passwords:
```bash
# Change these passwords to your own
ICECAST_ADMIN_PASSWORD=your_strong_admin_password
ICECAST_SOURCE_PASSWORD=your_strong_source_password
ICECAST_RELAY_PASSWORD=your_strong_relay_password
```

### 2. Generate Icecast Configuration
Use the provided script to generate the Icecast configuration from the template:
```bash
./generate-config.sh
```

This script will:
- Read passwords from your `.env` file
- Generate `icecast/icecast.xml` from the template
- Automatically substitute all environment variables

### 3. Add Your Music
Place your audio files in the appropriate directories:
- `liquidsoap/music/default/` - main music files
- `liquidsoap/music/ads/` - advertisement files

## Quick Start

After completing the initial setup:

```bash
# Generate Icecast configuration from template
./generate-config.sh

# Start the radio station
docker compose up -d
```

## Stopping the Project

```bash
docker compose down
```

## Accessing the Radio Station

After startup, the radio station will be available at:

- **Audio stream**: http://localhost:8100/stream
- **Icecast web interface**: http://localhost:8100/
- **Admin panel**: http://localhost:8100/admin/

### Credentials

- **Admin login**: admin
- **Admin password**: as set in your `.env` file
- **Source password**: as set in your `.env` file

## Content Management

### Adding Music
Place MP3 files in the appropriate folders:
- `liquidsoap/music/default/` - main music
- `liquidsoap/music/ads/` - advertisements

### Updating Playlists
Playlists are automatically updated every hour. To force reload, restart the container:

```bash
docker compose restart liquidsoap
```

## Monitoring

To view logs in real-time:

```bash
# Logs for all services
docker compose logs -f

# Logs for Liquidsoap only
docker compose logs -f liquidsoap

# Logs for Icecast only
docker compose logs -f icecast
```

## Troubleshooting

### Check Container Status
```bash
docker compose ps
```

### Restart Services
```bash
# Restart all services
docker compose restart

# Restart Liquidsoap only
docker compose restart liquidsoap
```

### Connection Testing
```bash
# Test stream
curl -I http://localhost:8100/stream

# Check web interface
curl -I http://localhost:8100/
```

## Configuration

All main settings are moved to the `.env` file for easy modification:

### .env File
```bash
# Passwords
ICECAST_ADMIN_PASSWORD=your_strong_admin_password
ICECAST_SOURCE_PASSWORD=your_strong_source_password
ICECAST_RELAY_PASSWORD=your_strong_relay_password
ICECAST_ADMIN_USERNAME=admin

# Image versions
ICECAST_IMAGE=infiniteproject/icecast
LIQUIDSOAP_IMAGE=savonet/liquidsoap:main

# Timezone
TIMEZONE=Europe/Kiev

# Ports
ICECAST_EXTERNAL_PORT=8100
ICECAST_INTERNAL_PORT=8000
```

### Changing Settings

**Passwords and users:**
- Edit the `.env` file
- Run `./generate-config.sh` to regenerate `icecast.xml`
- Restart containers: `docker compose restart`

**Image versions:**
- Change `ICECAST_IMAGE` and `LIQUIDSOAP_IMAGE` variables in `.env`
- Recreate containers: `docker compose up -d --force-recreate`

**Timezone:**
- Change the `TIMEZONE` variable in `.env`
- Restart liquidsoap: `docker compose restart liquidsoap`

**Ports:**
- Change `ICECAST_EXTERNAL_PORT` in `.env`
- Restart: `docker compose restart`

## Configuration Management

This project uses secure configuration management:

- **Environment variables**: All passwords and settings are stored in `.env` file
- **Template system**: `icecast.xml` is automatically generated from template
- **Git safety**: Sensitive files are excluded from version control
- **Easy deployment**: One script generates all configurations

### Configuration Files

- `.env` - Contains all passwords and settings (not in git)
- `.env.example` - Template for environment variables
- `icecast/icecast.xml.template` - Template for Icecast configuration
- `generate-config.sh` - Script to generate config from template

## Security Notes

- Never commit `.env` or `icecast.xml` to git
- Change default passwords before deployment
- Use strong passwords (recommended: 16+ characters)
- Template files are safe to commit (no passwords)

### Changing Schedule
Edit the `liquidsoap/radio.liq` file, switch section with time conditions.

### Changing Audio Quality
In the `radio.liq` file, change the `%mp3(bitrate=128)` parameter to the desired bitrate.

## License

This project uses open source software:
- [Liquidsoap](https://www.liquidsoap.info/) - GPL v2
- [Icecast](https://icecast.org/) - GPL v2

---

**Author**: kk  
**Creation Date**: April 2025

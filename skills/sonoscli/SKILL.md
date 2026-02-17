---
name: sonoscli
description: Control Sonos speakers (discover/status/play/volume/group).
homepage: https://sonoscli.sh
metadata:
  {
    "clawdbot": {
      "emoji": "🔊",
      "requires": { "bins": ["sonos"] },
      "install": [
        {
          "id": "go",
          "kind": "go",
          "module": "github.com/steipete/sonoscli/cmd/sonos@latest",
          "bins": ["sonos"],
          "label": "Install sonoscli (go)"
        }
      ],
      "version": "1.1.0"
    }
  }
---

# Sonos CLI

Use `sonos` to control Sonos speakers on the local network.

## Quick Start

```bash
# Discover speakers on your network
sonos discover

# Check status of a specific speaker
sonos status --name "Kitchen"

# Playback control
sonos play --name "Kitchen"
sonos pause --name "Kitchen"
sonos stop --name "Kitchen"

# Volume control (0-100)
sonos volume set 15 --name "Kitchen"
sonos volume up 5 --name "Kitchen"
sonos volume down 5 --name "Kitchen"
```

## Common Tasks

### Grouping
```bash
# Check group status
sonos group status

# Join speakers together
sonos group join --name "Living Room" --master "Kitchen"

# Unjoin from group
sonos group unjoin --name "Living Room"

# Party mode (all speakers play same thing)
sonos group party

# Solo mode (disconnect all)
sonos group solo
```

### Favorites
```bash
# List saved favorites
sonos favorites list

# Play a favorite
sonos favorites open --name "Kitchen" --favorite "Jazz Playlist"
```

### Queue Management
```bash
# View current queue
sonos queue list --name "Kitchen"

# Play queue
sonos queue play --name "Kitchen"

# Clear queue
sonos queue clear --name "Kitchen"
```

### Spotify Integration
```bash
# Search Spotify (requires SMAPI setup)
sonos smapi search --service "Spotify" --category tracks "query"

# Note: Spotify Web API search requires SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET
```

## Troubleshooting

### Speaker Not Found
If SSDP discovery fails, specify the speaker IP directly:
```bash
sonos status --ip 192.168.1.100
```

### Spotify Search Not Working
Spotify Web API integration is optional and requires:
```bash
export SPOTIFY_CLIENT_ID="your-client-id"
export SPOTIFY_CLIENT_SECRET="your-client-secret"
```

## Requirements

- **Go:** For building/installing sonoscli
- **Network:** Speakers must be on the same local network
- **SSDP:** Service discovery protocol must be enabled on your network

## Installation

```bash
# Install via Go
go install github.com/steipete/sonoscli/cmd/sonos@latest

# Or use the OpenClaw skill installer
# (see metadata.install section above)
```

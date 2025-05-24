# DisPlex Project

DisPlex is a program I built in my spare time. The source code can be found on my GitHub repository [mchestr/displex](https://github.com/mchestr/displex). DisPlex is a Discord bot with additional functionality that I use to automate managing my Plex media server and its users.

## Features

- **Web Server**: Implements OAuth2 flows and Discord Linked Role. Users can be assigned a role in Discord if they are invited to my Plex server.
- **Discord Bot**: Currently limited to responding to `~ping` commands.
- **User Statistics**: Script to update Discord user metadata to display how many hours users have streamed.
- **Token Management**: Script to clean up expired Discord tokens.
- **Request Management**: Script to automatically increase user request limits on Overseerr as they watch more Plex content.
- **Expandable**: Framework in place for additional features as needed.

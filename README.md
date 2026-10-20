# Omarchy Tau Agent Integration

Native integration for the [Tau AI Agent](https://github.com/right9code/tau) into the Omarchy Quattro desktop environment.

## Features
- **Binary Stub**: Builds and links `tau` directly into `~/.local/bin/tau`.
- **Omarchy Launcher Integration**: Registers `tau.desktop` using `omarchy-launch-tui`.
- **Default Agent Integration**: Plugs into Omarchy's `setup.default.agent` menu and sets Tau as the active default coding agent.
- **Shortcut Support**: Seamlessly triggers via `SUPER + SHIFT + CTRL + A` or `omarchy agent`.
- **Omarchy Theme Sync**: Reacts to Omarchy theme changes via `~/.config/omarchy/hooks/theme-set.d/`.

## Manual Installation
```bash
chmod +x hooks/post-install.sh
./hooks/post-install.sh
```

## Uninstallation
```bash
chmod +x hooks/post-remove.sh
./hooks/post-remove.sh
```

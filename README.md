# Wallhaven Fetcher Plugin

A DankMaterialShell widget that fetches high-quality wallpapers from [Wallhaven.cc](https://wallhaven.cc/).

## Features

- **One-Click Fetch**: Instantly download and set a random wallpaper directly from your bar.
- **Tag Filtering**: Search for specific themes (e.g., "anime", "cyberpunk", "nature").
- **Strict Tag Combinations**: Create sets of tags that must *all* be present in the image (e.g., "mountain, night" finds images with both tags).
- **Multiple Query Sets**: Add multiple different tag combinations. The plugin picks one set at random each time it fetches (e.g., Randomly choose between "Cars" OR "Nature").
- **Daily Automatic Updates**: Configure the plugin to automatically fetch a new wallpaper once every day at a specific time.

## Installation

1.  Place this folder in your DankMaterialShell plugins directory (usually `~/.config/DankMaterialShell/plugins/` or inside the `quickshell/PLUGINS` source folder if developing).
2.  Reload DankMaterialShell (`dms restart` or `dms ipc call plugins reload wallhavenFetcher`).
3.  Enable "Wallhaven Fetcher" in **Settings > Plugins**.
4.  Add the widget to your bar in **Settings > Dank Bar**.

## Configuration

Click the **Gear Icon** next to the plugin in Settings to configure:

### 1. Tag Combinations
This list allows you to define what kind of wallpapers you want.
- **Format**: Enter tags separated by commas.
- **Logic**: 
    - Comma-separated tags are treated as "AND" (Strict).
    - Example: `anime, rain` will strictly search for images containing *both* "anime" AND "rain".
- **Random Selection**: If you add multiple items to this list, the plugin will randomly pick *one* of the items to use for the search.
    - Item 1: `cyberpunk`
    - Item 2: `nature, forest`
    - Result: 50% chance of Cyberpunk, 50% chance of Forest Nature.

### 2. Daily Wallpaper
- **Toggle**: Enable/Disable automatic daily updates.
- **Update Time**: Set the target time in 24-hour format (e.g., `09:00` for 9 AM).
    - The plugin checks every minute.
    - If the current time is past the target time and no update has occurred *today*, it will fetch a new wallpaper.
    - **Note**: The computer/shell must be running for the check to occur. If you turn on your PC after the time, it will update immediately (once per day).

## Usage

- **Click the Icon**: Press the "Image Search" icon in your bar. A toast notification ("Fetching wallpaper...") will appear. The wallpaper will change automatically once downloaded.

## Troubleshooting

- **No Images Found**: If you use too many specific tags (e.g., "car, red, night, rain, ferrari"), Wallhaven might not have any images that match *all* of them. Try simplifying your tags.
- **Download Location**: Wallpapers are saved to `~/Pictures/Wallpapers/Wallhaven/`.

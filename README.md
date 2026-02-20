# Image Paste Fix

A tiny macOS menu bar app that fixes broken image pastes from Google.

## The Problem

When you copy an image from Google Search (or other Google products), the clipboard sometimes contains a URL or malformed data instead of the actual image. Pasting into another app gives you a link or nothing at all instead of the image.

## The Fix

Image Paste Fix runs silently in the background. When it detects a Google image copy, it downloads the real image and replaces the clipboard contents with proper PNG/TIFF data — so your paste just works.

## Features

- Lives in the menu bar, uses no Dock space
- Enable/disable with one click
- Optional launch at login
- macOS 13 Ventura or later

## Building

Open `ImagePasteFix.xcodeproj` in Xcode and build, or use Swift Package Manager:

```sh
swift build -c release
```

## License

MIT — see [LICENSE](LICENSE).

© 2026 Colin Weir

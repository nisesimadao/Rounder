Show HN: I wanted rounded corners on my old MacBook, so I built this

I wanted rounded corners on my old MacBook.

Modern Macs look great, but older ones still have sharp display edges, and it bothered me more than it should have. I wanted a simple, non-invasive way to get that modern look without replacing hardware.

So I made "Rounder" — a small macOS app that adds software-based rounded corners to your Mac display.

It runs quietly in the background as a menu bar app and uses native macOS APIs (SwiftUI + Core Graphics) to draw an overlay at the screen level (`NSWindow.Level.screenSaver`).

Features:
- Lightweight menu bar app
- Smooth overlay that doesn’t interfere with normal usage
- Fully local, no data collection
- Open source (MIT)

I've been using it daily for a while now and it's been stable.

External display support is something I’d like to explore next.

GitHub: https://github.com/nisesimadao/rounder  
Download: https://github.com/nisesimadao/rounder/releases

Would love feedback or ideas — especially edge cases I might have missed.
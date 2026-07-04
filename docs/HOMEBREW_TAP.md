# Homebrew Tap

Rounder is available through the public tap at `nisesimadao/homebrew-rounder`.

## Install

```bash
brew tap nisesimadao/rounder
brew install --cask rounder
```

## Tap Repository

- https://github.com/nisesimadao/homebrew-rounder

## Current Cask

```ruby
cask "rounder" do
  version "2.1.4"
  sha256 "e2284afa5f0da4e3c663b8bc36f7a208fc07cacf13fdfab0ee6f4052f51e441a"

  url "https://github.com/nisesimadao/Rounder/releases/download/v#{version}/Rounder.zip"
  name "Rounder"
  desc "Menu-bar app that rounds macOS screen corners"
  homepage "https://github.com/nisesimadao/Rounder"

  depends_on macos: :sonoma

  app "Rounder.app"

  zap trash: [
    "~/Library/Preferences/com.nisesimadao.Rounder.plist",
    "~/Library/Containers/com.nisesimadao.Rounder",
  ]

  caveats <<~EOS
    Rounder is currently distributed without a paid Developer ID signature.
    If macOS blocks the first launch, right-click Rounder.app and choose Open.
  EOS
end
```

## Validation

```bash
brew tap nisesimadao/rounder
brew info --cask nisesimadao/rounder/rounder
brew fetch --cask nisesimadao/rounder/rounder
```

`brew audit --cask --new` currently requires newer Command Line Tools on this Mac, so validate with `brew info` and `brew fetch` here until CLT is updated.

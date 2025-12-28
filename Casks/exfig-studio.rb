# Homebrew Cask formula for ExFig Studio
# This file is a template for the alexey1312/homebrew-exfig tap.
# The actual formula is maintained in the homebrew-exfig repository
# and updated automatically by the release-app.yml workflow.
#
# To install:
#   brew tap alexey1312/exfig
#   brew install --cask exfig-studio
#
# Or directly:
#   brew install --cask alexey1312/exfig/exfig-studio

cask "exfig-studio" do
  version "1.0.0"
  sha256 "PLACEHOLDER_SHA256"

  url "https://github.com/alexey1312/ExFig/releases/download/studio-v#{version}/ExFigStudio-#{version}.dmg"
  name "ExFig Studio"
  desc "Visual configuration editor for ExFig - export Figma assets to iOS, Android, Flutter"
  homepage "https://github.com/alexey1312/ExFig"

  depends_on macos: ">= :sequoia"

  app "ExFig Studio.app"

  zap trash: [
    "~/Library/Application Support/ExFig Studio",
    "~/Library/Caches/io.exfig.studio",
    "~/Library/Preferences/io.exfig.studio.plist",
    "~/Library/Saved Application State/io.exfig.studio.savedState",
  ]
end

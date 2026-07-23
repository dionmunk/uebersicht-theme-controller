#!/bin/bash
# Prints the menu-bar strip's darkness (0=white .. 100=black), the signal macOS keys
# its menu-bar text color off. Used by theme-controller to pick light/dark mode.
#
# Requires: Screen Recording permission for the Übersicht app (System Settings >
# Privacy & Security > Screen Recording) so screencapture returns real pixels, and
# Xcode Command Line Tools (swiftc) to build the helper on first run.
DIR="$(cd "$(dirname "$0")" && pwd)"

# Compile the Swift helper on first run (or after the source changes).
if [ ! -x "$DIR/menubar-darkness" ] || [ "$DIR/menubar-darkness.swift" -nt "$DIR/menubar-darkness" ]; then
    swiftc -O "$DIR/menubar-darkness.swift" -o "$DIR/menubar-darkness" 2>/dev/null
fi

IMG="/tmp/ubersicht-menubar.png"
screencapture -x "$IMG" && "$DIR/menubar-darkness" "$IMG"

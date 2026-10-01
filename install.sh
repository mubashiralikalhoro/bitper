#!/bin/sh
# One-step setup for Bitper: tools -> models -> build -> /Applications -> launch.
# Safe to run again; it skips anything already done.
set -e
cd "$(dirname "$0")"

step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }

[ "$(uname -m)" = arm64 ] || echo "Note: Bitper is tuned for Apple Silicon. It will run slowly on Intel Macs."

step "Checking developer tools"
if ! xcode-select -p >/dev/null 2>&1; then
    xcode-select --install
    echo "Finish installing the Command Line Tools, then run ./install.sh again."
    exit 1
fi
if ! command -v brew >/dev/null; then
    echo "Bitper needs Homebrew. Install it from https://brew.sh, then run ./install.sh again."
    exit 1
fi
for f in whisper-cpp llama.cpp; do
    brew list "$f" >/dev/null 2>&1 && echo "✓ $f" || brew install "$f"
done

step "Getting models"
mkdir -p models
fetch() { # <file> <url>
    if [ -s "models/$1" ]; then echo "✓ $1"; return; fi
    echo "Downloading $1"
    curl -L --fail --progress-bar -C - -o "models/$1.part" "$2"
    mv "models/$1.part" "models/$1"
}
fetch ggml-base.en.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin
fetch ggml-medium-q5_0.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium-q5_0.bin
fetch Qwen3.5-2B-Q4_K_M.gguf https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/resolve/main/Qwen3.5-2B-Q4_K_M.gguf

step "Installing models"
DEST="$HOME/Library/Application Support/Bitper/models"
mkdir -p "$DEST"
for f in models/*.bin models/*.gguf; do
    [ -s "$f" ] || continue
    name=$(basename "$f")
    if [ -s "$DEST/$name" ]; then echo "✓ $name"; continue; fi
    # -c makes an APFS clone: no extra disk space. Falls back to a normal copy.
    cp -c "$f" "$DEST/" 2>/dev/null || cp "$f" "$DEST/"
    echo "✓ $name"
done

step "Building Bitper"
./build.sh

step "Installing app"
APPS=/Applications
[ -w "$APPS" ] || { APPS="$HOME/Applications"; mkdir -p "$APPS"; }
pkill -x Bitper 2>/dev/null && while pgrep -x Bitper >/dev/null; do sleep 0.2; done || true
rm -rf "$APPS/Bitper.app"
mv Bitper.app "$APPS/"
open "$APPS/Bitper.app"

step "Done"
echo "Bitper is in your menu bar (the waveform icon). Your first recording will ask for microphone access."

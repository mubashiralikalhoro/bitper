# Bitper

**Private dictation in your Mac's menu bar.** Click the mic, speak, and get clean, punctuated text to copy, or press a shortcut in any app and have the text typed for you. Speak English or Urdu; the text always comes out in English.

Everything runs on your Mac. No account, no cloud, no subscription. Your audio never leaves the machine.

![Bitper: ready, listening, and a cleaned-up result](docs/screenshot.png)

## Features

- **One-click dictation** from the menu bar. Click the mic or press Space, speak, then click or press Space again.
- **Clean up text:** a small local AI model removes "um", "uh", stutters and false starts ("Thursday, no wait, Friday" becomes "Friday"), fixes punctuation, and turns spoken lists into bullet points. You can turn it off.
- **Urdu to English:** speak Urdu and Bitper writes English.
- **Dictate into any app:** set a shortcut (for example ⌥Space), press it in any text field, speak, press it again, and the text is typed where your cursor is. A small floating pill shows that it's listening.
- **History:** your last 10 dictations, with both the cleaned and the original text, ready to copy.
- **Fast:** about 1 second from when you stop talking to finished text on Apple Silicon.

## Requirements

- A Mac with Apple Silicon (M1 or newer). It also runs on Intel Macs, but slowly.
- macOS 14 Sonoma or newer
- [Homebrew](https://brew.sh)
- About 2.5 GB of free disk space for the models

## Install

```sh
git clone https://github.com/mubashiralikalhoro/bitper.git
cd bitper
./install.sh
```

The installer:

1. Checks for Xcode Command Line Tools (and starts their install if they're missing) and Homebrew.
2. Installs [whisper.cpp](https://github.com/ggml-org/whisper.cpp) and [llama.cpp](https://github.com/ggml-org/llama.cpp) with Homebrew.
3. Downloads the three models into `models/` (about 2 GB, one time only).
4. Copies the models to `~/Library/Application Support/Bitper/models`.
5. Builds `Bitper.app`, moves it to `/Applications` and opens it.

It's safe to run again. Steps that are already done are skipped. To update, `git pull` and run `./install.sh` again.

### First run

Look for the waveform icon in your menu bar.

1. **Microphone:** the first recording asks for microphone access. Click **Allow**.
2. **Shortcut (optional):** open **⋯ → Settings**, click **Click to set** and press a combination that includes ⌃ Control or ⌥ Option, for example ⌥Space. Bitper rejects shortcuts that macOS or another app already uses.
3. **Typing (optional):** in the same Settings page, click **Allow…** next to Typing and turn Bitper on under **Privacy & Security → Accessibility**. Without this, shortcut dictation copies the text to your clipboard instead of typing it.

To start Bitper when you log in: **System Settings → General → Login Items → +**, then choose Bitper.

## Use

| To | Do this |
|---|---|
| Dictate in the panel | Click the menu bar icon, click the mic or press **Space**, speak, press **Space** again |
| Dictate into any app | In a text field, press your shortcut, speak, press it again. **Esc** cancels |
| Speak Urdu | Switch **English / Urdu** at the top of the panel |
| Copy the result | **Copy** or **⌘C**. **Show original** shows the text before cleanup |
| See past dictations | **⋯ → History**, then click one to open it |
| Change settings | **⋯ → Settings** |

## How it works

```
mic → 16 kHz WAV → whisper.cpp → simple rules → Qwen 3.5 2B (llama.cpp) → text
                   (speech to text,  (drop um/uh,   (punctuation, corrections,
                    Urdu→English)     repeats)       lists; English only)
```

| Model | Size | Used for |
|---|---|---|
| `ggml-base.en.bin` | 148 MB | English speech |
| `ggml-medium-q5_0.bin` | 540 MB | Urdu speech, translated to English by Whisper |
| `Qwen3.5-2B-Q4_K_M.gguf` | 1.3 GB | Text cleanup |

The cleanup model is told to keep your exact words and never answer or rephrase. As a safety net, if its output contains words you didn't say (for example, it answered a question you dictated), Bitper discards it and shows the plain transcript instead. The model loads while you're speaking and unloads after 5 idle minutes to free memory.

These models were picked by benchmarking seven small models on messy test dictations. Smaller ones rewrote sentences, invented words or answered questions instead of cleaning them.

## Troubleshooting

**No waveform icon in the menu bar.** The menu bar may be full; quit another menu bar app or hold ⌘ and drag icons to make room. Check that Bitper is running in Activity Monitor.

**"Microphone access is off".** Open **System Settings → Privacy & Security → Microphone** and turn on Bitper.

**Shortcut dictation copies instead of typing.** Allow Bitper under **Privacy & Security → Accessibility**. If you rebuilt the app, macOS forgets this permission: remove Bitper from the list with **−**, then add it again.

**"Speech model missing".** Run `./install.sh` again to download it.

**"Couldn't run whisper-cli".** Run `brew install whisper-cpp`.

**Text isn't cleaned up.** Check that **Clean up text** is on in Settings, and that llama.cpp is installed (`brew install llama.cpp`).

## Build from source

```sh
./build.sh          # builds Bitper.app in this folder and runs its self-test
open Bitper.app
```

The whole app is one file, `Bitper.swift` (SwiftUI, no Xcode project needed).

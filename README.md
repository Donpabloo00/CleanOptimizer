# CleanOptimizer

A premium, native macOS application designed to clean, optimize, and manage your Mac.

**Developed and Maintained by:** [AppConsultDeck](https://github.com/Donpabloo00)

---

## Key Features

### 🧹 System Cleaner
- Scans user caches, system logs, Safari cache, and temp files.
- Displays folder sizes and lets you select specific categories for safe deletion.

### ⚡ Performance Optimizer
- Purges inactive physical RAM memory.
- Rebuilds the Spotlight search index.
- Tunes standby power settings for instant wake-up.
- Securely prompts for administrator authorization once using an AppleScript runner.
- Includes a terminal log viewer console.

### 📦 App Uninstaller
- Scans installed apps in `/Applications`.
- Calculates application bundle sizes asynchronously.
- Moves selected apps to the Trash.
- Automatically cleans leftover configuration and cache files in `~/Library/`.

### ✉️ Mailbox Cleaner
- Connects natively to the macOS Mail.app.
- Provides a clean queue view of emails.
- Quick clean action buttons:
  - 🔴 **Delete (Red)**: Moves the email to the Trash.
  - 🟢 **Keep (Green)**: Marks the email as read and skips to the next.

---

## Technical Specifications

- **Language & Frameworks**: Swift 5.9, SwiftUI, AppKit (native macOS APIs)
- **Architecture**: Non-sandboxed standalone application for low-level system access.
- **Dependencies**: ShellOut library.

---

## Installation & Build

1. Open the Swift Package in Xcode or compile via CLI:
   ```bash
   cd CleanOptimizerApp
   swift build -c release
   ```
2. Build the DMG installer using the included packaging script:
   ```bash
   ./package_dmg.sh
   ```
3. Run `CleanOptimizer.dmg` and install the app!

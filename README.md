# BSTextEditor

A native macOS text editor prototype built with SwiftUI and AppKit.

## Current Milestone

This first slice focuses on the editor shell:

- Multi-window SwiftUI app structure
- One workspace window per project folder
- Folder picker from the app command menu and empty start window
- Recursive file tree sidebar
- UTF-8 text buffer loading, editing, dirty-state tracking, and save
- AppKit-backed `NSTextView` editor surface
- JSON-backed settings store at `~/Library/Application Support/BSTextEditor/settings.json`
- Theme, language, terminal, and LSP service placeholders

## Build

```sh
./build.sh
```

## Run

```sh
./run.sh
```

## Next Work

The next useful feature pass should add tabs and a real file-buffer registry, then replace the terminal placeholder with a PTY-backed terminal view.

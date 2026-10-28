# Security

Show Desktop hides and restores your windows, so it is built to do that with as little access as possible.

## Reporting a vulnerability

Please report security problems privately through **Security → Report a vulnerability** on this repository, not in a public issue. You'll get a reply within a few days.

## What Show Desktop can access

| | |
|---|---|
| **Running apps** | Hides and unhides regular apps with `NSRunningApplication`, the same as pressing ⌘H, and brings Finder or the app you were using to the front. It never closes or quits anything. |
| **Window owners** | Asks macOS which app owns each on-screen window and which layer it's on, so apps come back in the same order. Without Screen Recording permission, which it never requests, macOS doesn't give it window titles or contents. |
| **Finder** | Optional. Sends Apple Events to Finder to minimize its open windows and restore exactly those windows afterwards. macOS asks you first, and you can turn it off in the app's menu or in System Settings → Privacy & Security → Automation. |
| **Its own settings** | The shortcut you picked and whether to minimize Finder windows, stored in the app's sandbox container. |

## What it can't access

- **The internet.** The app runs in the App Sandbox without a network entitlement, so macOS blocks every connection. CI checks every build for this.
- **Your files.** It has no file entitlements, so the sandbox blocks every document, download and folder.
- **Other apps' data.** Its only Apple Events entitlement is for Finder, and the scripts it sends only change whether Finder windows are minimized.
- **Your keystrokes.** The shortcut uses the Carbon hot key API, which only reports that one shortcut. No Accessibility or Input Monitoring permission is needed.
- **Your screen.** It never requests Screen Recording permission and never captures the screen.

Check it yourself on any copy of the app:

```bash
codesign -d --entitlements - "/Applications/Show Desktop.app"
```

## How it handles things

- The only values put into the Finder scripts are window ID numbers that Finder itself returned, so nothing on screen can change what a script does.
- What it remembers between the two clicks (process IDs and Finder window IDs) is kept in memory only and forgotten as soon as the windows are back.
- It has no dependencies. Every line that runs is in this repository.

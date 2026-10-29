# Changelog

## 0.2.0 (2026-10-28)

- **Record your own shortcut:** right-click the menu bar icon and choose Keyboard Shortcut → Record Shortcut… to use any combination with ⌃, or ⌘ with ⇧ or ⌥. Function keys like F13 work on their own. Shortcuts that would get in the way of typing (like ⌥E, which types an accent) or that macOS already uses (like ⇧⌘3 for screenshots) are refused, so a shortcut can't break something you rely on.
- **Clashes:** when macOS reports that another app already has your shortcut, the Keyboard Shortcut menu says so.
- **Function keys and arrows** show up next to Show Desktop in the menu, like any other shortcut.
- The shortcut you picked in 0.1.0 carries over.

## 0.1.0 (2026-10-28)

First release.

- **Show the Desktop** with one click on the menu bar icon, or with ⌃⇧D from any app.
- **Put everything back** with a second click: only the apps that were open, in the same order, with the one you were using in front. Apps you'd already hidden stay hidden.
- **Finder windows** are minimized too and restored afterwards. You can turn this off.
- **Shortcut choices:** ⌃⇧D, ⌃⌥D, ⌃⌥⌘H or none.
- **Open at login**, on by default and easy to turn off.
- Runs in the App Sandbox with no network or file access, and needs no Accessibility or Screen Recording permission.

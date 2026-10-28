# Contributing

Thanks for helping out! Bug reports, ideas and pull requests are all welcome.

## Getting started

You need macOS 14 or later and Swift 6 (Xcode 16 or the Command Line Tools).

```bash
swift test                # run the tests
scripts/build-app.sh      # build "Show Desktop.app" into ./build
open "build/Show Desktop.app"
```

The logic that decides what to hide and what to bring back lives in `Sources/ShowDesktopCore`, with tests in `Tests/ShowDesktopCoreTests`. The menu bar app, shortcut and Finder scripts are in `Sources/ShowDesktop`.

## Ground rules

- **No network access, ever.** Pull requests that add a network entitlement or third-party analytics won't be merged.
- **No new dependencies** without a very good reason. The app has none today, which keeps it easy to audit.
- **Keep permissions minimal.** New features shouldn't need Accessibility, Screen Recording, file access or Apple Events to anything but Finder.
- Run `swift test` before opening a pull request, and add tests for changes to `ShowDesktopCore`.
- Keep commits small, with a short message saying what changed and why.

## Security issues

Please don't open public issues for vulnerabilities. See [SECURITY.md](SECURITY.md).

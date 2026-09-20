# Napsafe

A watchOS-only app that lets you nap on transit and wakes you before your stop. Pick a destination, set how far out you want to be alerted, start a session, and Napsafe tracks your location in the background. When you enter the alert radius it fires haptics and time-sensitive notifications until you dismiss the alarm.

**Display name:** Napsafe  
**Bundle ID:** `com.napsafe.NapsafeWatch`  
**Platform:** watchOS 10.0+ (Watch-only; no iPhone companion app)

## Features

- **Destination lists** on the home screen:
  - **Nearby** — curated Japanese stations sorted by distance from your current location
  - **Favorites**, **Most Used** (top 5), and **Recent** (last 10), persisted in `UserDefaults`
- **Search** — MapKit local search for stations or addresses
- **Session setup** — choose alert distance (`800 m`, `1 km`, or `1.5 km`) and transport mode (Train, Subway, or Bus); optional map preview of the destination
- **Active session** — live distance to destination, nap duration, map snapshot background; tracking uses Core Location with background updates
- **Arrival alert** — when distance ≤ alert radius: repeating Watch haptics plus time-sensitive local notifications (“WAKE UP NOW”) until you stop the alarm
- **Nap totals** — cumulative nap minutes shown on the home screen (long-press to reset)

## Requirements

- macOS with **Xcode 16.0** or newer
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (project is defined by `project.yml`; a checked-in `.xcodeproj` is also present)
- Apple Developer account for device/signing (Automatic signing is configured in `project.yml`)
- Physical Apple Watch or watchOS Simulator for running

## Setup / Build

1. Clone the repository:

   ```bash
   git clone https://github.com/masapong/napsafe-watch.git
   cd napsafe-watch
   ```

2. (Recommended) Regenerate the Xcode project from `project.yml`:

   ```bash
   brew install xcodegen   # if needed
   xcodegen generate
   ```

3. Open the project:

   ```bash
   open NapsafeWatch.xcodeproj
   ```

4. Select the **NapsafeWatch** scheme, a watchOS destination, then Build & Run.

`project.yml` sets `PRODUCT_BUNDLE_IDENTIFIER` to `com.napsafe.NapsafeWatch`, `INFOPLIST_FILE` to `Resources/Info.plist`, entitlements to `Resources/NapsafeWatch.entitlements`, and deployment target **watchOS 10.0**.

## Usage

1. On first launch, allow **location** (Always) and **notifications** when prompted.
2. Choose a destination from Nearby / Favorites / Most Used / Recent, or tap **Search Destination**.
3. In Settings, pick alert distance and transport mode. Optionally open **Preview on Map**.
4. Tap **Start Napsafe** to begin tracking.
5. During the session, distance and nap time update on screen. When you are within the alert distance, the alarm runs until you tap **Stop Alarm** / **Cancel**.

## Permissions & entitlements

### Info.plist (`Resources/Info.plist`)

| Key | Purpose |
|-----|---------|
| `NSLocationWhenInUseUsageDescription` | Location used to alert you before your destination |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | Background position tracking during a nap |
| `UIBackgroundModes` → `location` | Continue location updates while the app is in the background |
| `WKApplication` / `WKWatchOnly` | Standalone Watch app |

### Entitlements (`Resources/NapsafeWatch.entitlements`)

- `com.apple.developer.location.push`
- `com.apple.developer.maps`

### Runtime authorization

- Core Location: `requestAlwaysAuthorization()`, `allowsBackgroundLocationUpdates = true`
- User Notifications: alert + sound for arrival / wake-up alerts

## Project layout

```
NapsafeWatch.xcodeproj/   # Xcode project (also regenerable via XcodeGen)
project.yml               # XcodeGen spec
Resources/
  Info.plist
  NapsafeWatch.entitlements
  Assets.xcassets/
Sources/
  NapsafeWatchApp.swift
  Models/                 # Destination, NapSession, TransportMode
  Services/               # DestinationStore, LocationManager, SessionManager
  Views/                  # ContentView, ActiveSessionView, AlertSettingsView,
                          # LocationSearchView, MapPreviewView
```

## License

No license file is included in this repository. All rights reserved by the author unless otherwise stated.

# AtriaWall AI

Premium iOS gallery wall planner built with SwiftUI.

## What It Does

AtriaWall AI helps DIY homeowners design, preview, and hang gallery walls with more precision than a simple visual mockup app.

- Editable wall projects with real wall dimensions
- Drag-and-drop frame canvas with scale-preserving layout
- Premium layout templates for salon walls, grids, staircases, and triptychs
- Photo import for family photos, artwork, and prints
- Gemini-powered AI layout plans with local fallback suggestions
- Exact nail position guide based on frame size and hardware offset
- ARKit preview surface for live wall alignment
- Custom RevenueCat-ready paywall with weekly, monthly, yearly plans

## Project

Open:

```bash
AtriaWallAI.xcodeproj
```

The shared scheme is:

```bash
AtriaWallAI
```

Minimum target:

```bash
iOS 16.0
```

## Local Secrets

Do not hardcode or commit API keys.

Copy:

```bash
Config/Secrets.example.xcconfig
```

to:

```bash
Config/Secrets.xcconfig
```

Then fill:

```xcconfig
GEMINI_API_KEY = your_gemini_key
GEMINI_MODEL = gemini-3.5-flash
REVENUECAT_API_KEY = your_revenuecat_public_sdk_key
PRODUCT_BUNDLE_IDENTIFIER = com.triphabibi.atriawallai
```

`Config/Secrets.xcconfig` is ignored by git.

## RevenueCat

Use one entitlement:

```text
pro
```

Use one offering:

```text
default
```

Products:

- `com.triphabibi.atriawallai.pro.weekly`
- `com.triphabibi.atriawallai.pro.monthly`
- `com.triphabibi.atriawallai.pro.yearly`

Suggested USD prices are listed in [AppStore/iap-products.json](AppStore/iap-products.json).

## Gemini

The app calls Gemini through `GeminiDesignService` using the `x-goog-api-key` header. If no key is configured, the app returns a curated local plan so the UI remains usable.

Because a key was pasted into chat during planning, rotate or restrict that key before any production use.

## Current Limits

This repo was scaffolded on Windows, where Xcode and Swift are not available. The code and project files were statically checked, but final compile/test must be run on macOS with Xcode.

Suggested macOS check:

```bash
xcodebuild -project AtriaWallAI.xcodeproj -scheme AtriaWallAI -destination 'platform=iOS Simulator,name=iPhone 16' test CODE_SIGNING_ALLOWED=NO
```

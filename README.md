# AtriaWall AI

Premium iOS gallery wall planner built with SwiftUI.

## What It Does

AtriaWall AI helps DIY homeowners design, preview, and hang gallery walls with more precision than a simple visual mockup app.

- Scan your real wall: take a live photo or attach several wall photos, tag corner walls, and measure real width/height with AR (with a manual fallback)
- Design on the real photo: a Gemini image model renders a photorealistic gallery wall directly onto your wall picture, respecting corners and wall size
- Multiple walls per project with a wall selector and per-wall dimensions
- Editable wall projects with real wall dimensions
- Drag-and-drop frame canvas that uses your captured wall photo as the backdrop
- Premium layout templates for salon walls, grids, staircases, and triptychs
- Photo import for family photos, artwork, and prints
- Gemini-powered AI layout plans with local fallback suggestions
- Exact nail position guide based on frame size and hardware offset
- ARKit preview surface for live wall alignment
- Native StoreKit paywall with weekly, monthly, yearly plans

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
GEMINI_MODEL = gemini-2.5-flash
GEMINI_IMAGE_MODEL = gemini-2.5-flash-image
PRODUCT_BUNDLE_IDENTIFIER = com.triphabibi.atriawallai
```

`GEMINI_MODEL` powers the editable layout plans. `GEMINI_IMAGE_MODEL` powers the
photorealistic "Design on My Wall" render. If no key is configured, layout plans
fall back to a curated local plan and the render step shows a clear prompt to add
a key. The image model defaults to `gemini-2.5-flash-image` if the key is omitted.

`Config/Secrets.xcconfig` is ignored by git.

## StoreKit Subscriptions

Create one auto-renewable subscription group in App Store Connect:

```text
AtriaWall Pro
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

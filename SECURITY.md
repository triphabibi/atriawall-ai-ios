# Security Notes

## API Keys

Do not commit Gemini keys or Apple private keys. Use:

```text
Config/Secrets.xcconfig
```

That file is ignored by git.

## Gemini Key Rotation

A Gemini API key was pasted into the planning conversation. Treat it as exposed:

1. Rotate it in Google AI Studio.
2. Prefer a new auth key.
3. Restrict the key to Gemini usage.
4. Add the replacement only to `Config/Secrets.xcconfig`.

## App Store Review

Before submission, confirm:

- Privacy policy covers AI processing, photo import, diagnostics, and purchases.
- Camera usage string matches AR preview behavior.
- Photo library usage string matches imported artwork/family photo behavior.
- StoreKit product identifiers in the app and App Store Connect match exactly.

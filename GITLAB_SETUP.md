# GitLab TestFlight Setup

This repository is connected to:

```text
https://gitlab.com/arsalantravelgkp-group/atriawall-ai-ios.git
```

## Required CI/CD Variables

Add these in GitLab under **Settings > CI/CD > Variables**:

```text
APP_STORE_CONNECT_KEY_ID
APP_STORE_CONNECT_ISSUER_ID
APP_STORE_CONNECT_API_KEY_P8_BASE64
GEMINI_API_KEY
REVENUECAT_API_KEY
```

`APPLE_TEAM_ID` and `PRODUCT_BUNDLE_IDENTIFIER` are already set in `.gitlab-ci.yml`:

```text
APPLE_TEAM_ID = QAT93YWVSF
PRODUCT_BUNDLE_IDENTIFIER = com.triphabibi.atriawallai
```

Use `APP_STORE_CONNECT_API_KEY_P8_BASE64` instead of pasting the raw `.p8` text when possible. On macOS or Linux, encode the key with:

```sh
base64 -i AuthKey_3UDB969SVY.p8 | pbcopy
```

On Windows PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\Users\relno\Downloads\AuthKey_3UDB969SVY.p8"))
```

## Running The Pipeline

Pushing to `main` runs the simulator test job. The TestFlight upload job is manual so it does not spend runner minutes by accident.

To deploy:

1. Open the GitLab project.
2. Go to **Build > Pipelines**.
3. Open the latest pipeline on `main`.
4. Press the manual play button for `testflight_upload`.

## Runner Requirement

iOS builds require macOS with Xcode. The pipeline is configured for GitLab's hosted macOS runner image:

```text
image: macos-26-xcode-26
tag: saas-macos-medium-m1
```

If the job stays pending, the GitLab account/project does not have access to that macOS runner. In that case the YAML is still correct, but the project needs an available macOS runner before TestFlight deployment can run.

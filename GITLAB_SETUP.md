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

Add this variable only when the project has access to a macOS runner:

```text
ENABLE_GITLAB_MACOS_RUNNER = true
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

Pushing to `main` always runs `ci_preflight` on a normal Linux runner. This confirms the repository files are present and reports whether required CI/CD variables exist without printing their values.

The iOS simulator test and TestFlight upload jobs require macOS with Xcode. They are intentionally skipped until `ENABLE_GITLAB_MACOS_RUNNER=true` is added.

To deploy:

1. Open the GitLab project.
2. Confirm a macOS runner is available for this project.
3. Add `ENABLE_GITLAB_MACOS_RUNNER=true` under **Settings > CI/CD > Variables**.
4. Go to **Build > Pipelines**.
5. Run a new pipeline on `main`.
6. After `ios_tests` passes, press the manual play button for `testflight_upload`.

## Runner Requirement

iOS builds require macOS with Xcode. The pipeline is configured for GitLab's hosted macOS runner image:

```text
image: macos-26-xcode-26
tag: saas-macos-medium-m1
```

If the job says **No matching runner available**, the GitLab account/project does not have access to that macOS runner. In that case the YAML is still correct, but the project needs an available macOS runner before TestFlight deployment can run.

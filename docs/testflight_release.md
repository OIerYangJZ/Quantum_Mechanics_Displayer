# TestFlight Release Architecture

This project does not maintain a public store-launch workflow. TestFlight distribution still requires Apple Developer signing and App Store Connect build processing, so the release architecture keeps those concerns narrow and beta-only.

## Current Release Path

1. Code lives on GitHub and changes are validated by the CI workflow.
2. A beta candidate is tagged from `main`, for example `v0.2.0-beta.1`.
3. The release owner runs the local release gate:

```bash
scripts/verify_release_candidate.sh
```

4. The release owner archives an iOS build with an Apple Developer team:

```bash
export DEVELOPMENT_TEAM=YOUR_TEAM_ID
export APP_BUNDLE_ID=io.github.oieryangjz.quantummechanicslab
export MARKETING_VERSION=0.2.0
export CURRENT_PROJECT_VERSION=1

scripts/archive_testflight.sh
```

5. To upload directly for TestFlight processing, provide App Store Connect API credentials:

```bash
export DEVELOPMENT_TEAM=YOUR_TEAM_ID
export APP_BUNDLE_ID=io.github.oieryangjz.quantummechanicslab
export MARKETING_VERSION=0.2.0
export CURRENT_PROJECT_VERSION=1
export UPLOAD_TO_TESTFLIGHT=1
export ASC_KEY_ID=YOUR_KEY_ID
export ASC_ISSUER_ID=YOUR_ISSUER_ID
export ASC_KEY_PATH=/secure/path/AuthKey_YOUR_KEY_ID.p8

scripts/archive_testflight.sh
```

## Required Apple Setup

- Apple Developer Program membership.
- A registered bundle identifier matching `APP_BUNDLE_ID`.
- An App Store Connect app record for the bundle identifier, used only for TestFlight build processing.
- A signing certificate and provisioning access for the selected `DEVELOPMENT_TEAM`.
- App Store Connect API access if direct command-line upload is used.

Keep `.p8` API keys, certificates, provisioning profiles, and passwords out of Git. Store them in a local secret manager or GitHub Actions secrets if automated upload is added later.

## GitHub Responsibilities

- Run `swift test`.
- Run `swift run QuantumMechanicsLabCoreSmokeTests`.
- Regenerate the Xcode project and fail if generator output drifts.
- Run simulator `build-for-testing` with signing disabled.
- Track TestFlight feedback as GitHub issues.

The default GitHub workflow intentionally does not upload to TestFlight. Upload requires Apple credentials and signing assets that should be introduced only after the Apple account, bundle ID, and tester group policy are finalized.

## Release Checklist

- `main` is clean and up to date with `origin/main`.
- `scripts/verify_release_candidate.sh` passes locally.
- GitHub CI passes on the target commit.
- `MARKETING_VERSION` matches the beta tag.
- `CURRENT_PROJECT_VERSION` is greater than any previous uploaded build number for that version.
- Manual UI checks in `UITestPlan.md` are complete for the target beta scope.
- Release notes summarize user-visible changes and known limitations.
- TestFlight tester group and feedback collection issue are prepared.

## References

- Apple: Upload builds - https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/
- Apple: App Store Connect API - https://developer.apple.com/documentation/appstoreconnectapi
- Apple: App build statuses - https://developer.apple.com/help/app-store-connect/reference/app-uploads/app-build-statuses/

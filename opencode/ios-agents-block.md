<!-- iOS app project: use ~/.dotfiles/scripts/ios-build.sh (build/test/run;
     -only-testing: filters pass through on test). Scheme + destination come from
     the committed .ios-build.env; machine overrides go in .ios-build.env.local
     (gitignored). Keep raw xcodebuild fallback only where the script differs.
     Evidence beyond green tests: UI-walkthrough attachments via
     `xcrun xcresulttool export attachments --path <xcresult> --output-path <dir>`,
     or `xcrun simctl io <udid> screenshot` — save to the vault worker-evidence
     folder, never into the repo. -->

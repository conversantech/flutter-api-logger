# 1.0.2

* Updated `mailer` dependency constraint to `'>=6.0.0 <8.0.0'` to support version `7.x.x`.
* Configured analyzer overrides to ignore `deprecated_member_use` warnings, ensuring backward compatibility with Flutter `>=3.24.0` while passing analysis on modern SDKs.
* Formatted all library files.
* Updated `README.md` with instructions for running the example.
* Updated `LICENSE` from MIT to BSD-3-Clause

# 1.0.1

* Updated `README.md` to reflect the new package name.

# 1.0.0

* Initial release of `flutter_api_tracker`.
* Updated Flutter SDK minimum requirement to 3.24.0.
* Updated Dart SDK minimum requirement to 3.5.0.
* Broadened dependency version ranges for improved compatibility.
* Global API interception using `HttpOverrides`.
* SQLite persistence for sessions and logs.
* Secret tap gesture activation (default 6 taps).
* HTML Email reports with SMTP support.
* Log sharing and export to text files.
* Real-time search and filtering.
* Automatic screen tracking via `NavigatorObserver`.

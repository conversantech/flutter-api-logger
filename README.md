# Flutter API Tracker ⚡

A production-ready, **zero-boilerplate** Flutter package that automatically tracks API calls and their call sequences. It intercepts all outgoing network traffic **globally** at the `dart:io` level — no modifications needed to your existing `Dio`, `http`, or `HttpClient` code.

---

## 🚀 Features

| Feature | Description |
|---|---|
| 🔌 **Zero-Config Interception** | Uses `HttpOverrides.global` to catch all network traffic without touching your code. |
| 📁 **Session-Based Logging** | API calls are grouped by **session** (one per app launch when enabled). |
| 🗄️ **SQLite Persistence** | All sessions and logs are stored locally via `sqflite`. History survives app restarts. |
| 📱 **Screen Tracking** | Associates each API call with the screen it was triggered from. |
| 🔍 **Search & Filter** | Search logs by URL, method, status code, or screen name in real-time. |
| 🕵️ **Secret Activation** | An invisible **6-tap** gesture (configurable) reveals the debugger UI. |
| 📧 **HTML Email Reports** | Export session summaries as professional HTML emails with `.txt` attachments. |
| 📤 **System Sharing** | Share session logs as text files directly via the system share sheet. |
| 📝 **Session Management** | Rename sessions for better organization or delete old ones to save space. |
| 📋 **Copy to Clipboard** | Copy any full log entry to clipboard with a single tap. |
| 💾 **Persistent Enable State** | The enabled/disabled state is saved via `shared_preferences` and restored on next launch. |
| ⚡ **Performance Optimized** | When disabled, all logging and database writes are completely skipped. |
| 🔒 **Release Mode Safe** | Disabled by default in Release builds unless you explicitly opt in. |

---

## 📦 Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_api_tracker: ^1.0.0
```


Then run:
```bash
flutter pub get
```

---

## 🛠️ Quick Start

### Step 1 — Initialize in `main()`

Call `ApiDebugger.initialize()` **before** `runApp()`. You **must** call `WidgetsFlutterBinding.ensureInitialized()` first because the package uses `sqflite` and `shared_preferences`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_api_tracker/flutter_api_tracker.dart';

void main() async {
  // CRITICAL: Must be called before any async work.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the debugger with optional parameters.
  await ApiDebugger.initialize(
    enableInRelease: false, // Default: false. Set true to allow in production.
    // Optional: SMTP configuration for email reports
    smtpConfig: SmtpConfig(
      server: 'smtp.gmail.com',
      port: 587,
      username: 'your-email@gmail.com',
      password: 'your-app-password',
      fromEmail: 'your-email@gmail.com',
      defaultRecipients: [
        const RecipientConfig(name: 'Dev Team', email: 'dev@example.com'),
        const RecipientConfig(name: 'QA Team', email: 'qa@example.com'),
      ],
    ),
  );

  runApp(const MyApp());
}
```

### Step 2 — Wrap your App

Wrap your root widget (or `MaterialApp`) with `ApiDebuggerWrapper`. This widget listens for the secret tap gesture to open the debugger UI.

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ApiDebuggerWrapper(
      child: MaterialApp(
        title: 'My App',
        // Add the navigator observer for automatic screen tracking.
        navigatorObservers: [ApiDebugger.navigatorObserver()],
        home: const MyHomePage(),
      ),
    );
  }
}
```

### Step 3 — Track Screen Names (Recommended)

For best results, use `ApiDebugger.route()` instead of `MaterialPageRoute` when navigating. This automatically logs the widget's class name as the "Screen" for each API call made on that screen.

```dart
Navigator.push(
  context,
  ApiDebugger.route(const MyProfilePage()),
);
```

> **How it works**: `ApiDebugger.route()` creates a `MaterialPageRoute` with `RouteSettings(name: page.runtimeType.toString())`. The `ApiNavigatorObserver` then picks up this name and stores it in the singleton `ScreenTracker`, which the HTTP interceptor reads when logging each request.

---

## 🚥 Advanced Usage

### Programmatic Control

Control the debugger from anywhere in your code:

```dart
import 'package:flutter_api_tracker/flutter_api_tracker.dart';

// Enable logging (starts a new session, persists state)
await ApiDebugger.enable();

// Disable logging (persists state, clears active session)
await ApiDebugger.disable();

// Check current status
bool isActive = ApiDebugger.isEnabled;

// Open the Session List screen directly
ApiDebugger.open(context);
```

### Custom Tap Trigger

Customize the number of taps required or provide your own trigger logic:

```dart
ApiDebuggerWrapper(
  tapCount: 10, // Require 10 rapid taps instead of the default 6.
  onTrigger: (BuildContext context) {
    // Your custom logic here.
    // Example: show a custom dialog before opening.
    ApiDebugger.open(context);
  },
  child: const MyAppBody(),
)
```

> **Tap timeout**: A tap sequence resets if there is more than a **2-second gap** between taps.

### Force-Override State on Launch

If you want to guarantee the debugger starts in a specific state (e.g., always enabled in debug builds, always disabled in staging):

```dart
await ApiDebugger.initialize(
  initiallyEnabled: true, // Forces ON regardless of the persisted state.
);
```

### Email Reporting & SMTP

To enable the "Send Email" feature, provide an `SmtpConfig` during initialization. You can also define `defaultRecipients` which will appear as selectable chips in the email form.

The exported email includes:
- **Professional HTML Body**: A summary of the session including total requests, success rate, and failure count.
- **Custom Header**: Session name, sender name, and timestamp.
- **Detailed Attachment**: A full `.txt` log file attached for deep inspection.

```dart
await ApiDebugger.initialize(
  smtpConfig: SmtpConfig(
    server: 'smtp.office365.com',
    port: 587,
    username: 'reports@company.com',
    password: 'password123',
    fromEmail: 'reports@company.com',
    defaultRecipients: [
      RecipientConfig(name: 'Lead Dev', email: 'lead@company.com'),
    ],
  ),
);
```

### Sharing Logs

From the **Log List** screen, you can tap the **Share** icon in the AppBar. This generates a complete `.txt` report of all logs in that session and opens the system share sheet.

Files are automatically named using the format:
`api_report_[session_name]_[mmddyyyy]_[hhmm].txt`

### Search & Filtering

Inside the **Log List** screen, tap the search icon to filter logs in real-time. You can filter by:
- **URL**: Matches any part of the endpoint path.
- **Method**: e.g., `GET`, `POST`.
- **Status Code**: e.g., `404`, `200`.
- **Screen Name**: The widget name where the call originated.

### Session Management

To keep your logs organized:
- **Rename**: Open the Log List for a session, tap the menu (three dots), and select **Edit Name**.
- **Delete**: Single sessions can be deleted from the same menu.
- **Clear All**: Use the "sweep" icon on the main Session List screen to wipe all local data.

---

## 📄 Debugger UI Overview

The debugger UI consists of three interconnected screens:

```
ApiSessionListScreen         ApiLogListScreen           ApiLogDetailScreen
┌─────────────────────┐     ┌─────────────────────┐   ┌─────────────────────┐
│  API Sessions        │     │  Logs for Session   │   │  Log Details        │
│  ─────────────────  │     │  ─────────────────  │   │  ─────────────────  │
│  ○ Session abc123   │──►  │  GET /posts/1 200   │──►│  [Request] [Response│
│  ○ Session def456   │     │  POST /posts  201   │   │                     │
│  ○ Session ghi789   │     │  DELETE /posts 404  │   │  URL, Method, Status│
│  [Enable] [Clear]   │     │                     │   │  Headers, Body      │
└─────────────────────┘     └─────────────────────┘   └─────────────────────┘
```

| Screen | Description |
|---|---|
| **Session List** | Shows all recorded sessions. **Current session** is highlighted with a pulsing green dot and primary colors. Each card shows the **API count**. Includes Toggle and "Clear All". |
| **Log List** | Shows all API calls in a session. Use the **Search bar** to filter. The AppBar shows the session name. Contains **Email**, **Share**, and **Session Menu** (Rename/Delete). |
| **Log Detail** | Two tabs: **Request** (URL, method, time, screen, headers, body) and **Response** (status code, headers, body). Features syntax highlighting and clipboard copy. |

---

## 🗂️ Data Models

### `ApiLogModel`
Represents a single intercepted HTTP call.

| Property | Type | Description |
|---|---|---|
| `id` | `String` | Unique UUID for the log entry. |
| `sessionId` | `String` | The session this log belongs to. |
| `method` | `String` | HTTP method (`GET`, `POST`, `PUT`, etc.). |
| `url` | `String` | The full request URL. |
| `requestHeaders` | `Map<String, String>?` | Request headers. |
| `requestBody` | `dynamic` | Request body (auto-formatted if JSON). |
| `responseHeaders` | `Map<String, String>?` | Response headers. |
| `responseBody` | `dynamic` | Response body (auto-formatted if JSON). |
| `statusCode` | `int?` | HTTP response status code. |
| `timestamp` | `DateTime` | When the request was initiated. |
| `duration` | `Duration` | How long the request took. |
| `screenName` | `String?` | The screen that initiated the request. |
| `isError` | `bool` | `true` if the status code indicates an error. |

### `ApiSessionModel`
Represents a single debugging session (one per app launch when enabled).

| Property | Type | Description |
|---|---|---|
| `id` | `String` | Unique UUID for this session. |
| `startTime` | `DateTime` | When this session was started. |

---

## ❌ Limitations

- **🌐 No Web Support**: `HttpOverrides` and `dart:io` are not available on Flutter Web. The package silently no-ops on Web.
- **📦 Interception Level**: Intercepts at the raw `dart:io` `HttpClient` level. It captures data after your app processes it but before it's sent over the wire. This means multipart form data bodies may not be human-readable.
- **⚠️ Sensitive Data**: All request/response data, including auth tokens and payloads, is stored in the local SQLite database. **Do not enable `enableInRelease: true` in production apps that handle sensitive user data** without a clear security review.

---

## 🔒 Safety & Performance

- **SSL/TLS Safe**: The package does not interfere with certificate validation, SSL handshakes, or `badCertificateCallback`.
- **No Overhead When Disabled**: All interception code returns immediately when `isEnabled` is `false`.
- **Session Memory Cap**: The in-memory log list is capped at **200 entries** per session to prevent excessive memory usage. Older entries roll off but remain in the database.
- **Singleton Services**: `ApiLogService` and `ApiDatabaseService` are singletons, ensuring a single shared state and database connection.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to open an issue or submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -m 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

---

## Created & Maintained By

This package is created and maintained by [Conversantech](https://conversantech.com).

## License

This project is licensed under the BSD-3-Clause License - see the [LICENSE](LICENSE) file for details.
Copyright (c) 2026 Conversantech.


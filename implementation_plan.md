# AcadHack Mobile: Implementation Plan 📱

**Goal**: Create a native Android app that wraps `app.acadally.com` and injects the AcadHack solver logic.

## 1. The Architecture
We will use **Flutter**. It has a superior WebView plugin (`webview_flutter`) that allows robust JavaScript injection and communication compared to Kivy.

### Core Components
1.  **Native Interface (Flutter/Dart)**:
    *   **Config Screen**: A native UI form to set API Key, Model, and Settings.
    *   **WebView Widget**: Displays `app.acadally.com`.
    *   **Control Panel**: A native "Floating Action Button" (FAB) overlay to Toggle Automation.

2.  **The "Payload" (JavaScript)**:
    *   This is a rewritten version of `scraper.py` + `AutomationController`.
    *   It does **not** contain the Gemini API usage directly (to hide API keys and avoid CORS issues).
    *   It focuses on DOM manipulation: `findQuestion()`, `clickOption()`, `clickSubmit()`.

3.  **The Bridge (MethodChannels)**:
    *   **JS -> Dart**: When the JS finds a question, it sends a message `JavaScriptChannel` to Flutter: `{ type: 'QUESTION_FOUND', data: { ... } }`.
    *   **Dart -> Gemini**: The Flutter app captures this message, calls the Gemini API (native HTTP call), and gets the answer ("B").
    *   **Dart -> JS**: Flutter injects `clickAnswer('B')` back into the WebView.

---

## 2. Technical Stack
*   **Framework**: Flutter (Dart)
*   **Plugins**:
    *   `webview_flutter`: For the browser engine.
    *   `google_generative_ai`: Official Gemini Dart SDK.
    *   `shared_preferences`: For saving API keys locally.
    *   `flutter_dotenv`: For managing environment variables.

---

## 3. Project Structure (`acadhack-mobile/`)
```
lib/
├── main.dart           # Entry point
├── config.dart         # Configuration storage
├── gemini_service.dart # AI Logic
├── webview_screen.dart # The Main Browser UI
└── assets/
    └── injector.js     # The JavaScript payload
```

---

## 4. Roadmap

### Phase 1: Setup & Prototype
1.  Initialize Flutter project.
2.  Implement `WebViewWidget` pointing to `app.acadally.com`.
3.  Inject a simple test script to prove control.

### Phase 2: The Logic Port
1.  **JavaScript**: Translate `scraper.py` logic to `injector.js`.
2.  **Dart**: Implement `GeminiService` to handle API calls.

### Phase 3: The Binding
1.  Setup `JavaScriptChannel` in Flutter.
2.  Wire up the flow: JS Scrape -> Dart API Call -> JS Click.

### Phase 4: Polish & Deploy
1.  Add native Settings UI for API Key.
2.  Add "Stealth Mode" logic.
3.  Build APK for Android.

# AcadHack Mobile (WIP) 🚧

**Work In Progress**: This project is currently in the initial planning and setup phase.

## 🎯 Aim
To bring the powerful automation of AcadHack to Android devices as a native application. Our goal is to create a seamless "browser-like" app that wraps the Acadally student portal and intelligently assists with quizzes.

## 📱 How It Will Work
Unlike the desktop version which uses Selenium, **AcadHack Mobile** will function as a specialized browser:
1.  **Native Shell**: Built with Flutter, providing a robust wrapper around the website.
2.  **JavaScript Injection**: The app will inject a lightweight JavaScript payload into the webview to detect questions and interact with the page elements.
3.  **Bridge to AI**: Question data will be passed securely from the Javascript layer to the native Dart code, which will communicate with the Google Gemini API to retrieve answers.
4.  **Automation**: The native code will send instructions back to the webview to automatically select the correct answer.

## 🛠️ Tech Stack
-   **Framework**: Flutter (Dart)
-   **Web Engine**: `webview_flutter`
-   **AI**: Google Gemini API via `google_generative_ai` SDK

---
*Stay tuned for updates as development kicks off!*

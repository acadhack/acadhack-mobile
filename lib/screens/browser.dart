import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../services/config_service.dart';
import '../services/gemini_service.dart';
import 'settings.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  late final WebViewController _controller;
  ConfigService? _config;
  GeminiService? _gemini;

  bool _isAutomationRunning = false;
  bool _isLoading = true;
  String _statusText = "Ready";

  // Login State
  bool _isLoggingIn = false;
  String? _tempUser;
  String? _tempPass;

  // Floating Pill Position
  Offset _pillPos = Offset.zero;
  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    // Defer argument reading to build/didChangeDependencies or read in initState via manual context check if needed,
    // but better to handle init logic in didChangeDependencies for route args.
    _initServices();
    _initWebView();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 1. Read Credentials (One-time use)
    if (_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args != null &&
          args['username'] != null &&
          args['username'].toString().isNotEmpty) {
        _tempUser = args['username'];
        _tempPass = args['password'];
        _isLoggingIn = true; // Start in Login Mode
        _statusText = "Auto-Login...";
      }

      // 2. Position Pill
      final size = MediaQuery.of(context).size;
      _pillPos = Offset((size.width - 280) / 2, size.height - 100);
      _isInit = false;
    }
  }

  Future<void> _initServices() async {
    _config = await ConfigService.init();
    if (_config!.apiKey != null && _config!.apiKey!.isNotEmpty) {
      _gemini = GeminiService(
        apiKey: _config!.apiKey!,
        modelName: _config!.modelName,
      );
    }
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF121212))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            setState(() => _isLoading = false);

            // Hide Login Overlay if we've left the login page
            if (_isLoggingIn && !url.contains('/login')) {
              setState(() {
                _isLoggingIn = false;
                _tempUser = null; // Clear credentials from memory
                _tempPass = null;
                _statusText = "Ready";
              });
            }

            await _injectScripts();

            // Execute One-Time Login
            if (_isLoggingIn && _tempUser != null) {
              // Give React a moment to hydrate
              await Future.delayed(const Duration(seconds: 1));
              print("Injecting Auto-Login for $_tempUser");
              final u = jsonEncode(_tempUser);
              final p = jsonEncode(_tempPass);
              await _controller.runJavaScript(
                "if(window.AcadHackAuth) window.AcadHackAuth.login($u, $p);",
              );
            }
          },
          onUrlChange: (change) {
            print("URL Changed: ${change.url}");
            if (change.url == null) return;

            // 1. Hide Overlay if we've left the login page
            if (_isLoggingIn && !change.url!.contains('/login')) {
              setState(() {
                _isLoggingIn = false;
                _tempUser = null;
                _tempPass = null;
                _statusText = "Ready";
              });
            }

            // 2. SPA/Redirect Fail-Safe: Re-inject login logic if on Login Page
            // This fixes the "Stuck" issue if onPageFinished doesn't fire.
            if (_isLoggingIn &&
                change.url!.contains('/login') &&
                _tempUser != null) {
              print("Detected Login Page via URL Change - Force Injecting...");
              Future.delayed(const Duration(seconds: 1), () async {
                await _injectScripts();
                final u = jsonEncode(_tempUser);
                final p = jsonEncode(_tempPass);
                await _controller.runJavaScript(
                  "if(window.AcadHackAuth) window.AcadHackAuth.login($u, $p);",
                );
              });
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        'AcadHackChannel',
        onMessageReceived: _handleJsMessage,
      );

    // Enable Remote Debugging (Moved after init)
    if (_controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller.loadRequest(
      Uri.parse('https://app.acadally.com/login/student'),
    );
  }

  Future<void> _injectScripts() async {
    if (_config?.isDarkMode ?? true) {
      final css = await rootBundle.loadString('assets/dark_mode.css');
      final jsCss =
          "if(!document.getElementById('ah-dark')){var s=document.createElement('style');s.id='ah-dark';s.innerHTML=`$css`;document.head.appendChild(s);}";
      await _controller.runJavaScript(jsCss);
    }

    // Core Logic
    final js = await rootBundle.loadString('assets/injector.js');
    await _controller.runJavaScript(js);

    // Auto Login Logic
    final loginJs = await rootBundle.loadString('assets/auto_login.js');
    await _controller.runJavaScript(loginJs);
  }

  void _handleJsMessage(JavaScriptMessage message) async {
    if (!_isAutomationRunning && !message.message.contains("HTML_DUMP")) return;

    try {
      final data = jsonDecode(message.message);

      if (data['type'] == 'LOG') {
        print("JS LOG: ${data['message']}");
        return;
      }

      if (data['type'] == 'HTML_DUMP') {
        print("--- HTML DUMP START ---");
        final String html = data['html'];
        // Split into 800-char chunks to avoid Android log truncation
        for (int i = 0; i < html.length; i += 800) {
          print(html.substring(i, min(i + 800, html.length)));
        }
        print("--- HTML DUMP END ---");
        setState(() => _statusText = "HTML Dumped (Chunked)");
        return;
      }

      if (!_isAutomationRunning) return;

      if (data['type'] == 'QUESTION_FOUND') {
        setState(() => _statusText = "Thinking...");

        final question = data['question'];
        final options = (data['options'] as List)
            .map((o) => o['text'].toString())
            .toList();

        // --- DELAYS ---
        double delay = _config?.rateLimit ?? 2.0;

        // Stealth Override
        if (_config?.isStealthMode ?? false) {
          final minD = _config?.minDelay ?? 3.0;
          final maxD = _config?.maxDelay ?? 10.0;
          delay = minD + Random().nextDouble() * (maxD - minD);
          setState(() => _statusText = "Stealth: ${delay.toStringAsFixed(1)}s");
        }

        // Booster Override
        if (_config?.isBoosterMode ?? false) {
          delay = 0.2;
        }

        await Future.delayed(Duration(milliseconds: (delay * 1000).toInt()));

        // --- SOLVING ---
        String? answerLetter = await _gemini?.solveQuestion(question, options);

        // Guess Fallback
        if (answerLetter == null && (_config?.isGuessMode ?? false)) {
          final opt = _config?.guessOption ?? 'RANDOM';
          setState(
            () => _statusText = "Guessing: ${opt == 'RANDOM' ? '?' : opt}",
          );
          if (opt == 'RANDOM') {
            answerLetter = ['A', 'B', 'C', 'D'][Random().nextInt(4)];
          } else {
            answerLetter = opt;
          }
        }

        if (answerLetter != null) {
          setState(() => _statusText = "Answer: $answerLetter");
          final index = "ABCD".indexOf(answerLetter);
          if (index != -1) {
            // Try to click option
            await _controller.runJavaScript(
              "window.AcadHack.clickOption($index);",
            );
          }
        } else {
          setState(() => _statusText = "Failed");
        }
      }
    } catch (e) {
      // print("Error: $e");
    }
  }

  void _toggleAutomation() {
    setState(() {
      _isAutomationRunning = !_isAutomationRunning;
      _statusText = _isAutomationRunning ? "Active" : "Paused";
    });
    if (!_isAutomationRunning) {
      _controller.runJavaScript(
        "if(window.AcadHack) window.AcadHack.resetProcessing();",
      );
    }
  }

  Future<void> _openSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
    if (result == true) {
      await _initServices();
      // Reload on config change to apply new scripts/settings
      if (mounted) _controller.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. The WebView (Underneath)
            WebViewWidget(controller: _controller),

            // 2. Loading / Verification Overlay
            if (_isLoggingIn)
              Container(
                color: const Color(0xFF121212),
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFFFF8A00)),
                    const SizedBox(height: 20),
                    Text(
                      "Logging you in...",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Please wait while we set things up.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

            // 3. Status Loader for normal browsing
            if (_isLoading && !_isLoggingIn)
              const Center(child: CircularProgressIndicator()),

            // 4. Floating Pill (Only show if NOT logging in)
            if (!_isLoggingIn)
              Positioned(
                left: _pillPos.dx,
                top: _pillPos.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      final size = MediaQuery.of(context).size;
                      double newX = _pillPos.dx + details.delta.dx;
                      double newY = _pillPos.dy + details.delta.dy;
                      newX = newX.clamp(0.0, size.width - 280);
                      newY = newY.clamp(0.0, size.height - 60);
                      _pillPos = Offset(newX, newY);
                    });
                  },
                  child: _buildPill(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 280,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF333333)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.drag_indicator, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
              ),
            ),
            IconButton(
              icon: Icon(
                _isAutomationRunning ? Icons.stop_circle : Icons.play_circle,
                color: _isAutomationRunning ? Colors.red : Colors.green,
              ),
              onPressed: _toggleAutomation,
            ),
            // DEBUG BUTTON
            IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.orange),
              onPressed: () {
                _controller.runJavaScript(
                  "window.AcadHackChannel.postMessage(JSON.stringify({type: 'HTML_DUMP', html: document.documentElement.outerHTML}));",
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.grey),
              onPressed: _openSettings,
            ),
          ],
        ),
      ),
    );
  }
}

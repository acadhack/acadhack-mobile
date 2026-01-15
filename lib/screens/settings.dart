import 'package:flutter/material.dart';
import '../services/config_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiKeyController;
  late TextEditingController _modelController;
  late TextEditingController _rateLimitController;
  late TextEditingController _minDelayController;
  late TextEditingController _maxDelayController;

  bool _stealthMode = false;
  bool _darkMode = true;
  bool _boosterMode = false;
  bool _guessMode = false;
  String _guessOption = 'A';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await ConfigService.init();
    setState(() {
      _apiKeyController = TextEditingController(text: config.apiKey ?? '');
      _modelController = TextEditingController(text: config.modelName);
      _rateLimitController = TextEditingController(
        text: config.rateLimit.toString(),
      );
      _minDelayController = TextEditingController(
        text: config.minDelay.toString(),
      );
      _maxDelayController = TextEditingController(
        text: config.maxDelay.toString(),
      );

      _stealthMode = config.isStealthMode;
      _darkMode = config.isDarkMode;
      _boosterMode = config.isBoosterMode;
      _guessMode = config.isGuessMode;
      _guessOption = config.guessOption;

      _isLoading = false;
    });
  }

  Future<void> _saveConfig() async {
    final config = await ConfigService.init();
    await config.setApiKey(_apiKeyController.text);
    await config.setModelName(_modelController.text);

    // Parse doubles safely
    await config.setRateLimit(
      double.tryParse(_rateLimitController.text) ?? 2.0,
    );
    await config.setMinDelay(double.tryParse(_minDelayController.text) ?? 3.0);
    await config.setMaxDelay(double.tryParse(_maxDelayController.text) ?? 10.0);

    // Credentials Logic Removed (Security)

    await config.setStealthMode(_stealthMode);
    await config.setDarkMode(_darkMode);
    await config.setBoosterMode(_boosterMode);
    await config.setGuessMode(_guessMode);
    await config.setGuessOption(_guessOption);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings Saved')));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('AI Configuration'),
          TextField(
            controller: _apiKeyController,
            decoration: const InputDecoration(
              labelText: 'Gemini API Key',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _modelController,
                  decoration: const InputDecoration(
                    labelText: 'Model Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _rateLimitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Rate Limit (RPM sec)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),

          _buildSectionHeader('Automation Modes'),
          SwitchListTile(
            title: const Text('Stealth Mode'),
            subtitle: const Text('Random delays to mimic human behavior'),
            value: _stealthMode,
            onChanged: (val) => setState(() => _stealthMode = val),
          ),
          if (_stealthMode) _buildDelayInputs(),

          SwitchListTile(
            title: const Text('Quiz Booster'),
            subtitle: const Text('High-speed solving (Caution)'),
            value: _boosterMode,
            onChanged: (val) => setState(() => _boosterMode = val),
          ),

          SwitchListTile(
            title: const Text('Guess Mode'),
            subtitle: const Text('Randomly select options if AI fails'),
            value: _guessMode,
            onChanged: (val) => setState(() => _guessMode = val),
          ),
          if (_guessMode) _buildGuessDropdown(),

          _buildSectionHeader('App Settings'),
          SwitchListTile(
            title: const Text('Dark Mode (Web)'),
            value: _darkMode,
            onChanged: (val) => setState(() => _darkMode = val),
          ),

          const SizedBox(height: 30),
          FilledButton.icon(
            onPressed: _saveConfig,
            icon: const Icon(Icons.save),
            label: const Text('Save Settings'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFBB86FC),
        ),
      ),
    );
  }

  Widget _buildDelayInputs() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minDelayController,
                decoration: const InputDecoration(labelText: 'Min Delay (s)'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _maxDelayController,
                decoration: const InputDecoration(labelText: 'Max Delay (s)'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuessDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<String>(
        value: _guessOption,
        items: ['A', 'B', 'C', 'D', 'RANDOM']
            .map(
              (e) =>
                  DropdownMenuItem(value: e, child: Text("Force Option: $e")),
            )
            .toList(),
        onChanged: (val) => setState(() => _guessOption = val!),
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
    );
  }
}

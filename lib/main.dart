

import 'package:flutter/material.dart';
import 'core/persistence.dart';
import 'ui/game_screen.dart';
import 'package:google_fonts/google_fonts.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tic Tac Toe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF7C66FF),
      ),
      home: const HomePage(),
    );
  }
}

enum AIDifficulty { easy, medium, hard }

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final store = StatsStore();
  Stats stats = const Stats();
  AIDifficulty difficulty = AIDifficulty.easy;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final s = await store.load();
    if (!mounted) return;
    setState(() => stats = s);
  }

  Future<void> _resetStats() async {
    await store.reset();
    await _loadStats();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Stats reset')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Tic Tac Toe',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // --- XO LOGO ---------------------------------------------------
              const SizedBox(height: 16),
              const _XOLogo(),
              const SizedBox(height: 24),

              const Text(
                'You play as X, AI plays as O',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 20),

              // --- Stats Cards -----------------------------------------------
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 360,
                  child: Row(
                    children: [
                      _statCard('Wins', stats.wins, const Color(0xFF1B5E20)),
                      _statCard('Losses', stats.losses, const Color(0xFF7F1D1D)),
                      _statCard('Draws', stats.draws, Colors.grey.shade700),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 36),
              const Text(
                'Difficulty',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              SegmentedButton<AIDifficulty>(
                segments: const [
                  ButtonSegment(value: AIDifficulty.easy, label: Text('Easy')),
                  ButtonSegment(value: AIDifficulty.medium, label: Text('Medium')),
                  ButtonSegment(value: AIDifficulty.hard, label: Text('Hard')),
                ],
                selected: {difficulty},
                onSelectionChanged: (s) => setState(() => difficulty = s.first),
              ),

              // --- Buttons Section -------------------------------------------
              const SizedBox(height: 64), // lowered buttons more
              SizedBox(
                width: 360,
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Play'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GameScreen(
                          difficulty: difficulty,
                          store: store,
                        ),
                      ),
                    );
                    _loadStats();
                  },
                ),
              ),

              const SizedBox(height: 20), 
              SizedBox(
                  width: 360,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Stats'),
                    onPressed: _resetStats,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                  ),
                ),
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String title, int value, Color color) {
    return Expanded(
      child: Card(
        color: color.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                '$value',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- SECTION: XO Logo Widget -----------------------------------------------
class _XOLogo extends StatelessWidget {
  const _XOLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'X',
          style: GoogleFonts.permanentMarker(
            fontSize: 96,
            fontWeight: FontWeight.w900,
            color: Colors.redAccent,
          ),
        ),
        Text(
          'O',
          style: GoogleFonts.permanentMarker(
            fontSize: 96,
            fontWeight: FontWeight.w900,
            color: Colors.lightBlueAccent,
          ),
        ),
      ],
    );
  }
}

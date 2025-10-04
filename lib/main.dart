import 'package:flutter/material.dart';
import 'core/persistence.dart';
import 'ui/game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Dark, modern palette for the whole site
    return MaterialApp(
      title: 'Tic-Tac-Toe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        // soft violet seed, subtle and consistent
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Tic-Tac-Toe')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('You are X · AI is O',
                  style: TextStyle(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 18),

              // Centered stat cards (dark borders)
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 360,
                  child: Row(
                    children: [
                      _statCard('Wins',   stats.wins,   const Color(0xFF1B5E20)), // dark green
                      _statCard('Losses', stats.losses, const Color(0xFF7F1D1D)), // dark red
                      _statCard('Draws',  stats.draws,  Colors.grey.shade700),    // dark grey
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text('Difficulty',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),

              SegmentedButton<AIDifficulty>(
                segments: const [
                  ButtonSegment(value: AIDifficulty.easy,   label: Text('Easy')),
                  ButtonSegment(value: AIDifficulty.medium, label: Text('Medium')),
                  ButtonSegment(value: AIDifficulty.hard,   label: Text('Hard')),
                ],
                selected: {difficulty},
                onSelectionChanged: (s) => setState(() => difficulty = s.first),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: 360,
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Play'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
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
                    await _loadStats(); // refresh on return
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 360,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset Stats'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: _resetStats,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, int value, Color color) {
    return Expanded(
      child: Container(
        height: 88,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color, width: 1.8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$value',
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

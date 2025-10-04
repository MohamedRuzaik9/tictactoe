import 'package:shared_preferences/shared_preferences.dart';

class Stats {
  final int wins;
  final int losses;
  final int draws;
  const Stats({this.wins = 0, this.losses = 0, this.draws = 0});

  Stats copyWith({int? wins, int? losses, int? draws}) => Stats(
        wins: wins ?? this.wins,
        losses: losses ?? this.losses,
        draws: draws ?? this.draws,
      );
}

class StatsStore {
  static const _kWins = 'wins';
  static const _kLosses = 'losses';
  static const _kDraws = 'draws';

  Future<Stats> load() async {
    final sp = await SharedPreferences.getInstance();
    return Stats(
      wins: sp.getInt(_kWins) ?? 0,
      losses: sp.getInt(_kLosses) ?? 0,
      draws: sp.getInt(_kDraws) ?? 0,
    );
  }

  Future<void> save(Stats s) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kWins, s.wins);
    await sp.setInt(_kLosses, s.losses);
    await sp.setInt(_kDraws, s.draws);
  }

  Future<void> reset() async => save(const Stats());
}

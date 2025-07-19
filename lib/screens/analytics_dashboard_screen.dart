import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/analytics_service.dart';
import '../models/journal_entry.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AnalyticsDashboardScreen extends StatelessWidget {
  const AnalyticsDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<AuthProvider>(context).currentUser?.uid;
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view analytics')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Insights & Analytics')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Your Music Journal Insights',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Mood Pie Chart
              _MoodPieChart(userId: userId),

              const SizedBox(height: 24),
              // Favorite Artists
              _FavoriteArtistsBar(userId: userId),

              const SizedBox(height: 24),
              // Entries per Month
              _EntriesPerMonthBar(userId: userId),

              const SizedBox(height: 24),
              // Average Rating
              _AverageRatingLine(userId: userId),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Mood Pie Chart ---
class _MoodPieChart extends StatelessWidget {
  final String userId;
  const _MoodPieChart({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<Mood, int>>(
      future: AnalyticsService.getMoodCounts(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        final data = snapshot.data!;
        if (data.isEmpty) {
          return const Text('No mood data yet.');
        }
        final total = data.values.fold(0, (a, b) => a + b);
        final sections =
            data.entries.map((e) {
              final percentage = (e.value / total) * 100;
              return PieChartSectionData(
                color:
                    Colors.primaries[Mood.values.indexOf(e.key) %
                        Colors.primaries.length],
                value: e.value.toDouble(),
                title: '${e.key.emoji}\n${percentage.toStringAsFixed(1)}%',
                radius: 50,
                titleStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              );
            }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mood Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 180,
              child: PieChart(PieChartData(sections: sections)),
            ),
          ],
        );
      },
    );
  }
}

// --- Favorite Artists Bar Chart ---
class _FavoriteArtistsBar extends StatelessWidget {
  final String userId;
  const _FavoriteArtistsBar({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: AnalyticsService.getFavoriteArtists(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        final data = snapshot.data!;
        if (data.isEmpty) {
          return const Text('No artist data yet.');
        }
        final topArtists =
            data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        final showArtists = topArtists.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Artists',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: [
                    for (int i = 0; i < showArtists.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: showArtists[i].value.toDouble(),
                            color: Colors.blueAccent,
                          ),
                        ],
                      ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final idx = value.toInt();
                          return Text(
                            showArtists[idx].key,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// --- Entries Per Month Bar Chart ---
class _EntriesPerMonthBar extends StatelessWidget {
  final String userId;
  const _EntriesPerMonthBar({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: AnalyticsService.getEntriesPerMonth(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        final data = snapshot.data!;
        if (data.isEmpty) {
          return const Text('No entry frequency data yet.');
        }
        final months = data.keys.toList()..sort();
        final values = months.map((m) => data[m]!).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entries Per Month',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: [
                    for (int i = 0; i < months.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: values[i].toDouble(),
                            color: Colors.green,
                          ),
                        ],
                      ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final idx = value.toInt();
                          return Text(
                            months[idx],
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// --- Average Rating Line Chart ---
class _AverageRatingLine extends StatelessWidget {
  final String userId;
  const _AverageRatingLine({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AnalyticsService.getAverageRatingPerMonth(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        final data = snapshot.data!;
        if (data.isEmpty) {
          return const Text('No rating data yet.');
        }
        final months = data.map((d) => d['month'] as String).toList();
        final ratings = data.map((d) => d['avgRating'] as double).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Average Rating Per Month',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (int i = 0; i < ratings.length; i++)
                          FlSpot(i.toDouble(), ratings[i]),
                      ],
                      isCurved: true,
                      color: Colors.redAccent,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final idx = value.toInt();
                          return Text(
                            months[idx],
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                  minY: 0,
                  maxY: 5,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

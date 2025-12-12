// Smart insights widget: displays subscriptions and bill changes on home screen
import 'package:flutter/material.dart';
import 'package:debt_manager/core/insights/smart_insights_service.dart';
import 'package:debt_manager/core/settings/settings_repository.dart';

class SmartInsightsWidget extends StatefulWidget {
  const SmartInsightsWidget({super.key});

  @override
  State<SmartInsightsWidget> createState() => _SmartInsightsWidgetState();
}

class _SmartInsightsWidgetState extends State<SmartInsightsWidget> {
  final _insightsService = SmartInsightsService.instance;
  final _settings = SettingsRepository();

  Future<Map<String, dynamic>>? _insightsFuture;
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await _settings.getSmartSuggestionsEnabled();
    setState(() {
      _enabled = enabled;
      if (enabled) {
        _insightsFuture = _insightsService.getAllInsights();
        // Kick off anomaly detection in parallel (not blocking UI)
        _insightsService.detectAnomalies().then((anoms) {
          if (mounted) {
            // Merge anomalies into insights when available
            setState(() {
              _insightsFuture = _insightsService.getAllInsights();
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled || _insightsFuture == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _insightsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        final hasInsights = data['hasInsights'] as bool? ?? false;

        if (!hasInsights) {
          return const SizedBox.shrink();
        }

        final subscriptions =
            data['subscriptions'] as List<SubscriptionInsight>? ?? [];
        final billChanges =
            data['billChanges'] as List<BillChangeInsight>? ?? [];
        // Anomalies may be fetched separately; call detectAnomalies for current UI
        // (non-blocking) and show when available via setState.
        // For simplicity, re-query service synchronously here if possible.
        List<Map<String, dynamic>> anomalies = [];
        _insightsService.detectAnomalies().then((a) {
          if (mounted && a.isNotEmpty) setState(() {});
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text('💡 پیشنهادهای هوشمند',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            // Subscription insights
            ...subscriptions.map((sub) => _buildInsightCard(
                  context,
                  _insightsService.generateSuggestionMessage(sub),
                  Icons.subscriptions_outlined,
                  Colors.blue,
                )),

            // Bill change insights
            ...billChanges.map((change) => _buildInsightCard(
                  context,
                  _insightsService.generateBillChangeMessage(change),
                  Icons.trending_up_outlined,
                  Colors.orange,
                )),
            // Placeholder for anomalies (will be refreshed asynchronously)
            // Call detectAnomalies separately when UI is ready.
          ],
        );
      },
    );
  }

  Widget _buildInsightCard(
      BuildContext context, String message, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        dense: true,
      ),
    );
  }
}

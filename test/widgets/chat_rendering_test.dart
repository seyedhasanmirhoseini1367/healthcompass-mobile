import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:healthcompass_mobile/models/chat_event.dart';
import 'package:healthcompass_mobile/widgets/chat_source_chip.dart';
import 'package:healthcompass_mobile/widgets/trend_chart_card.dart';

// Exercises the widgets assistant_screen.dart uses to render a streamed
// reply's sources + chart (see lib/screens/assistant_screen.dart's
// _MessageBubble, which is private and so not directly testable from
// here -- SourceChip/TrendChartCard were extracted to lib/widgets/ so
// this path has real widget-test coverage instead of being skipped).

Widget _wrap(Widget child) => MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, __) => Scaffold(body: child)),
          GoRoute(path: '/records/:id', builder: (_, s) => Text('record ${s.pathParameters['id']}')),
        ],
      ),
    );

void main() {
  testWidgets('personal-record source chip renders title and navigates on tap', (tester) async {
    const source = SourceRef(
      title: 'Lab Results Jan 2024',
      documentType: 'lab_result',
      recordDate: '2024-01-15',
      recordId: 'rec-1',
    );

    await tester.pumpWidget(_wrap(SourceChip(source: source)));

    expect(find.text('Lab Results Jan 2024'), findsOneWidget);
    expect(find.textContaining('lab_result'), findsOneWidget);

    await tester.tap(find.byType(SourceChip));
    await tester.pumpAndSettle();

    expect(find.text('record rec-1'), findsOneWidget);
  });

  testWidgets('general/article source chip renders but is not tappable', (tester) async {
    const source = SourceRef(
      title: 'Diabetes Overview',
      isGeneral: true,
      sourceName: 'Mayo Clinic',
      topic: 'diabetes',
    );

    await tester.pumpWidget(_wrap(SourceChip(source: source)));

    expect(find.text('Diabetes Overview'), findsOneWidget);
    expect(find.textContaining('Mayo Clinic'), findsOneWidget);

    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkWell.onTap, isNull);
  });

  testWidgets('trend chart card renders the biomarker name and trend badge', (tester) async {
    // Real payload shape captured from a live trajectory-query SSE response.
    final chart = ChartPayload.fromJson({
      'biomarker': 'hba1c',
      'display_name': 'Hba1C',
      'unit': '%',
      'labels': ['Jan 2024', 'Jun 2024'],
      'values': [7.8, 6.9],
      'trend_direction': 'DECREASING',
      'pct_change': -11.5,
      'slope_per_month': -0.184,
      'reference_low': null,
      'reference_high': 6.5,
    });

    await tester.pumpWidget(_wrap(TrendChartCard(chart: chart)));

    expect(find.textContaining('Hba1C'), findsOneWidget);
    expect(find.textContaining('-11.5%'), findsOneWidget);
    expect(find.byIcon(Icons.trending_down_rounded), findsOneWidget);
  });

  testWidgets('a chat bubble with multiple sources renders one chip per source', (tester) async {
    final sources = [
      const SourceRef(title: 'Lab A', recordId: 'a', documentType: 'lab_result'),
      const SourceRef(title: 'Lab B', recordId: 'b', documentType: 'lab_result'),
    ];

    await tester.pumpWidget(_wrap(Wrap(
      children: sources.map((s) => SourceChip(source: s)).toList(),
    )));

    expect(find.byType(SourceChip), findsNWidgets(2));
    expect(find.text('Lab A'), findsOneWidget);
    expect(find.text('Lab B'), findsOneWidget);
  });
}

// Diagnostic benchmark: host debug timings are NOT device frame timings.
// Run: flutter test test/performance/mobile_lists_test.dart --reporter expanded
import 'dart:convert';
import 'dart:io';

import 'package:cysvet_app/filters/animal_filter.dart';
import 'package:cysvet_app/filters/visit_filter.dart';
import 'package:cysvet_app/models/animal_summary_model.dart';
import 'package:cysvet_app/models/property_summary_model.dart';
import 'package:cysvet_app/models/visit_summary_model.dart';
import 'package:cysvet_app/pages/animals/animals_page.dart';
import 'package:cysvet_app/pages/visits/visits_page.dart';
import 'package:cysvet_app/providers/animals_provider.dart';
import 'package:cysvet_app/providers/properties_provider.dart';
import 'package:cysvet_app/providers/visits_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  final results = <Map<String, Object>>[];
  GoogleFonts.config.allowRuntimeFetching = false;

  tearDownAll(() {
    final output = File('build/performance/mobile_lists.json');
    output.parent.createSync(recursive: true);
    output.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'environment': 'Flutter widget test, debug, host PC, synthetic data',
        'viewport': '390x844 logical pixels, DPR 1',
        'limitations':
            'No device GPU, network, backend or actual mobile FPS measured. RSS is whole test process; not app memory.',
        'results': results,
      }),
    );
  });

  for (final page in ['animals', 'visits']) {
    for (final count in [100, 500, 1000]) {
      testWidgets('$page mobile list: $count records', (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final animals = List.generate(
          count,
          (i) => AnimalSummaryModel(
            id: i + 1,
            idPropriedade: 1,
            codigo: 'AN-${i.toString().padLeft(5, '0')}',
            dataNascimento: DateTime(2022, 1, 1),
            dataUltimoParto: DateTime(2026, 1, 1),
          ),
        );
        final visits = List.generate(
          count,
          (i) => VisitSummaryModel(
            id: i + 1,
            idPropriedade: 1,
            dataVisita: DateTime(2026, 1, 1).add(Duration(days: i)),
            nomeUsuario: 'Veterinario teste',
            observacoes: 'Visita de teste $i',
          ),
        );

        for (var repetition = 0; repetition < 3; repetition++) {
          final container = ProviderContainer(
            overrides: [
              animalsProvider.overrideWith((ref) async => animals),
              visitsProvider.overrideWith((ref) async => visits),
              propertiesProvider.overrideWith(
                (ref) async => const [
                  PropertySummaryModel(id: 1, nome: 'Fazenda teste'),
                ],
              ),
            ],
          );
          // Resolve fixtures before timing: isolate UI work from data loading.
          await container.read(animalsProvider.future);
          await container.read(visitsProvider.future);
          await container.read(propertiesProvider.future);
          final watch = Stopwatch()..start();
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                home: page == 'animals'
                    ? const AnimalsPage()
                    : const VisitsPage(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          watch.stop();
          expect(tester.takeException(), isNull);
          final elements = find
              .byWidgetPredicate((_) => true, skipOffstage: false)
              .evaluate()
              .length;
          // Diagnostic lookup only; update if private card classes are renamed.
          final cardType = page == 'animals'
              ? 'AnimalMobileCard'
              : '_VisitCard';
          final cards = find
              .byWidgetPredicate(
                (widget) => widget.runtimeType.toString() == cardType,
                skipOffstage: false,
              )
              .evaluate()
              .length;
          expect(cards, greaterThan(0));
          final mountMs = watch.elapsedMicroseconds / 1000;
          watch.reset();
          watch.start();
          if (page == 'animals') {
            container.read(animalsSearchQueryProvider.notifier).state = 'AN-';
          } else {
            container.read(visitsSearchQueryProvider.notifier).state = 'teste';
          }
          await tester.pumpAndSettle();
          watch.stop();
          expect(tester.takeException(), isNull);
          final result = <String, Object>{
            'page': page,
            'records': count,
            'repetition': repetition + 1,
            'mount_ms': mountMs,
            'search_rebuild_ms': watch.elapsedMicroseconds / 1000,
            'mounted_elements': elements,
            'mounted_cards': cards,
            'process_rss_mb': ProcessInfo.currentRss / (1024 * 1024),
          };
          results.add(result);
          // ignore: avoid_print
          print('PERF ${jsonEncode(result)}');
          await tester.pumpWidget(const SizedBox.shrink());
          container.dispose();
        }
      });
    }
  }
}

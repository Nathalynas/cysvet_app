import 'package:cysvet_app/core/constants/app_constants.dart';
import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/core/widgets/app_button.dart';
import 'package:cysvet_app/core/widgets/app_card.dart';
import 'package:cysvet_app/core/widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/utils/formatters.dart';
import '../../../visits/application/visits_provider.dart';
import '../../../visits/data/visits_repository.dart';
import '../../../visits/domain/visit_summary_model.dart';
import '../../data/animals_repository.dart';
import '../../domain/animal_history_event_model.dart';
import '../../domain/animal_summary_model.dart';

String _animalCodeLabel(String code) {
  if (code.trim().isEmpty) return '--';
  if (code.trim().startsWith('#')) return code.trim();
  return '#${code.trim()}';
}

AnimalReproductiveStatus reproductiveStatusFor(AnimalSummaryModel animal) {
  final savedStatus = animal.statusReprodutivo;
  if (savedStatus != null) {
    return savedStatus;
  }

  if (animal.dataInseminacao != null) {
    return AnimalReproductiveStatus.inseminated;
  }

  final history = (animal.historicoReprodutivo ?? '').normalize();

  if (history.contains('pren') || history.contains('confirm')) {
    return AnimalReproductiveStatus.pregnant;
  }

  if (history.contains('insemin')) {
    return AnimalReproductiveStatus.inseminated;
  }

  if (history.contains('seca') || history.contains('dry')) {
    return AnimalReproductiveStatus.dry;
  }

  if (history.contains('vazia') ||
      history.contains('empty') ||
      history.contains('negativ') ||
      history.contains('toque')) {
    return AnimalReproductiveStatus.empty;
  }

  return AnimalReproductiveStatus.pending;
}

final _animalHistoryProvider = FutureProvider.autoDispose
    .family<_AnimalHistoryData, AnimalSummaryModel>((ref, animal) async {
      // TODO(api): substituir esta composicao front-end por um endpoint
      // consolidado, por exemplo GET /api/animals/{id}/history, retornando
      // historico produtivo, eventos, visitas, movimentacoes e alteracoes.
      // Temporario: eventos vêm de /api/events?idAnimal; visitas vêm de
      // /api/visits?idPropriedade e sao filtradas no front. Movimentacoes e
      // alteracoes ainda usam somente o estado atual de AnimalSummaryModel.
      final eventsFuture = animal.id > 0
          ? ref
                .watch(animalsRepositoryProvider)
                .listHistoryEvents(animalId: animal.id)
          : Future.value(const <AnimalHistoryEventModel>[]);
      final remoteVisitsFuture = ref
          .watch(visitsRepositoryProvider)
          .list(
            propertyId: animal.idPropriedade > 0 ? animal.idPropriedade : null,
          );
      final localVisits = ref.watch(localVisitsProvider).values;

      final results = await Future.wait<Object>([
        eventsFuture,
        remoteVisitsFuture,
      ]);
      final events = [...(results[0] as List<AnimalHistoryEventModel>)]
        ..sort(_compareHistoryEventsDesc);
      final remoteVisits = results[1] as List<VisitSummaryModel>;
      final visitsById = {
        for (final visit in remoteVisits) visit.id: visit,
        for (final visit in localVisits)
          if (_visitBelongsToAnimalProperty(visit, animal)) visit.id: visit,
      };
      final visitRecords =
          visitsById.values
              .expand((visit) => _visitRecordsForAnimal(visit, animal))
              .toList()
            ..sort(_compareVisitRecordsDesc);

      return _AnimalHistoryData(
        animal: animal,
        events: events,
        visits: visitRecords,
      );
    });

class AnimalHistoryDialog {
  const AnimalHistoryDialog._();

  static Future<void> show({
    required BuildContext context,
    required AnimalSummaryModel animal,
    required String propertyName,
  }) {
    return AppDialog.show<void>(
      context: context,
      title: 'Histórico do animal',
      subtitle: _animalCodeLabel(animal.codigo),
      width: 900,
      fullscreenOnMobile: true,
      useInternalScroll: true,
      content: _AnimalHistoryDialogContent(
        animal: animal,
        propertyName: propertyName,
      ),
    );
  }
}

class _AnimalHistoryDialogContent extends ConsumerWidget {
  const _AnimalHistoryDialogContent({
    required this.animal,
    required this.propertyName,
  });

  final AnimalSummaryModel animal;
  final String propertyName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyProvider = _animalHistoryProvider(animal);
    final history = ref.watch(historyProvider);

    return history.when(
      data: (data) =>
          _AnimalHistoryBody(data: data, propertyName: propertyName),
      loading: () => const _AnimalHistoryLoading(),
      error: (error, stackTrace) {
        return _AnimalHistoryLoadError(
          onRetry: () => ref.invalidate(historyProvider),
        );
      },
    );
  }
}

class _AnimalHistoryBody extends StatelessWidget {
  const _AnimalHistoryBody({required this.data, required this.propertyName});

  final _AnimalHistoryData data;
  final String propertyName;

  @override
  Widget build(BuildContext context) {
    final animal = data.animal;
    final iaHistory = _IaHistorySummary.fromHistoryData(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _AnimalHistoryHeader(animal: animal, propertyName: propertyName),
        const SizedBox(height: 12),
        _AnimalHistoryMetricGrid(animal: animal),
        const SizedBox(height: 18),
        _AnimalHistorySection(
          icon: Icons.calculate_outlined,
          title: 'Resultados calculados',
          child: _CalculatedResultsPanel(
            animal: animal,
            latestEntry: data.latestVisitEntry,
            iaHistory: iaHistory,
          ),
        ),
        const SizedBox(height: 18),
        _AnimalHistorySection(
          icon: Icons.insights_outlined,
          title: 'Histórico produtivo',
          child: _ProductiveHistoryPanel(animal: animal),
        ),
        const SizedBox(height: 18),
        _AnimalHistorySection(
          icon: Icons.event_available_outlined,
          title: 'Eventos registrados',
          count: data.events.length,
          child: _AnimalEventHistoryList(events: data.events),
        ),
        const SizedBox(height: 18),
        _AnimalHistorySection(
          icon: Icons.science_outlined,
          title: 'Histórico de IAs',
          count: iaHistory.totalIas,
          child: _AnimalIaHistoryPanel(history: iaHistory),
        ),
        const SizedBox(height: 18),
        _AnimalHistorySection(
          icon: Icons.assignment_outlined,
          title: 'Visitas',
          count: data.visits.length,
          child: _AnimalVisitHistoryList(records: data.visits),
        ),
        const SizedBox(height: 18),
        _AnimalHistorySection(
          icon: Icons.sync_alt_outlined,
          title: 'Alterações e movimentações',
          child: _AnimalMovementHistoryPanel(
            animal: animal,
            propertyName: propertyName,
          ),
        ),
      ],
    );
  }
}

class _AnimalHistoryHeader extends StatelessWidget {
  const _AnimalHistoryHeader({
    required this.animal,
    required this.propertyName,
  });

  final AnimalSummaryModel animal;
  final String propertyName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      shadow: false,
      backgroundColor: colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.42,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(MdiIcons.cow, color: colorScheme.primary, size: 50),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _animalCodeLabel(animal.codigo),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  propertyName.trim().isEmpty
                      ? 'Propriedade não informada'
                      : propertyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _ReproductiveStatusPill(status: reproductiveStatusFor(animal)),
        ],
      ),
    );
  }
}

class _AnimalHistoryMetricGrid extends StatelessWidget {
  const _AnimalHistoryMetricGrid({required this.animal});

  final AnimalSummaryModel animal;

  @override
  Widget build(BuildContext context) {
    final items = [
      _HistoryInfoItem(
        label: 'Categoria',
        value: _valueOrDash(animal.categoria),
      ),
      _HistoryInfoItem(
        label: 'Lactações',
        value: formatInteger(animal.numeroLactacao),
      ),
      _HistoryInfoItem(
        label: 'Último parto',
        value: formatDate(animal.dataUltimoParto),
      ),
      _HistoryInfoItem(
        label: 'Última IA',
        value: formatDate(animal.dataInseminacao),
      ),
      _HistoryInfoItem(
        label: 'DEL',
        value: animal.diasEmLactacao == null
            ? '--'
            : '${formatInteger(animal.diasEmLactacao!)} dias',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 620 ? 2 : 4;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _HistoryInfoTile(item: item),
              ),
          ],
        );
      },
    );
  }
}


class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HistoryInfoTile extends StatelessWidget {
  const _HistoryInfoTile({required this.item});

  final _HistoryInfoItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimalHistorySection extends StatelessWidget {
  const _AnimalHistorySection({
    required this.icon,
    required this.title,
    required this.child,
    this.count,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (count != null) _MiniBadge(label: formatInteger(count!)),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}


class _CalculatedResultsPanel extends StatelessWidget {
  const _CalculatedResultsPanel({
    required this.animal,
    required this.latestEntry,
    required this.iaHistory,
  });

  final AnimalSummaryModel animal;
  final VisitAnimalEntryModel? latestEntry;
  final _IaHistorySummary iaHistory;

  @override
  Widget build(BuildContext context) {
    final items = _calculatedResultItems(
      animal: animal,
      latestEntry: latestEntry,
      iaHistory: iaHistory,
    );

    return _HistoryPanel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 560
              ? 1
              : constraints.maxWidth < 820
                  ? 2
                  : 3;
          const spacing = 8.0;
          final width =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final item in items)
                SizedBox(
                  width: width,
                  child: _CalculatedResultTile(item: item),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CalculatedResultTile extends StatelessWidget {
  const _CalculatedResultTile({required this.item});

  final _HistoryDetail item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            item.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

List<_HistoryDetail> _calculatedResultItems({
  required AnimalSummaryModel animal,
  required VisitAnimalEntryModel? latestEntry,
  required _IaHistorySummary iaHistory,
}) {
  final lastBirth = _dateFromEntry(latestEntry, 'dataUltimoParto') ??
      animal.dataUltimoParto;
  final inseminationDate = _dateFromEntry(latestEntry, 'dataUltimaIa') ??
      _dateFromEntry(latestEntry, 'dataInseminacao') ??
      animal.dataInseminacao;
  final dryOffForecast = _dateFromEntry(latestEntry, 'previsaoSecagem');
  final calvingForecast = _dateFromEntry(latestEntry, 'previsaoParto') ??
      _dateFromEntry(latestEntry, 'dataPrevistaParto');
  final prePartumDate = _dateFromEntry(latestEntry, 'dataPreParto') ??
      _dateFromEntry(latestEntry, 'entradaPreParto');

  final intervals = _iaIntervalsFromEntry(latestEntry);
  final resolvedIntervals = intervals.isNotEmpty ? intervals : iaHistory.intervals;

  return [
    _HistoryDetail(
      label: 'DEL',
      value: _formatIntDays(
        _intFromEntry(latestEntry, 'del') ?? animal.diasEmLactacao,
      ),
    ),
    _HistoryDetail(
      label: 'Idade',
      value: _formatAgeFromBirthDate(
        _dateFromEntry(latestEntry, 'dataNascimento') ?? animal.dataNascimento,
      ),
    ),
    _HistoryDetail(
      label: 'Idade no primeiro parto',
      value: _formatDoubleMonths(
        _doubleFromEntry(latestEntry, 'idadePrimeiroPartoMeses') ??
            _doubleFromEntry(latestEntry, 'idadePrimeiroParto'),
      ),
    ),
    _HistoryDetail(
      label: 'Idade na primeira IA',
      value: _formatDoubleMonths(_doubleFromEntry(latestEntry, 'idadePrimeiraIa')),
    ),
    _HistoryDetail(
      label: 'Mês do parto',
      value: _valueOrDash(
        _stringFromEntry(latestEntry, 'mesParto') ?? _monthLabel(lastBirth),
      ),
    ),
    _HistoryDetail(
      label: 'Ano do último parto',
      value: _formatIntegerOrDash(
        _intFromEntry(latestEntry, 'anoUltimoParto') ?? lastBirth?.year,
      ),
    ),
    _HistoryDetail(
      label: 'IEP atual',
      value: _formatDoubleMonths(_doubleFromEntry(latestEntry, 'iepAtual')),
    ),
    _HistoryDetail(
      label: 'Primípara/multípara',
      value: _valueOrDash(_stringFromEntry(latestEntry, 'classificacaoPartos')),
    ),
    _HistoryDetail(
      label: 'Vaca apta',
      value: _formatBool(_boolFromEntry(latestEntry, 'vacaApta')),
    ),
    _HistoryDetail(
      label: 'Intervalos entre IAs',
      value: resolvedIntervals.isEmpty
          ? '--'
          : resolvedIntervals.map((days) => '${formatInteger(days)} dias').join(' | '),
    ),
    _HistoryDetail(
      label: 'Média intervalo IA',
      value: _formatDoubleDays(
        _doubleFromEntry(latestEntry, 'mediaIntervaloIa') ?? iaHistory.averageInterval,
      ),
    ),
    _HistoryDetail(
      label: 'Previsão retorno cio',
      value: formatDate(_dateFromEntry(latestEntry, 'previsaoRetornoCio')),
    ),
    _HistoryDetail(
      label: 'Dias de prenhez',
      value: _formatIntDays(_intFromEntry(latestEntry, 'diasPrenhez')),
    ),
    _HistoryDetail(
      label: 'DEL primeira IA',
      value: _formatIntDays(_intFromEntry(latestEntry, 'delPrimeiraIa')),
    ),
    _HistoryDetail(
      label: 'Período de serviço',
      value: _formatIntDays(_intFromEntry(latestEntry, 'periodoServico')),
    ),
    _HistoryDetail(
      label: 'Dias para secar',
      value: _formatIntDays(_intFromEntry(latestEntry, 'diasParaSecar')),
    ),
    _HistoryDetail(
      label: 'Previsão de secagem',
      value: formatDate(dryOffForecast),
    ),
    _HistoryDetail(
      label: 'Mês de secagem',
      value: _valueOrDash(
        _stringFromEntry(latestEntry, 'mesSecagem') ?? _monthLabel(dryOffForecast),
      ),
    ),
    _HistoryDetail(
      label: 'Diferença de secagem',
      value: _formatIntDays(_intFromEntry(latestEntry, 'diferencaSecagem')),
    ),
    _HistoryDetail(
      label: 'Período de lactação',
      value: _formatIntDays(_intFromEntry(latestEntry, 'periodoLactacao')),
    ),
    _HistoryDetail(
      label: 'Data pré-parto',
      value: formatDate(prePartumDate),
    ),
    _HistoryDetail(
      label: 'Mês pré-parto',
      value: _valueOrDash(
        _stringFromEntry(latestEntry, 'mesPreParto') ?? _monthLabel(prePartumDate),
      ),
    ),
    _HistoryDetail(
      label: 'Duração pré-parto',
      value: _formatIntDays(_intFromEntry(latestEntry, 'duracaoPreParto')),
    ),
    _HistoryDetail(
      label: 'Previsão de parto',
      value: formatDate(calvingForecast),
    ),
    _HistoryDetail(
      label: 'Mês previsto do parto',
      value: _valueOrDash(
        _stringFromEntry(latestEntry, 'mesPrevistoParto') ??
            _monthLabel(calvingForecast),
      ),
    ),
    _HistoryDetail(
      label: 'IEP projetado',
      value: _formatDoubleMonths(_doubleFromEntry(latestEntry, 'iepProjetado')),
    ),
    _HistoryDetail(
      label: 'Controle leiteiro com desconto',
      value: _formatDoubleOrDash(
        _doubleFromEntry(latestEntry, 'controleLeiteiroComDesconto'),
      ),
    ),
  ];
}

List<int> _iaIntervalsFromEntry(VisitAnimalEntryModel? entry) {
  if (entry == null) return const [];

  return [
    _intFromEntry(entry, 'intervalo1e2Ia'),
    _intFromEntry(entry, 'intervalo2e3Ia'),
    _intFromEntry(entry, 'intervalo3e4Ia'),
    _intFromEntry(entry, 'intervalo4e5Ia'),
  ].whereType<int>().toList(growable: false);
}

String _formatAgeFromBirthDate(DateTime? birthDate) {
  if (birthDate == null) return '--';

  final today = DateUtils.dateOnly(DateTime.now());
  final birth = DateUtils.dateOnly(birthDate);
  if (birth.isAfter(today)) return '--';

  var years = today.year - birth.year;
  var months = today.month - birth.month;

  if (today.day < birth.day) {
    months -= 1;
  }

  if (months < 0) {
    years -= 1;
    months += 12;
  }

  if (years <= 0 && months <= 0) return '0 meses';
  if (years <= 0) return '$months ${months == 1 ? 'mês' : 'meses'}';
  if (months <= 0) return '$years ${years == 1 ? 'ano' : 'anos'}';
  return '$years ${years == 1 ? 'ano' : 'anos'} e $months ${months == 1 ? 'mês' : 'meses'}';
}

String? _monthLabel(DateTime? date) {
  if (date == null) return null;

  const months = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  return months[date.month - 1];
}

String _formatIntegerOrDash(int? value) {
  if (value == null) return '--';
  return formatInteger(value);
}

String _formatIntDays(int? value) {
  if (value == null) return '--';
  return '${formatInteger(value)} dias';
}

String _formatDoubleDays(double? value) {
  if (value == null || !value.isFinite) return '--';
  return '${formatDecimal(value)} dias';
}

String _formatDoubleMonths(double? value) {
  if (value == null || !value.isFinite) return '--';
  return '${formatDecimal(value)} meses';
}

String _formatDoubleOrDash(double? value) {
  if (value == null || !value.isFinite) return '--';
  return formatDecimal(value);
}

String _formatBool(bool? value) {
  if (value == null) return '--';
  return value ? 'Sim' : 'Não';
}

Object? _readEntryField(VisitAnimalEntryModel? entry, String fieldName) {
  if (entry == null) return null;

  try {
    final dynamic value = entry;
    switch (fieldName) {
      case 'del':
        return value.del;
      case 'dataNascimento':
        return value.dataNascimento;
      case 'idadePrimeiroPartoMeses':
        return value.idadePrimeiroPartoMeses;
      case 'idadePrimeiroParto':
        return value.idadePrimeiroParto;
      case 'idadePrimeiraIa':
        return value.idadePrimeiraIa;
      case 'mesParto':
        return value.mesParto;
      case 'dataUltimoParto':
        return value.dataUltimoParto;
      case 'anoUltimoParto':
        return value.anoUltimoParto;
      case 'iepAtual':
        return value.iepAtual;
      case 'classificacaoPartos':
        return value.classificacaoPartos;
      case 'vacaApta':
        return value.vacaApta;
      case 'intervalo1e2Ia':
        return value.intervalo1e2Ia;
      case 'intervalo2e3Ia':
        return value.intervalo2e3Ia;
      case 'intervalo3e4Ia':
        return value.intervalo3e4Ia;
      case 'intervalo4e5Ia':
        return value.intervalo4e5Ia;
      case 'mediaIntervaloIa':
        return value.mediaIntervaloIa;
      case 'previsaoRetornoCio':
        return value.previsaoRetornoCio;
      case 'diasPrenhez':
        return value.diasPrenhez;
      case 'delPrimeiraIa':
        return value.delPrimeiraIa;
      case 'periodoServico':
        return value.periodoServico;
      case 'diasParaSecar':
        return value.diasParaSecar;
      case 'previsaoSecagem':
        return value.previsaoSecagem;
      case 'mesSecagem':
        return value.mesSecagem;
      case 'diferencaSecagem':
        return value.diferencaSecagem;
      case 'periodoLactacao':
        return value.periodoLactacao;
      case 'dataSecagemEfetiva':
        return value.dataSecagemEfetiva;
      case 'dataPreParto':
        return value.dataPreParto;
      case 'entradaPreParto':
        return value.entradaPreParto;
      case 'mesPreParto':
        return value.mesPreParto;
      case 'duracaoPreParto':
        return value.duracaoPreParto;
      case 'previsaoParto':
        return value.previsaoParto;
      case 'dataPrevistaParto':
        return value.dataPrevistaParto;
      case 'mesPrevistoParto':
        return value.mesPrevistoParto;
      case 'iepProjetado':
        return value.iepProjetado;
      case 'controleLeiteiroComDesconto':
        return value.controleLeiteiroComDesconto;
      case 'dataUltimaIa':
        return value.dataUltimaIa;
      case 'dataInseminacao':
        return value.dataInseminacao;
    }
  } catch (_) {
    return null;
  }

  return null;
}

String? _stringFromEntry(VisitAnimalEntryModel? entry, String fieldName) {
  final value = _readEntryField(entry, fieldName);
  if (value == null) return null;
  return value.toString();
}

DateTime? _dateFromEntry(VisitAnimalEntryModel? entry, String fieldName) {
  final value = _readEntryField(entry, fieldName);
  if (value is DateTime) return value;
  return null;
}

int? _intFromEntry(VisitAnimalEntryModel? entry, String fieldName) {
  final value = _readEntryField(entry, fieldName);
  if (value is int) return value;
  if (value is num) return value.round();
  return null;
}

double? _doubleFromEntry(VisitAnimalEntryModel? entry, String fieldName) {
  final value = _readEntryField(entry, fieldName);
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return null;
}

bool? _boolFromEntry(VisitAnimalEntryModel? entry, String fieldName) {
  final value = _readEntryField(entry, fieldName);
  if (value is bool) return value;
  return null;
}

class _ProductiveHistoryPanel extends StatelessWidget {
  const _ProductiveHistoryPanel({required this.animal});

  final AnimalSummaryModel animal;

  @override
  Widget build(BuildContext context) {
    final history = animal.historicoReprodutivo?.trim();
    final details = [
      _HistoryDetail(
        label: 'Nascimento',
        value: formatDate(animal.dataNascimento),
      ),
      _HistoryDetail(label: 'Sexo', value: _valueOrDash(animal.sexo)),
      _HistoryDetail(label: 'Status atual', value: animal.status.label),
      _HistoryDetail(
        label: 'Status reprodutivo',
        value: reproductiveStatusFor(animal).label,
      ),
    ];

    return _HistoryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < details.length; index++) ...[
            _HistoryDetailRow(detail: details[index]),
            if (index < details.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          Divider(color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Text(
            history?.isNotEmpty == true
                ? history!
                : 'Sem histórico produtivo ou reprodutivo resumido.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimalEventHistoryList extends StatelessWidget {
  const _AnimalEventHistoryList({required this.events});

  final List<AnimalHistoryEventModel> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const _HistoryEmptyPanel(
        message: 'Nenhum evento registrado para este animal.',
      );
    }

    return Column(
      children: [
        for (var index = 0; index < events.length; index++) ...[
          _HistoryTimelineItem(
            icon: _eventTypeIcon(events[index].tipo),
            title: _eventTypeLabel(events[index].tipo),
            date: events[index].dataEvento,
            details: _eventDetails(events[index]),
          ),
          if (index < events.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AnimalIaHistoryPanel extends StatelessWidget {
  const _AnimalIaHistoryPanel({required this.history});

  final _IaHistorySummary history;

  @override
  Widget build(BuildContext context) {
    if (history.totalIas == 0 && history.dates.isEmpty) {
      return const _HistoryEmptyPanel(
        message: 'Nenhuma IA registrada para este animal.',
      );
    }

    final details = [
      _HistoryDetail(
        label: 'Número total de IAs',
        value: formatInteger(history.totalIas),
      ),
      _HistoryDetail(label: 'Última IA', value: formatDate(history.lastDate)),
      _HistoryDetail(
        label: 'Histórico completo',
        value: history.dates.isEmpty
            ? 'Datas não informadas'
            : history.dates.map(formatDate).join(' | '),
      ),
      _HistoryDetail(
        label: 'Intervalos entre IAs',
        value: history.intervals.isEmpty
            ? '--'
            : history.intervals
                  .map((days) => '${formatInteger(days)} dias')
                  .join(' | '),
      ),
      _HistoryDetail(
        label: 'Média de intervalos',
        value: history.averageInterval == null
            ? '--'
            : '${formatDecimal(history.averageInterval!)} dias',
      ),
    ];

    return _HistoryPanel(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final detail in details) _HistoryDetailChip(detail: detail),
        ],
      ),
    );
  }
}

class _AnimalVisitHistoryList extends StatelessWidget {
  const _AnimalVisitHistoryList({required this.records});

  final List<_AnimalVisitHistoryRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const _HistoryEmptyPanel(
        message: 'Nenhuma visita com dados deste animal.',
      );
    }

    return Column(
      children: [
        for (var index = 0; index < records.length; index++) ...[
          _HistoryTimelineItem(
            icon: Icons.assignment_turned_in_outlined,
            title: 'Visita técnica',
            date: records[index].visit.dataVisita,
            subtitle: records[index].visit.observacoes,
            details: _visitDetails(records[index].entry),
          ),
          if (index < records.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AnimalMovementHistoryPanel extends StatelessWidget {
  const _AnimalMovementHistoryPanel({
    required this.animal,
    required this.propertyName,
  });

  final AnimalSummaryModel animal;
  final String propertyName;

  @override
  Widget build(BuildContext context) {
    // TODO(api): quando o endpoint/model de historico completo existir,
    // renderizar aqui movimentacoes reais de propriedade/lote, alteracoes de
    // status e auditoria. Hoje estes dados estao temporariamente derivados do
    // estado atual do AnimalSummaryModel.
    return _HistoryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HistoryDetailRow(
            detail: _HistoryDetail(
              label: 'Propriedade atual',
              value: propertyName.trim().isEmpty
                  ? 'Não informada'
                  : propertyName,
            ),
          ),
          const SizedBox(height: 10),
          _HistoryDetailRow(
            detail: _HistoryDetail(
              label: 'Status atual',
              value: animal.status.label,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sem movimentações históricas registradas para este animal.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTimelineItem extends StatelessWidget {
  const _HistoryTimelineItem({
    required this.icon,
    required this.title,
    required this.date,
    required this.details,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final DateTime? date;
  final String? subtitle;
  final List<_HistoryDetail> details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cleanSubtitle = subtitle?.trim();

    return _HistoryPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      formatDate(date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (cleanSubtitle?.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text(
                    cleanSubtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final detail in details)
                        _HistoryDetailChip(detail: detail),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.28)),
      ),
      child: child,
    );
  }
}

class _HistoryDetailRow extends StatelessWidget {
  const _HistoryDetailRow({required this.detail});

  final _HistoryDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            detail.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            detail.value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryDetailChip extends StatelessWidget {
  const _HistoryDetailChip({required this.detail});

  final _HistoryDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.15,
          ),
          children: [
            TextSpan(
              text: '${detail.label}: ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(
              text: detail.value,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryEmptyPanel extends StatelessWidget {
  const _HistoryEmptyPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _HistoryPanel(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _AnimalHistoryLoading extends StatelessWidget {
  const _AnimalHistoryLoading();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: colorScheme.primary),
          const SizedBox(height: 14),
          Text(
            'Carregando histórico...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimalHistoryLoadError extends StatelessWidget {
  const _AnimalHistoryLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _HistoryPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Não foi possível carregar o histórico do animal.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          AppButton(
            text: 'Tentar novamente',
            outlined: true,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}


class _AnimalHistoryData {
  const _AnimalHistoryData({
    required this.animal,
    required this.events,
    required this.visits,
  });

  final AnimalSummaryModel animal;
  final List<AnimalHistoryEventModel> events;
  final List<_AnimalVisitHistoryRecord> visits;

  VisitAnimalEntryModel? get latestVisitEntry =>
      visits.isEmpty ? null : visits.first.entry;
}

class _AnimalVisitHistoryRecord {
  const _AnimalVisitHistoryRecord({required this.visit, required this.entry});

  final VisitSummaryModel visit;
  final VisitAnimalEntryModel entry;
}

class _IaHistorySummary {
  const _IaHistorySummary({
    required this.dates,
    required this.totalIas,
    required this.intervals,
    required this.averageInterval,
  });

  factory _IaHistorySummary.fromHistoryData(_AnimalHistoryData data) {
    final dates = <DateTime>[];
    var totalIas = 0;

    if (data.animal.dataInseminacao != null) {
      dates.add(DateUtils.dateOnly(data.animal.dataInseminacao!));
      totalIas = 1;
    }

    for (final event in data.events) {
      if (event.tipo == 'INSEMINATION' && event.dataEvento != null) {
        dates.add(DateUtils.dateOnly(event.dataEvento!));
      }
    }

    for (final record in data.visits) {
      dates.addAll(_iaDatesFromVisitEntry(record.entry));
      final entryIas = record.entry.numeroIaRecebida;
      if (entryIas != null && entryIas > totalIas) {
        totalIas = entryIas;
      }
    }

    final uniqueDates = _uniqueSortedDates(dates);
    final resolvedTotal = totalIas > uniqueDates.length
        ? totalIas
        : uniqueDates.length;
    final intervals = <int>[];

    for (var index = 1; index < uniqueDates.length; index++) {
      intervals.add(
        uniqueDates[index].difference(uniqueDates[index - 1]).inDays,
      );
    }

    final averageInterval = intervals.isEmpty
        ? null
        : intervals.fold<int>(0, (sum, value) => sum + value) /
              intervals.length;

    return _IaHistorySummary(
      dates: uniqueDates,
      totalIas: resolvedTotal,
      intervals: intervals,
      averageInterval: averageInterval,
    );
  }

  final List<DateTime> dates;
  final int totalIas;
  final List<int> intervals;
  final double? averageInterval;

  DateTime? get lastDate => dates.isEmpty ? null : dates.last;
}

class _HistoryInfoItem {
  const _HistoryInfoItem({required this.label, required this.value});

  final String label;
  final String value;
}

class _HistoryDetail {
  const _HistoryDetail({required this.label, required this.value});

  final String label;
  final String value;
}

bool _visitBelongsToAnimalProperty(
  VisitSummaryModel visit,
  AnimalSummaryModel animal,
) {
  if (animal.idPropriedade > 0 && visit.idPropriedade == animal.idPropriedade) {
    return true;
  }

  final animalExternalProperty = animal.idExternoPropriedade.trim();
  return animalExternalProperty.isNotEmpty &&
      visit.idExternoPropriedade.trim() == animalExternalProperty;
}

Iterable<_AnimalVisitHistoryRecord> _visitRecordsForAnimal(
  VisitSummaryModel visit,
  AnimalSummaryModel animal,
) {
  return visit.animais
      .where((entry) => _visitEntryBelongsToAnimal(entry, animal))
      .map((entry) => _AnimalVisitHistoryRecord(visit: visit, entry: entry));
}

bool _visitEntryBelongsToAnimal(
  VisitAnimalEntryModel entry,
  AnimalSummaryModel animal,
) {
  if (animal.id > 0 && entry.animalId == animal.id) {
    return true;
  }

  final externalId = animal.idExterno.trim();
  if (externalId.isNotEmpty && entry.animalIdExterno.trim() == externalId) {
    return true;
  }

  final code = animal.codigo.trim();
  return code.isNotEmpty && entry.animalCodigo.trim() == code;
}

int _compareVisitRecordsDesc(
  _AnimalVisitHistoryRecord a,
  _AnimalVisitHistoryRecord b,
) {
  return _compareNullableDatesDesc(a.visit.dataVisita, b.visit.dataVisita);
}

int _compareHistoryEventsDesc(
  AnimalHistoryEventModel a,
  AnimalHistoryEventModel b,
) {
  return _compareNullableDatesDesc(a.dataEvento, b.dataEvento);
}

int _compareNullableDatesDesc(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return b.compareTo(a);
}

List<DateTime> _iaDatesFromVisitEntry(VisitAnimalEntryModel entry) {
  return _uniqueSortedDates([
    if (entry.dataPrimeiraIa != null) entry.dataPrimeiraIa!,
    if (entry.dataSegundaIa != null) entry.dataSegundaIa!,
    if (entry.dataTerceiraIa != null) entry.dataTerceiraIa!,
    if (entry.dataQuartaIa != null) entry.dataQuartaIa!,
    if (entry.dataQuintaIa != null) entry.dataQuintaIa!,
    if (entry.dataUltimaIa != null) entry.dataUltimaIa!,
  ]);
}

List<DateTime> _uniqueSortedDates(Iterable<DateTime> values) {
  final dates = <DateTime>[];
  final seen = <String>{};

  for (final rawDate in values) {
    final date = DateUtils.dateOnly(rawDate);
    final key = '${date.year}-${date.month}-${date.day}';
    if (seen.add(key)) {
      dates.add(date);
    }
  }

  dates.sort();
  return List.unmodifiable(dates);
}

String _eventTypeLabel(String value) {
  return switch (value) {
    'INSEMINATION' => 'Inseminação',
    'PREGNANCY_DIAGNOSIS' => 'Diagnóstico de prenhez',
    'CALVING' => 'Parto',
    'DRY_OFF' => 'Secagem',
    'GESTATIONAL_LOSS' => 'Perda gestacional',
    _ => _valueOrDash(value),
  };
}

IconData _eventTypeIcon(String value) {
  return switch (value) {
    'INSEMINATION' => Icons.science_outlined,
    'PREGNANCY_DIAGNOSIS' => Icons.monitor_heart_outlined,
    'CALVING' => Icons.child_friendly_outlined,
    'DRY_OFF' => Icons.water_drop_outlined,
    'GESTATIONAL_LOSS' => Icons.warning_amber_outlined,
    _ => Icons.event_outlined,
  };
}

List<_HistoryDetail> _eventDetails(AnimalHistoryEventModel event) {
  final details = <_HistoryDetail>[];

  if (event.dataPrevistaParto != null) {
    details.add(
      _HistoryDetail(
        label: 'Previsão parto',
        value: formatDate(event.dataPrevistaParto),
      ),
    );
  }

  if (event.prenhezConfirmada != null) {
    details.add(
      _HistoryDetail(
        label: 'Prenhez',
        value: event.prenhezConfirmada! ? 'Confirmada' : 'Não confirmada',
      ),
    );
  }

  _addTextDetail(details, 'Observação', event.observacoes);
  return details;
}

List<_HistoryDetail> _visitDetails(VisitAnimalEntryModel entry) {
  final details = <_HistoryDetail>[];

  _addTextDetail(details, 'Produtiva', entry.situacaoProdutiva);
  _addTextDetail(details, 'Reprodutiva', entry.situacaoReprodutiva);
  _addTextDetail(details, 'Decisão', entry.decisao);
  _addTextDetail(details, 'Diagnóstico', entry.diagnostico);

  if (entry.dataUltimaIa != null) {
    details.add(
      _HistoryDetail(label: 'Última IA', value: formatDate(entry.dataUltimaIa)),
    );
  }

  if (entry.numeroIaRecebida != null) {
    details.add(
      _HistoryDetail(
        label: 'IAs',
        value: formatInteger(entry.numeroIaRecebida!),
      ),
    );
  }

  if (entry.diasPrenhez != null) {
    details.add(
      _HistoryDetail(
        label: 'Prenhez',
        value: '${formatInteger(entry.diasPrenhez!)} dias',
      ),
    );
  }

  if (entry.del != null) {
    details.add(
      _HistoryDetail(label: 'DEL', value: '${formatInteger(entry.del!)} dias'),
    );
  }

  if (entry.previsaoSecagem != null) {
    details.add(
      _HistoryDetail(
        label: 'Prev. secagem',
        value: formatDate(entry.previsaoSecagem),
      ),
    );
  }

  if (entry.previsaoParto != null) {
    details.add(
      _HistoryDetail(
        label: 'Prev. parto',
        value: formatDate(entry.previsaoParto),
      ),
    );
  }

  final iaDates = _iaDatesFromVisitEntry(entry);
  if (iaDates.isNotEmpty) {
    details.add(
      _HistoryDetail(
        label: 'Historico de IAs',
        value: iaDates.map(formatDate).join(' | '),
      ),
    );
  }

  _addDateDetail(details, 'Nascimento', entry.dataNascimento);
  _addDateDetail(details, 'Primeiro parto', entry.dataPrimeiroParto);
  _addDateDetail(details, 'Último parto', entry.dataUltimoParto);
  _addDateDetail(details, 'Parto anterior', entry.dataPartoAnterior);
  _addIntDetail(details, 'Número de partos', entry.numeroPartos, suffix: '');
  _addDoubleDetail(
    details,
    'Idade no primeiro parto',
    entry.idadePrimeiroPartoMeses,
    suffix: ' meses',
  );
  _addDoubleDetail(
    details,
    'Idade na primeira IA',
    entry.idadePrimeiraIa,
    suffix: ' meses',
  );
  _addTextDetail(details, 'Mês do parto', entry.mesParto);
  _addIntDetail(
    details,
    'Ano do último parto',
    entry.anoUltimoParto,
    suffix: '',
  );
  _addDoubleDetail(details, 'IEP atual', entry.iepAtual, suffix: ' meses');
  _addTextDetail(details, 'Primípara/multípara', entry.classificacaoPartos);
  _addBoolDetail(details, 'Vaca apta', entry.vacaApta);
  _addIntDetail(details, 'Intervalo 1a-2a IA', entry.intervalo1e2Ia);
  _addIntDetail(details, 'Intervalo 2a-3a IA', entry.intervalo2e3Ia);
  _addIntDetail(details, 'Intervalo 3a-4a IA', entry.intervalo3e4Ia);
  _addIntDetail(details, 'Intervalo 4a-5a IA', entry.intervalo4e5Ia);
  _addDoubleDetail(
    details,
    'Média intervalo IA',
    entry.mediaIntervaloIa,
    suffix: ' dias',
  );
  _addDateDetail(details, 'Previsão retorno cio', entry.previsaoRetornoCio);
  _addIntDetail(details, 'DEL primeira IA', entry.delPrimeiraIa);
  _addIntDetail(details, 'Período de serviço', entry.periodoServico);
  _addDateDetail(details, 'Previsão secagem', entry.previsaoSecagem);
  _addTextDetail(details, 'Mês da secagem', entry.mesSecagem);
  _addIntDetail(details, 'Diferença de secagem', entry.diferencaSecagem);
  _addIntDetail(details, 'Período de lactação', entry.periodoLactacao);
  _addDateDetail(details, 'Secagem efetiva', entry.dataSecagemEfetiva);
  _addDateDetail(details, 'Data de pré-parto', entry.dataPreParto);
  _addDateDetail(details, 'Entrada em pré-parto', entry.entradaPreParto);
  _addTextDetail(details, 'Mês de pré-parto', entry.mesPreParto);
  _addIntDetail(details, 'Duração do pré-parto', entry.duracaoPreParto);
  _addTextDetail(details, 'Mês previsto do parto', entry.mesPrevistoParto);
  _addDoubleDetail(
    details,
    'IEP projetado',
    entry.iepProjetado,
    suffix: ' meses',
  );
  _addDoubleDetail(details, 'Controle leiteiro', entry.controleLeiteiro);
  _addDoubleDetail(
    details,
    'Controle leiteiro com desconto',
    entry.controleLeiteiroComDesconto,
  );

  return details;
}

void _addTextDetail(List<_HistoryDetail> details, String label, String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return;
  details.add(_HistoryDetail(label: label, value: text));
}

void _addDateDetail(
  List<_HistoryDetail> details,
  String label,
  DateTime? value,
) {
  if (value == null) return;
  details.add(_HistoryDetail(label: label, value: formatDate(value)));
}

void _addIntDetail(
  List<_HistoryDetail> details,
  String label,
  int? value, {
  String suffix = ' dias',
}) {
  if (value == null) return;
  details.add(
    _HistoryDetail(label: label, value: '${formatInteger(value)}$suffix'),
  );
}

void _addDoubleDetail(
  List<_HistoryDetail> details,
  String label,
  double? value, {
  String suffix = '',
}) {
  if (value == null || !value.isFinite) return;
  details.add(
    _HistoryDetail(label: label, value: '${formatDecimal(value)}$suffix'),
  );
}

void _addBoolDetail(List<_HistoryDetail> details, String label, bool? value) {
  if (value == null) return;
  details.add(_HistoryDetail(label: label, value: value ? 'Sim' : 'Nao'));
}

String _valueOrDash(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return '--';
  return text;
}





class _ReproductiveStatusPill extends StatelessWidget {
  const _ReproductiveStatusPill({required this.status});

  final AnimalReproductiveStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = _reproductiveStatusColors(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12, color: colors.foreground),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              status.label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


_ReproductiveStatusColors _reproductiveStatusColors(
  BuildContext context,
  AnimalReproductiveStatus status,
) {
  final colorScheme = Theme.of(context).colorScheme;

  return switch (status) {
    AnimalReproductiveStatus.pregnant => const _ReproductiveStatusColors(
      background: Color(0xFFDFF8EA),
      border: Color(0xFFB9E9CF),
      foreground: Color(0xFF0D6B42),
    ),
    AnimalReproductiveStatus.empty => const _ReproductiveStatusColors(
      background: Color(0xFFFFE3EA),
      border: Color(0xFFF7B8C9),
      foreground: Color(0xFFB4234A),
    ),
    AnimalReproductiveStatus.inseminated ||
    AnimalReproductiveStatus.inseminatedSt ||
    AnimalReproductiveStatus.protocol ||
    AnimalReproductiveStatus.waitingDiagnosis =>
      const _ReproductiveStatusColors(
        background: Color(0xFFE0F2FE),
        border: Color(0xFFB9E1FA),
        foreground: Color(0xFF0369A1),
      ),
    AnimalReproductiveStatus.dry => const _ReproductiveStatusColors(
      background: Color(0xFFFFF0C2),
      border: Color(0xFFEFD58C),
      foreground: Color(0xFF8A5C00),
    ),
    AnimalReproductiveStatus.released => const _ReproductiveStatusColors(
      background: Color(0xFFDFF8EA),
      border: Color(0xFFB9E9CF),
      foreground: Color(0xFF0D6B42),
    ),
    AnimalReproductiveStatus.delayed ||
    AnimalReproductiveStatus.induction ||
    AnimalReproductiveStatus.discard ||
    AnimalReproductiveStatus.pev ||
    AnimalReproductiveStatus.noAge ||
    AnimalReproductiveStatus.calf ||
    AnimalReproductiveStatus.pending => _ReproductiveStatusColors(
      background: colorScheme.surfaceContainerHighest,
      border: colorScheme.outline.withValues(alpha: 0.55),
      foreground: colorScheme.onSurfaceVariant,
    ),
  };
}

class _ReproductiveStatusColors {
  const _ReproductiveStatusColors({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}


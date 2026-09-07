import 'package:cysvet_app/app/theme.dart';
import 'package:cysvet_app/core/constants/app_constants.dart';
import 'package:cysvet_app/core/utils/formatters.dart';
import 'package:cysvet_app/core/widgets/app_card.dart';
import 'package:cysvet_app/features/visits/domain/visit_summary_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

class VisitMobileCardList<T> extends StatelessWidget {
  const VisitMobileCardList({
    super.key,
    required this.items,
    required this.visitFor,
    required this.propertyNameFor,
    required this.onTap,
    this.footerLabel,
    this.emptyMessage = 'Nenhuma visita encontrada.',
  });

  final List<T> items;
  final VisitSummaryModel Function(T item) visitFor;
  final String Function(T item) propertyNameFor;
  final ValueChanged<T> onTap;
  final String? footerLabel;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(24),
        borderRadius: 16,
        shadow: false,
        child: Text(
          emptyMessage,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          VisitMobileCard(
            visit: visitFor(items[index]),
            propertyName: propertyNameFor(items[index]),
            onTap: () => onTap(items[index]),
          ),
          if (index < items.length - 1) const SizedBox(height: 10),
        ],
        if (footerLabel != null) ...[
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            borderRadius: 16,
            shadow: false,
            child: Text(
              footerLabel!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class VisitMobileCard extends StatelessWidget {
  const VisitMobileCard({
    super.key,
    required this.visit,
    required this.propertyName,
    required this.onTap,
  });

  final VisitSummaryModel visit;
  final String propertyName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        hoverColor: colorScheme.primary.withValues(alpha: 0.045),
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        child: AppCard(
          backgroundColor: Colors.transparent,
          padding: const EdgeInsets.all(12),
          borderRadius: 16,
          borderColor: colorScheme.outlineVariant.withValues(alpha: 0.8),
          shadow: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.primary2Color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      size: 24,
                      color: AppTheme.primary2Color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatDate(visit.dataVisita),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _dashIfBlank(propertyName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: Center(
                      child: _VisitCountPill(count: visit.animais.length),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _VisitProtocolCell(visit: visit)),
                  const SizedBox(width: 16),
                  Expanded(child: _VisitNextStepCell(visit: visit)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisitProtocolCell extends StatelessWidget {
  const _VisitProtocolCell({required this.visit});

  final VisitSummaryModel visit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _protocolLabel(visit),
          maxLines: 3,
          overflow: TextOverflow.visible,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _dashIfBlank(visit.veterinarioResponsavel),
          maxLines: 2,
          overflow: TextOverflow.visible,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          'Prenhez: ${_pregnancyRateLabel(visit)}',
          maxLines: 2,
          overflow: TextOverflow.visible,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _VisitNextStepCell extends StatelessWidget {
  const _VisitNextStepCell({required this.visit});

  final VisitSummaryModel visit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Próximo passo',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _nextStepText(visit),
          maxLines: 4,
          overflow: TextOverflow.visible,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _VisitCountPill extends StatelessWidget {
  const _VisitCountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = AppTheme.primary2Color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(MdiIcons.cow, size: 16, color: foreground),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

String _protocolLabel(VisitSummaryModel visit) {
  final animals = visit.animais;
  if (animals.isEmpty) return 'Visita técnica';

  final hasDiagnosis = animals.any(
    (animal) =>
        _cleanText(animal.diagnostico) != null ||
        _isPregnant(animal) ||
        _isEmptyReproductive(animal),
  );
  final hasProtocol = animals.any(
    (animal) =>
        _cleanText(animal.decisao) != null ||
        animal.dataUltimaIa != null ||
        animal.numeroIaRecebida != null,
  );

  if (hasProtocol && hasDiagnosis) return 'IATF + Diagnóstico';
  if (hasProtocol) return 'IATF / Protocolo reprodutivo';
  if (hasDiagnosis) return 'Diagnóstico reprodutivo';
  return 'Conferência técnica';
}

String _nextStepText(VisitSummaryModel visit) {
  final steps = <_VisitNextStep>[];

  for (final animal in visit.animais) {
    final identification =
        _cleanText(animal.animalCodigo) ??
        _cleanText(animal.animalIdExterno) ??
        'animal';

    if (animal.previsaoSecagem != null) {
      steps.add(
        _VisitNextStep(
          date: animal.previsaoSecagem!,
          text: 'Secagem prevista para $identification.',
        ),
      );
    }

    if (animal.dataPreParto != null) {
      steps.add(
        _VisitNextStep(
          date: animal.dataPreParto!,
          text: 'Pré-parto previsto para $identification.',
        ),
      );
    }

    if (animal.previsaoParto != null) {
      steps.add(
        _VisitNextStep(
          date: animal.previsaoParto!,
          text: 'Parto previsto para $identification.',
        ),
      );
    }
  }

  steps.sort((a, b) => a.date.compareTo(b.date));

  if (steps.isEmpty) {
    return _cleanText(visit.observacoes) ?? 'Próximos passos pendentes.';
  }

  final first = steps.first;
  return '${formatDate(first.date)} - ${first.text}';
}

String _pregnancyRateLabel(VisitSummaryModel visit) {
  final pregnant = visit.animais.where(_isPregnant).length;
  final empty = visit.animais.where(_isEmptyReproductive).length;
  final denominator = pregnant + empty;
  if (denominator == 0) return '--';

  return formatPercent(pregnant / denominator);
}

bool _isPregnant(VisitAnimalEntryModel entry) {
  if (_isEmptyReproductive(entry)) return false;
  if (entry.diasPrenhez != null) return true;

  return _containsAny(_reproductiveText(entry), const [
    'prenhe',
    'prenha',
    'prenhez',
    'positivo',
    'gestante',
  ]);
}

bool _isEmptyReproductive(VisitAnimalEntryModel entry) {
  return _containsAny(_reproductiveText(entry), const [
    'vazia',
    'vazio',
    'negativo',
    'nao prenha',
    'nao gestante',
  ]);
}

String _reproductiveText(VisitAnimalEntryModel entry) {
  return [
    entry.situacaoReprodutiva,
    entry.decisao,
    entry.diagnostico,
  ].whereType<String>().join(' ');
}

bool _containsAny(String value, List<String> terms) {
  final normalized = value.normalize();
  return terms.any((term) => normalized.contains(term.normalize()));
}

String? _cleanText(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

String _dashIfBlank(String? value) {
  return _cleanText(value) ?? '--';
}

class _VisitNextStep {
  const _VisitNextStep({required this.date, required this.text});

  final DateTime date;
  final String text;
}

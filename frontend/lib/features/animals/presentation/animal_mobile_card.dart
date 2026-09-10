import 'package:cysvet_app/app/theme.dart';
import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/core/utils/formatters.dart';
import 'package:cysvet_app/core/widgets/app_button.dart';
import 'package:cysvet_app/core/widgets/app_card.dart';
import 'package:cysvet_app/features/animals/domain/animal_summary_model.dart';
import 'package:cysvet_app/features/indicators/indicador_reprodutivo_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

class AnimalMobileCardList extends StatelessWidget {
  const AnimalMobileCardList({
    super.key,
    required this.animals,
    required this.propertyNameFor,
    required this.onTap,
    required this.onEdit,
    required this.onInactivate,
    required this.onActivate,
    required this.onDelete,
    this.footerLabel,
    this.emptyMessage = 'Nenhum animal encontrado.',
  });

  final List<AnimalSummaryModel> animals;
  final String Function(AnimalSummaryModel animal) propertyNameFor;
  final ValueChanged<AnimalSummaryModel> onTap;
  final ValueChanged<AnimalSummaryModel> onEdit;
  final ValueChanged<AnimalSummaryModel> onInactivate;
  final ValueChanged<AnimalSummaryModel> onActivate;
  final ValueChanged<AnimalSummaryModel> onDelete;
  final String? footerLabel;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (animals.isEmpty) {
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
        for (var index = 0; index < animals.length; index++) ...[
          AnimalMobileCard(
            animal: animals[index],
            propertyName: propertyNameFor(animals[index]),
            onTap: () => onTap(animals[index]),
            onEdit: () => onEdit(animals[index]),
            onInactivate: () => onInactivate(animals[index]),
            onActivate: () => onActivate(animals[index]),
            onDelete: () => onDelete(animals[index]),
          ),
          if (index < animals.length - 1) const SizedBox(height: 10),
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

class AnimalMobileCard extends StatelessWidget {
  const AnimalMobileCard({
    super.key,
    required this.animal,
    required this.propertyName,
    required this.onEdit,
    required this.onInactivate,
    required this.onActivate,
    required this.onDelete,
    required this.onTap,
  });

  final AnimalSummaryModel animal;
  final String propertyName;
  final VoidCallback onEdit;
  final VoidCallback onInactivate;
  final VoidCallback onActivate;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final reproductiveStatus =
        IndicadorReprodutivoCalculator.resolveAnimalStatus(animal);

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
                      MdiIcons.cow,
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
                          _animalCodeLabel(animal.codigo),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          propertyName.trim().isEmpty
                              ? 'Propriedade não informada'
                              : propertyName,
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _AnimalReproductiveStatusPill(
                          status: reproductiveStatus,
                        ),
                        const SizedBox(width: 2),
                        _AnimalMobileActionsMenu(
                          animal: animal,
                          onEdit: onEdit,
                          onInactivate: onInactivate,
                          onActivate: onActivate,
                          onDelete: onDelete,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _AnimalIaBullCell(animal: animal)),
                  const SizedBox(width: 16),
                  Expanded(child: _LastEventCell(animal: animal)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimalIaBullCell extends StatelessWidget {
  const _AnimalIaBullCell({required this.animal});

  final AnimalSummaryModel animal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          animal.touroIa?.trim().isNotEmpty == true ? animal.touroIa! : '--',
          maxLines: 3,
          overflow: TextOverflow.visible,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          'Nascimento: ${formatDate(animal.dataNascimento)}',
          maxLines: 2,
          overflow: TextOverflow.visible,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          'Lactação: ${animal.numeroLactacao}',
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

class _LastEventCell extends StatelessWidget {
  const _LastEventCell({required this.animal});

  final AnimalSummaryModel animal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lastBirth = animal.dataUltimoParto;
    final inseminationDate = animal.dataInseminacao;

    if (lastBirth == null && inseminationDate == null) {
      return Text(
        animal.historicoReprodutivo?.trim().isNotEmpty == true
            ? 'Histórico informado'
            : 'Sem evento',
        maxLines: 4,
        overflow: TextOverflow.visible,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lastBirth != null)
          Text(
            'Parto em ${formatDate(lastBirth)}',
            maxLines: 3,
            overflow: TextOverflow.visible,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        if (inseminationDate != null) ...[
          if (lastBirth != null) const SizedBox(height: 4),
          Text(
            'IA em ${formatDate(inseminationDate)}',
            maxLines: 3,
            overflow: TextOverflow.visible,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (animal.diasEmLactacao != null) ...[
          const SizedBox(height: 4),
          Text(
            '${animal.diasEmLactacao} dias em lactação',
            maxLines: 3,
            overflow: TextOverflow.visible,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _AnimalReproductiveStatusPill extends StatelessWidget {
  const _AnimalReproductiveStatusPill({required this.status});

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

enum _AnimalMobileAction { edit, toggleActive, delete }

class _AnimalMobileActionsMenu extends StatelessWidget {
  const _AnimalMobileActionsMenu({
    required this.animal,
    required this.onEdit,
    required this.onInactivate,
    required this.onActivate,
    required this.onDelete,
  });

  final AnimalSummaryModel animal;
  final VoidCallback onEdit;
  final VoidCallback onInactivate;
  final VoidCallback onActivate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isInactive = animal.status == AnimalStatus.inactive;

    return PopupMenuButton<_AnimalMobileAction>(
      tooltip: 'Ações',
      padding: EdgeInsets.zero,
      onSelected: (action) {
        switch (action) {
          case _AnimalMobileAction.edit:
            onEdit();
            break;
          case _AnimalMobileAction.toggleActive:
            isInactive ? onActivate() : onInactivate();
            break;
          case _AnimalMobileAction.delete:
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _AnimalMobileAction.edit,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit_outlined),
            title: Text('Editar'),
          ),
        ),
        PopupMenuItem(
          value: _AnimalMobileAction.toggleActive,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              isInactive ? Icons.unarchive_outlined : Icons.archive_outlined,
            ),
            title: Text(isInactive ? 'Ativar' : 'Inativar'),
          ),
        ),
        PopupMenuItem(
          value: _AnimalMobileAction.delete,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline, color: colorScheme.error),
            title: Text('Excluir', style: TextStyle(color: colorScheme.error)),
          ),
        ),
      ],
      child: IgnorePointer(
        child: AppButton(
          outlined: true,
          width: 36,
          height: 36,
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          borderColor: colorScheme.outline.withValues(alpha: 0.55),
          shadow: false,
          color: colorScheme.primary,
          textColor: colorScheme.primary,
          onPressed: () {},
          child: const Icon(Icons.more_vert, size: 20),
        ),
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

String _animalCodeLabel(String code) {
  final text = code.trim();
  if (text.isEmpty) return '--';
  if (text.startsWith('#')) return text;
  return '#$text';
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../core/presentation/app_scaffold_messenger.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../properties/domain/property_summary_model.dart';
import '../../application/visits_provider.dart';
import '../../domain/visit_summary_model.dart';

class VisitDetailDialog extends ConsumerWidget {
  const VisitDetailDialog({
    super.key,
    required this.visit,
    required this.propertyName,
    this.property,
  });

  final VisitSummaryModel visit;
  final String propertyName;
  final PropertySummaryModel? property;

  static Future<void> show(
    BuildContext context, {
    required VisitSummaryModel visit,
    required String propertyName,
    PropertySummaryModel? property,
  }) {
    return AppDialog.show<void>(
      context: context,
      title: 'Detalhes da visita',
      width: 760,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      fullscreenBodyPadding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      headerIndent: 16,
      useInternalScroll: true,
      fullscreenOnMobile: true,
      content: VisitDetailDialog(
        visit: visit,
        propertyName: propertyName,
        property: property,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDownloading = ref.watch(visitsReportBusyProvider);
    final canDownloadReport = visit.id > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Section(
            title: 'Dados da visita',
            children: [
              _InfoLine(label: 'Data', value: formatDate(visit.dataVisita)),
              _InfoLine(label: 'Propriedade', value: propertyName),
              _InfoLine(label: 'ID externo', value: visit.idExterno),
              _InfoLine(
                label: 'Animais com coleta',
                value: visit.animais.length.toString(),
              ),
              if (visit.observacoes != null && visit.observacoes!.isNotEmpty)
                _InfoLine(label: 'Observacoes', value: visit.observacoes!),
            ],
          ),
          if (visit.animais.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Section(
              title: 'Coleta por animal',
              children: [
                for (final item in visit.animais)
                  _VisitAnimalItemTile(item: item),
              ],
            ),
          ],
          const SizedBox(height: 16),
          _ReportPreview(
            visit: visit,
            propertyName: propertyName,
            property: property,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            children: [
              AppButton(
                text: 'Compartilhar',
                outlined: true,
                disabled: true,
                height: 40,
                icon: const Icon(Icons.share_outlined, size: 18),
                onPressed: () {},
              ),
              Tooltip(
                message: canDownloadReport
                    ? 'Baixar relatorio em PDF'
                    : 'Relatorio disponivel apos sincronizar a visita',
                child: AppButton(
                  text: 'Baixar PDF',
                  height: 40,
                  loading: isDownloading,
                  disabled: !canDownloadReport,
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  onPressed: canDownloadReport
                      ? () => _downloadReport(context, ref)
                      : null,
                ),
              ),
            ],
          ),
          if (!canDownloadReport) ...[
            const SizedBox(height: 8),
            Text(
              'O PDF sera liberado quando a visita tiver um ID do servidor.',
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _downloadReport(BuildContext context, WidgetRef ref) async {
    try {
      final bytes = await ref
          .read(visitsControllerProvider)
          .downloadReportPdf(visit.id);
      await Printing.layoutPdf(
        name: _reportFileName(),
        onLayout: (_) async => bytes,
      );
    } catch (error) {
      showAppError(error);
    }
  }

  String _reportFileName() {
    final date = visit.dataVisita;
    if (date == null) return 'relatorio-visita-${visit.id}.pdf';
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return 'relatorio-visita-$year$month$day-${visit.id}.pdf';
  }
}

class _VisitAnimalItemTile extends StatelessWidget {
  const _VisitAnimalItemTile({required this.item});

  final VisitAnimalEntryModel item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            item.animalCodigo.isEmpty ? 'Animal sem codigo' : item.animalCodigo,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _ItemFact(label: 'Categoria', value: item.animalCategoria),
              if (item.idadeMeses != null)
                _ItemFact(label: 'Idade', value: '${item.idadeMeses} meses'),
              if (item.situacaoProdutiva?.isNotEmpty == true)
                _ItemFact(label: 'Sit. produtiva', value: item.situacaoProdutiva!),
              if (item.situacaoReprodutiva?.isNotEmpty == true)
                _ItemFact(label: 'Sit. reprodutiva', value: item.situacaoReprodutiva!),
              if (item.decisao?.isNotEmpty == true)
                _ItemFact(label: 'Decisao', value: item.decisao!),
              if (item.diagnostico?.isNotEmpty == true)
                _ItemFact(label: 'Diagnostico', value: item.diagnostico!),
              if (item.dataUltimaIa != null)
                _ItemFact(label: 'Ultima IA', value: formatDate(item.dataUltimaIa)),
              if (item.numeroIaRecebida != null)
                _ItemFact(label: 'Nº IA', value: item.numeroIaRecebida.toString()),
              if (item.diasPrenhez != null)
                _ItemFact(label: 'Dias prenhez', value: item.diasPrenhez.toString()),
              if (item.del != null)
                _ItemFact(label: 'DEL', value: item.del.toString()),
              if (item.diasParaSecar != null)
                _ItemFact(label: 'Dias p/ secar', value: item.diasParaSecar.toString()),
              if (item.previsaoSecagem != null)
                _ItemFact(label: 'Prev. secagem', value: formatDate(item.previsaoSecagem)),
              if (item.dataPreParto != null)
                _ItemFact(label: 'Data pre-parto', value: formatDate(item.dataPreParto)),
              if (item.previsaoParto != null)
                _ItemFact(label: 'Prev. parto', value: formatDate(item.previsaoParto)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemFact extends StatelessWidget {
  const _ItemFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          TextSpan(
            text: value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportPreview extends StatelessWidget {
  const _ReportPreview({
    required this.visit,
    required this.propertyName,
    this.property,
  });

  final VisitSummaryModel visit;
  final String propertyName;
  final PropertySummaryModel? property;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Relatorio Tecnico - Cysvet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          _InfoLine(label: 'Propriedade', value: propertyName),
          if (property != null) ...[
            _InfoLine(label: 'Responsavel', value: property!.nomeProprietario),
            _InfoLine(label: 'Localizacao', value: property!.localizacao),
          ],
          _InfoLine(label: 'Periodo', value: formatDate(visit.dataVisita)),
          const SizedBox(height: 10),
          Text(
            visit.observacoes == null || visit.observacoes!.isEmpty
                ? 'Sem observacoes informadas.'
                : visit.observacoes!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

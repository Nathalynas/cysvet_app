import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/api_config.dart';

/// Versao publicada em `<servidor>/app/versao.json` pelo script
/// `deploy/oracle/publicar-apk.sh`.
class AppRelease {
  const AppRelease({
    required this.versionCode,
    required this.versionName,
    required this.minVersionCode,
    required this.apkUrl,
    this.sha256,
    this.notes,
  });

  final int versionCode;
  final String versionName;

  /// Versoes abaixo desta precisam atualizar para continuar usando o app.
  final int minVersionCode;
  final String apkUrl;
  final String? sha256;
  final String? notes;

  static AppRelease fromJson(Map<String, dynamic> json, Uri manifestUrl) {
    final versionCode = json['versionCode'] as int;
    return AppRelease(
      versionCode: versionCode,
      versionName: json['versionName'] as String,
      minVersionCode: json['minVersionCode'] as int? ?? 0,
      apkUrl: manifestUrl.resolve(json['apk'] as String).toString(),
      sha256: json['sha256'] as String?,
      notes: json['notas'] as String?,
    );
  }
}

Uri get appReleaseManifestUrl =>
    Uri.parse('${ApiConfig.baseUrl}/app/versao.json');

/// Nova versao disponivel para este aparelho, ou null (sem internet,
/// servidor sem versao publicada ou app ja atualizado).
Future<AppRelease?> fetchAvailableUpdate() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;

  try {
    final manifestUrl = appReleaseManifestUrl;
    final response = await Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: {'Cache-Control': 'no-cache'},
      ),
    ).getUri<Map<String, dynamic>>(manifestUrl);
    final release = AppRelease.fromJson(response.data!, manifestUrl);
    final info = await PackageInfo.fromPlatform();
    final installed = int.tryParse(info.buildNumber) ?? 0;
    return release.versionCode > installed ? release : null;
  } catch (error) {
    debugPrint('Verificacao de atualizacao falhou: $error');
    return null;
  }
}

Future<bool> isUpdateRequired(AppRelease release) async {
  final info = await PackageInfo.fromPlatform();
  final installed = int.tryParse(info.buildNumber) ?? 0;
  return installed < release.minVersionCode;
}

/// Envolve o app e mostra o aviso de atualizacao por cima de qualquer tela.
/// Verifica ao abrir e ao voltar para o app.
class AppUpdateGate extends StatefulWidget {
  const AppUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate>
    with WidgetsBindingObserver {
  AppRelease? _release;
  bool _required = false;
  bool _dismissed = false;
  bool _checking = false;
  double? _progress;
  String? _error;
  StreamSubscription<OtaEvent>? _download;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _download?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _download == null) _check();
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    try {
      final release = await fetchAvailableUpdate();
      if (!mounted || release == null) return;
      final required = await isUpdateRequired(release);
      if (!mounted) return;
      setState(() {
        if (release.versionCode != _release?.versionCode) _dismissed = false;
        _release = release;
        _required = required;
      });
    } finally {
      _checking = false;
    }
  }

  void _startDownload() {
    final release = _release!;
    setState(() {
      _progress = 0;
      _error = null;
    });
    _download = OtaUpdate()
        .execute(
          release.apkUrl,
          destinationFilename: 'cysvet-${release.versionCode}.apk',
          sha256checksum: release.sha256,
        )
        .listen(
          (event) {
            if (!mounted) return;
            switch (event.status) {
              case OtaStatus.DOWNLOADING:
                setState(() {
                  _progress = (double.tryParse(event.value ?? '') ?? 0) / 100;
                });
              case OtaStatus.INSTALLING:
              case OtaStatus.INSTALLATION_DONE:
                setState(() {
                  _progress = null;
                  _download = null;
                });
              default:
                setState(() {
                  _progress = null;
                  _download = null;
                  _error =
                      event.status == OtaStatus.PERMISSION_NOT_GRANTED_ERROR
                      ? 'Permita que o CYSVET instale apps e tente de novo.'
                      : 'Não foi possível baixar a atualização. Tente de novo.';
                });
            }
          },
          onError: (Object _) {
            if (!mounted) return;
            setState(() {
              _progress = null;
              _download = null;
              _error = 'Não foi possível baixar a atualização. Tente de novo.';
            });
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final release = _release;
    final visible = release != null && (_required || !_dismissed);

    return Stack(
      children: [
        widget.child,
        if (visible)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black54,
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _UpdateCard(
                      release: release,
                      required: _required,
                      progress: _progress,
                      downloading: _download != null,
                      error: _error,
                      onUpdate: _startDownload,
                      onLater: () => setState(() => _dismissed = true),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({
    required this.release,
    required this.required,
    required this.progress,
    required this.downloading,
    required this.error,
    required this.onUpdate,
    required this.onLater,
  });

  final AppRelease release;
  final bool required;
  final double? progress;
  final bool downloading;
  final String? error;
  final VoidCallback onUpdate;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final notes = release.notes;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.system_update, size: 36, color: colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                'Nova versão disponível',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                required
                    ? 'A versão ${release.versionName} é necessária para '
                          'continuar usando o CYSVET.'
                    : 'A versão ${release.versionName} do CYSVET está pronta '
                          'para instalar.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(notes, style: theme.textTheme.bodyMedium),
              ],
              if (downloading) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 6),
                Text(
                  'Baixando... ${((progress ?? 0) * 100).round()}%',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!required)
                    TextButton(
                      onPressed: downloading ? null : onLater,
                      child: const Text('Agora não'),
                    ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: downloading ? null : onUpdate,
                    icon: const Icon(Icons.download),
                    label: const Text('Atualizar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

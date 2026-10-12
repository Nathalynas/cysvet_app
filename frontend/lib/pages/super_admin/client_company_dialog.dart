import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cysvet_app/core/presentation/app_scaffold_messenger.dart';
import 'package:cysvet_app/core/widgets/app_button.dart';
import 'package:cysvet_app/core/widgets/app_text_field.dart';
import 'package:cysvet_app/providers/super_admin_provider.dart';

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// Resultado do cadastro: se o e-mail com a senha provisória foi enviado.
class NewCompanyResult {
  const NewCompanyResult({
    required this.email,
    required this.emailSent,
    this.reloadFailed = false,
  });

  final String email;
  final bool emailSent;
  final bool reloadFailed;
}

Future<NewCompanyResult?> showClientCompanyDialog(BuildContext context) {
  return showDialog<NewCompanyResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const ClientCompanyDialog(),
  );
}

class ClientCompanyDialog extends ConsumerStatefulWidget {
  const ClientCompanyDialog({super.key});

  @override
  ConsumerState<ClientCompanyDialog> createState() =>
      _ClientCompanyDialogState();
}

class _ClientCompanyDialogState extends ConsumerState<ClientCompanyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _companyController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    final email = _emailController.text.trim();
    try {
      final outcome = await ref
          .read(superAdminCompaniesProvider.notifier)
          .create(
            companyName: _companyController.text,
            responsibleName: _nameController.text,
            responsibleEmail: email,
          );
      if (!mounted) return;
      Navigator.of(context).pop(
        NewCompanyResult(
          email: email,
          emailSent: outcome.emailSent,
          reloadFailed: outcome.reloadFailed,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova empresa'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                AppTextField(
                  label: 'Nome da empresa',
                  controller: _companyController,
                  required: true,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Nome do responsável',
                  controller: _nameController,
                  required: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'E-mail do responsável',
                  controller: _emailController,
                  required: true,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (value) =>
                      _emailPattern.hasMatch(value?.trim() ?? '')
                      ? null
                      : 'Informe um e-mail válido',
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        AppButton(text: 'Cadastrar', loading: _saving, onPressed: _submit),
      ],
    );
  }
}

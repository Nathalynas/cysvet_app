import 'dart:async';

import 'package:cysvet_app/api/super_admin_api.dart';
import 'package:cysvet_app/core/presentation/app_scaffold_messenger.dart';
import 'package:cysvet_app/core/widgets/app_text_field.dart';
import 'package:cysvet_app/models/client_company_model.dart';
import 'package:cysvet_app/pages/super_admin/super_admin_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeSuperAdminRepository implements SuperAdminRepository {
  _FakeSuperAdminRepository(this.companies, {this.emailSent = true});

  final List<ClientCompanyModel> companies;
  final bool emailSent;
  final setActiveCalls = <(int, bool)>[];
  int createCalls = 0;
  int resendCalls = 0;
  int listCalls = 0;
  bool listThrows = false;
  bool setActiveThrows = false;
  Completer<bool>? resendGate;

  @override
  Future<List<ClientCompanyModel>> list() async {
    listCalls++;
    if (listThrows) throw Exception('falha ao listar');
    return [...companies];
  }

  @override
  Future<({ClientCompanyModel company, bool emailSent})> create({
    required String companyName,
    required String responsibleName,
    required String responsibleEmail,
  }) async {
    createCalls++;
    final created = ClientCompanyModel(
      id: 100 + createCalls,
      name: companyName,
      responsibleName: responsibleName,
      responsibleEmail: responsibleEmail,
      status: ClientCompanyStatus.aguardandoPrimeiroAcesso,
    );
    companies.add(created);
    return (company: created, emailSent: emailSent);
  }

  @override
  Future<ClientCompanyModel> setActive(int id, bool active) async {
    setActiveCalls.add((id, active));
    if (setActiveThrows) throw Exception('falha ao alterar');
    return companies.first;
  }

  @override
  Future<bool> resendAccess(int id) {
    resendCalls++;
    return resendGate?.future ?? Future.value(true);
  }
}

const _boaVista = ClientCompanyModel(
  id: 1,
  name: 'Clínica Boa Vista',
  responsibleName: 'Ana Souza',
  responsibleEmail: 'ana@boavista.com',
  status: ClientCompanyStatus.ativa,
);
const _agroVet = ClientCompanyModel(
  id: 2,
  name: 'Agro Vet Sul',
  responsibleName: 'Carlos Lima',
  responsibleEmail: 'carlos@agrovet.com',
  status: ClientCompanyStatus.aguardandoPrimeiroAcesso,
);
const _esperanca = ClientCompanyModel(
  id: 3,
  name: 'Fazenda Esperança',
  responsibleName: 'João Alves',
  responsibleEmail: 'joao@esperanca.com',
  status: ClientCompanyStatus.desativada,
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpPage(
    WidgetTester tester,
    _FakeSuperAdminRepository repository,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [superAdminRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          scaffoldMessengerKey: appScaffoldMessengerKey,
          home: const SuperAdminPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('showsCompaniesWithStatusBadges', (tester) async {
    await pumpPage(
      tester,
      _FakeSuperAdminRepository([_boaVista, _agroVet, _esperanca]),
    );

    expect(find.text('Ativa'), findsOneWidget);
    expect(find.text('Aguardando 1º acesso'), findsOneWidget);
    expect(find.text('Desativada'), findsOneWidget);
    expect(find.text('Reativar'), findsOneWidget);
    expect(find.text('Desativar'), findsNWidgets(2));
    expect(find.text('Reenviar senha'), findsNWidgets(2));
  });

  testWidgets('deactivatedRowHasNoResendButton', (tester) async {
    await pumpPage(tester, _FakeSuperAdminRepository([_esperanca]));

    expect(find.text('Reativar'), findsOneWidget);
    expect(find.text('Reenviar senha'), findsNothing);
  });

  testWidgets('resendReloadsList', (tester) async {
    final repository = _FakeSuperAdminRepository([_boaVista]);
    await pumpPage(tester, repository);
    final listsBefore = repository.listCalls;

    await tester.tap(find.text('Reenviar senha'));
    await tester.pumpAndSettle();

    expect(repository.listCalls, listsBefore + 1);
  });

  testWidgets('searchFiltersByCompanyOrEmail', (tester) async {
    await pumpPage(
      tester,
      _FakeSuperAdminRepository([_boaVista, _agroVet, _esperanca]),
    );

    await tester.enterText(find.byType(TextField), 'boa');
    await tester.pumpAndSettle();
    expect(find.text('Clínica Boa Vista'), findsOneWidget);
    expect(find.text('Agro Vet Sul'), findsNothing);
    expect(find.text('Fazenda Esperança'), findsNothing);

    await tester.enterText(find.byType(TextField), 'AGROVET');
    await tester.pumpAndSettle();
    expect(find.text('Agro Vet Sul'), findsOneWidget);
    expect(find.text('Clínica Boa Vista'), findsNothing);
    expect(find.text('carlos@agrovet.com'), findsOneWidget);
  });

  testWidgets('deactivateAsksConfirmationBeforeCalling', (tester) async {
    final repository = _FakeSuperAdminRepository([_boaVista]);
    await pumpPage(tester, repository);

    await tester.tap(find.text('Desativar'));
    await tester.pumpAndSettle();

    expect(find.text('Desativar Clínica Boa Vista?'), findsOneWidget);
    expect(
      find.text(
        'Os usuários dessa empresa perdem o acesso na hora. '
        'Os dados não são apagados.',
      ),
      findsOneWidget,
    );
    expect(repository.setActiveCalls, isEmpty);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Desativar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.setActiveCalls, [(1, false)]);
  });

  testWidgets('createShowsWarningWhenEmailNotSent', (tester) async {
    final repository = _FakeSuperAdminRepository([_boaVista], emailSent: false);
    await pumpPage(tester, repository);

    await tester.tap(find.text('+ Nova empresa'));
    await tester.pumpAndSettle();

    final fields = find.byType(AppTextField);
    await tester.enterText(fields.at(0), 'Nova Vet');
    await tester.enterText(fields.at(1), 'Maria');
    await tester.enterText(fields.at(2), 'maria@novavet.com');
    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1);
    expect(
      find.text(
        'Empresa criada, mas o e-mail não foi enviado. Use Reenviar senha.',
      ),
      findsOneWidget,
    );
  });

  Future<void> fillAndSubmitNewCompany(WidgetTester tester) async {
    await tester.tap(find.text('+ Nova empresa'));
    await tester.pumpAndSettle();
    final fields = find.byType(AppTextField);
    await tester.enterText(fields.at(0), 'Nova Vet');
    await tester.enterText(fields.at(1), 'Maria');
    await tester.enterText(fields.at(2), 'maria@novavet.com');
    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();
  }

  testWidgets('resendTwiceQuicklyCallsRepositoryOnce', (tester) async {
    final repository = _FakeSuperAdminRepository([_boaVista])
      ..resendGate = Completer<bool>();
    await pumpPage(tester, repository);

    await tester.tap(find.text('Reenviar senha'));
    await tester.pump();
    await tester.tap(find.text('Reenviar senha'), warnIfMissed: false);
    await tester.pump();
    expect(repository.resendCalls, 1);

    repository.resendGate!.complete(true);
    await tester.pumpAndSettle();
    expect(
      find.text('Nova senha provisória enviada para ana@boavista.com.'),
      findsOneWidget,
    );
  });

  testWidgets('setActiveErrorShowsMessageAndKeepsList', (tester) async {
    final repository = _FakeSuperAdminRepository([_boaVista, _esperanca])
      ..setActiveThrows = true;
    await pumpPage(tester, repository);

    await tester.tap(find.text('Reativar'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Clínica Boa Vista'), findsOneWidget);
    expect(find.text('Fazenda Esperança'), findsOneWidget);
    expect(find.text('Não foi possível carregar as empresas.'), findsNothing);
  });

  testWidgets('reloadFailureAfterCreateKeepsList', (tester) async {
    final repository = _FakeSuperAdminRepository([_boaVista]);
    await pumpPage(tester, repository);
    repository.listThrows = true;

    await fillAndSubmitNewCompany(tester);

    expect(repository.createCalls, 1);
    expect(find.text('Clínica Boa Vista'), findsOneWidget);
    expect(find.text('Não foi possível carregar as empresas.'), findsNothing);
    expect(find.textContaining('Empresa criada'), findsOneWidget);
  });

  testWidgets('createdCompanyAppearsInList', (tester) async {
    final repository = _FakeSuperAdminRepository([_boaVista]);
    await pumpPage(tester, repository);

    await fillAndSubmitNewCompany(tester);

    expect(find.text('Nova Vet'), findsOneWidget);
    expect(find.text('Clínica Boa Vista'), findsOneWidget);
  });
}

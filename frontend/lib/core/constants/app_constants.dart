// ignore: constant_identifier_names
const double MOBILE_WIDTH = 1000;

class AppAssets {
  const AppAssets._();

  static const companyLogo = 'assets/images/logo.png';
}

extension StringNormalizeExtension on String {
  String normalize() {
    return toLowerCase()
        .replaceAll(RegExp('[áàâãä]'), 'a')
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[íìîï]'), 'i')
        .replaceAll(RegExp('[óòôõö]'), 'o')
        .replaceAll(RegExp('[úùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll('ñ', 'n');
  }
}

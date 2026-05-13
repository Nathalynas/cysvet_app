import 'package:cysvet_app/core/widgets/app_dropdown.dart';
import 'package:cysvet_app/features/properties/domain/property_summary_model.dart';
import 'package:flutter/material.dart';

class PropertyFilterCard extends StatelessWidget {
  const PropertyFilterCard({
    super.key,
    required this.properties,
    required this.selectedPropertyId,
    required this.onChanged,
    this.labelText = 'Filtrar por propriedade',
    this.allPropertiesText = 'Todas as propriedades',
  });

  final List<PropertySummaryModel> properties;
  final int? selectedPropertyId;
  final ValueChanged<int?> onChanged;
  final String labelText;
  final String allPropertiesText;

  @override
  Widget build(BuildContext context) {
    return AppDropdown<int>(
      value: selectedPropertyId,
      labelText: labelText,
      nullLabel: allPropertiesText,
      searchable: true,
      onChanged: onChanged,
      options: [
        AppDropdownOption<int>(label: allPropertiesText, value: null),
        ...properties.map(
          (property) => AppDropdownOption<int>(
            label: property.nome,
            value: property.id,
          ),
        ),
      ],
    );
  }
}

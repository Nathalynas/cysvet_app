package com.cysvet.backend.dto.animal;

import java.util.List;
import java.util.Map;

public record AnimalSpreadsheetPreviewResponse(
        String sheetName,
        int headerRowIndex,
        List<String> columns,
        List<AnimalSpreadsheetRowResponse> rows,
        Map<Integer, String> mappings,
        List<String> missingRequiredFields,
        int validRows,
        int pendingRows,
        int invalidRows,
        int totalRows
) {}

package com.cysvet.backend.dto.animal;

import java.util.List;

public record AnimalSpreadsheetRowResponse(
        int excelRowNumber,
        List<AnimalSpreadsheetCellResponse> cells,
        String status,
        List<AnimalSpreadsheetIssueResponse> issues
) {}

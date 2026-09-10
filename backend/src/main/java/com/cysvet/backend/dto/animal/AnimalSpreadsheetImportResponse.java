package com.cysvet.backend.dto.animal;

public record AnimalSpreadsheetImportResponse(int importedRows, int invalidRows, int pendingRows) {}

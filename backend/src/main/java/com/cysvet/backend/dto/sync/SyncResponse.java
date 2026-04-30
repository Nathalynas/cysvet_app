package com.cysvet.backend.dto.sync;

import java.util.List;

public record SyncResponse(List<SyncItemResponse> items) {
}

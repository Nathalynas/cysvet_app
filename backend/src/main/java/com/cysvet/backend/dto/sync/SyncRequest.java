package com.cysvet.backend.dto.sync;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import java.util.List;

public record SyncRequest(@Valid @NotEmpty List<SyncItemRequest> items) {
}

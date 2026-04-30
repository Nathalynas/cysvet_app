package com.cysvet.backend.dto.sync;

public record SyncItemResponse(
        String chaveMutacao,
        String status,
        Long idEntidade,
        String idExterno,
        String message
) {
}

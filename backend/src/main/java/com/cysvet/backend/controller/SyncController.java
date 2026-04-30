package com.cysvet.backend.controller;

import com.cysvet.backend.dto.sync.PullSyncResponse;
import com.cysvet.backend.dto.sync.SyncRequest;
import com.cysvet.backend.dto.sync.SyncResponse;
import com.cysvet.backend.service.SyncService;
import java.time.Instant;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/sync")
@RequiredArgsConstructor
public class SyncController {

    private final SyncService syncService;

    @PostMapping
    public SyncResponse sync(@Valid @RequestBody SyncRequest request) {
        return syncService.sync(request);
    }

    @GetMapping("/pull")
    public PullSyncResponse pull(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant since
    ) {
        return syncService.pull(since);
    }
}

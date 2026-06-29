package com.hyperlocal.branchmanager.infrastructure.adapter.inbound;

import com.hyperlocal.branchmanager.application.service.BranchManagerService;
import com.hyperlocal.branchmanager.infrastructure.dto.*;
import com.hyperlocal.core.domain.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/branch-manager")
@RequiredArgsConstructor
public class BranchManagerController {
    private final BranchManagerService branchManagerService;

    @GetMapping("/{branchId}/dashboard")
    public ResponseEntity<ApiResponse<BranchDashboardDto>> getDashboard(
            @PathVariable("branchId") String branchId,
            @RequestHeader("X-User-Role") String userRole) {
        BranchDashboardDto response = branchManagerService.getDashboardMetrics(UUID.fromString(branchId));
        return ResponseEntity.ok(ApiResponse.ok(response, UUID.randomUUID().toString()));
    }

    @PostMapping("/config")
    public ResponseEntity<ApiResponse<String>> saveConfig(
            @RequestHeader("X-User-Role") String userRole,
            @RequestBody BranchConfigurationDto request) {
        branchManagerService.updateBranchConfig(request);
        return ResponseEntity.ok(ApiResponse.ok("Branch configuration updated", UUID.randomUUID().toString()));
    }
}

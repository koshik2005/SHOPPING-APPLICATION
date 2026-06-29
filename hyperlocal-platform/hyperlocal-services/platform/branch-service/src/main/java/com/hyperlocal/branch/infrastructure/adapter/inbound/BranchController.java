package com.hyperlocal.branch.infrastructure.adapter.inbound;

import com.hyperlocal.branch.application.service.BranchService;
import com.hyperlocal.branch.infrastructure.entity.BranchEntity;
import com.hyperlocal.core.domain.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/branches")
@RequiredArgsConstructor
public class BranchController {
    private final BranchService branchService;

    @GetMapping("/active")
    public ResponseEntity<ApiResponse<List<BranchEntity>>> getActiveBranches() {
        List<BranchEntity> response = branchService.getActiveBranches();
        return ResponseEntity.ok(ApiResponse.ok(response, UUID.randomUUID().toString()));
    }
}

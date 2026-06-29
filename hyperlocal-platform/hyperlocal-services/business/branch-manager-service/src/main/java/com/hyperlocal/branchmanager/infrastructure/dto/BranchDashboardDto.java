package com.hyperlocal.branchmanager.infrastructure.dto;

import lombok.Builder;
import lombok.Data;
import java.util.UUID;

@Data
@Builder
public class BranchDashboardDto {
    private UUID branchId;
    private long activeOrdersCount;
    private long pendingOrdersCount;
    private double totalSalesToday;
    private long activeShopsCount;
    private long onlinePartnersCount;
}

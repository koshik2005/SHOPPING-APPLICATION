package com.hyperlocal.customer.infrastructure.dto;

import lombok.Builder;
import lombok.Data;
import java.util.List;
import java.util.Map;

@Data
@Builder
public class HomeBootstrapResponse {
    private CustomerProfileDto profile;
    private String assignedBranchId;
    private Map<String, Object> homeLayout;
    private Map<String, Boolean> featureFlags;
    private double walletBalance;
    private int unreadNotifications;
    private List<Map<String, Object>> activeOrders;
}

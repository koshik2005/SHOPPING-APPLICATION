package com.hyperlocal.customer.application.service;

import com.hyperlocal.customer.infrastructure.entity.CustomerEntity;
import com.hyperlocal.customer.infrastructure.repository.CustomerRepository;
import com.hyperlocal.customer.infrastructure.dto.*;
import com.hyperlocal.common.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CustomerService {
    private final CustomerRepository customerRepository;

    @Transactional(readOnly = true)
    public CustomerProfileDto getProfileByUserId(UUID userId) {
        CustomerEntity customer = customerRepository.findByUserIdAndDeletedFalse(userId)
            .orElseThrow(() -> new ResourceNotFoundException("Customer profile not found for user ID: " + userId, "CUSTOMER_NOT_FOUND"));
            
        return CustomerProfileDto.builder()
            .id(customer.getId())
            .userId(customer.getUserId())
            .displayName(customer.getDisplayName())
            .profilePhotoUrl(customer.getProfilePhotoUrl())
            .rating(customer.getRating())
            .build();
    }

    @Transactional(readOnly = true)
    public HomeBootstrapResponse bootstrapHomeScreen(UUID userId) {
        CustomerProfileDto profile = getProfileByUserId(userId);
        
        // Dynamic properties configuration structures loaded statelessly
        Map<String, Boolean> flags = new HashMap<>();
        flags.put("food-delivery", true);
        flags.put("grocery-delivery", true);
        flags.put("ride-booking", false);

        Map<String, Object> layout = new HashMap<>();
        layout.put("theme", "warm-orange");
        layout.put("sections", Collections.emptyList());

        return HomeBootstrapResponse.builder()
            .profile(profile)
            .assignedBranchId("branch-a")
            .homeLayout(layout)
            .featureFlags(flags)
            .walletBalance(50.00)
            .unreadNotifications(3)
            .activeOrders(Collections.emptyList())
            .build();
    }
}

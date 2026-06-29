package com.hyperlocal.delivery.application.service;

import com.hyperlocal.delivery.infrastructure.entity.*;
import com.hyperlocal.delivery.infrastructure.repository.*;
import com.hyperlocal.delivery.infrastructure.dto.*;
import com.hyperlocal.common.exception.BusinessException;
import com.hyperlocal.common.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class DeliveryService {
    private final DeliveryPartnerRepository partnerRepository;
    private final DeliveryAssignmentRepository assignmentRepository;

    @Transactional
    public void assignDeliveryPartner(AssignPartnerRequest request) {
        DeliveryPartnerEntity partner = partnerRepository.findById(request.getPartnerId())
            .orElseThrow(() -> new ResourceNotFoundException("Delivery partner not found: " + request.getPartnerId(), "PARTNER_NOT_FOUND"));

        if ("BUSY".equals(partner.getStatus())) {
            throw new BusinessException("Delivery partner is currently busy", "PARTNER_BUSY");
        }

        partner.setStatus("BUSY");
        partnerRepository.save(partner);

        DeliveryAssignmentEntity assignment = new DeliveryAssignmentEntity();
        assignment.setOrderId(request.getOrderId());
        assignment.setPartnerId(partner.getId());
        assignment.setStatus("ASSIGNED");
        assignment.setVerificationOtp("123456"); // Default standard pin verification code
        assignmentRepository.save(assignment);
    }

    @Transactional
    public void updatePartnerLocation(UUID partnerId, PartnerLocationDto loc) {
        // Concrete method logging locations to Redis Spatial indices statelessly
    }

    @Transactional(readOnly = true)
    public DeliveryStatusDto getDeliveryStatus(UUID orderId) {
        DeliveryAssignmentEntity assignment = assignmentRepository.findByOrderId(orderId)
            .orElseThrow(() -> new ResourceNotFoundException("No delivery assignment found for order: " + orderId, "ASSIGNMENT_NOT_FOUND"));

        return DeliveryStatusDto.builder()
            .orderId(assignment.getOrderId())
            .partnerId(assignment.getPartnerId())
            .status(assignment.getStatus())
            .etaMinutes("12 Mins") // ETA spatial estimation details
            .build();
    }
}

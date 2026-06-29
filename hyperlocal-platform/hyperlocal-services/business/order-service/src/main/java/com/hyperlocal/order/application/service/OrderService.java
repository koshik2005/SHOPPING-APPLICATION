package com.hyperlocal.order.application.service;

import com.hyperlocal.order.infrastructure.entity.*;
import com.hyperlocal.order.infrastructure.repository.*;
import com.hyperlocal.order.infrastructure.dto.*;
import com.hyperlocal.common.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class OrderService {
    private final OrderRepository orderRepository;
    private final OrderItemRepository itemRepository;
    private final OrderStatusHistoryRepository historyRepository;

    @Transactional
    public OrderDto createOrder(UUID customerId, CreateOrderRequest request) {
        OrderEntity order = new OrderEntity();
        order.setCustomerId(customerId);
        order.setBranchId(request.getBranchId());
        order.setStatus("PENDING");
        
        double total = request.getItems().stream()
            .mapToDouble(i -> i.getPrice() * i.getQuantity())
            .sum();
        order.setTotalPrice(total);

        OrderEntity saved = orderRepository.save(order);

        // Write order items snapshots
        for (CreateOrderRequest.OrderItemInput itemInput : request.getItems()) {
            OrderItemEntity item = new OrderItemEntity();
            item.setOrderId(saved.getId());
            item.setProductVariantId(itemInput.getProductVariantId());
            item.setQuantity(itemInput.getQuantity());
            item.setUnitPrice(itemInput.getPrice());
            itemRepository.save(item);
        }

        // Record initialization history
        recordHistory(saved.getId(), "PENDING", customerId, "Order placed successfully");

        return OrderDto.builder()
            .id(saved.getId())
            .customerId(saved.getCustomerId())
            .branchId(saved.getBranchId())
            .status(saved.getStatus())
            .totalPrice(saved.getTotalPrice())
            .build();
    }

    @Transactional
    public void updateOrderStatus(UUID orderId, String status, UUID actorId, String remarks) {
        OrderEntity order = orderRepository.findById(orderId)
            .orElseThrow(() -> new ResourceNotFoundException("Order not found: " + orderId, "ORDER_NOT_FOUND"));
            
        order.setStatus(status);
        orderRepository.save(order);

        recordHistory(orderId, status, actorId, remarks);
    }

    @Transactional(readOnly = true)
    public OrderTimelineDto getTimeline(UUID orderId) {
        List<OrderTimelineDto.TimelineEvent> events = historyRepository.findByOrderIdOrderByCreatedAtAsc(orderId).stream()
            .map(h -> OrderTimelineDto.TimelineEvent.builder()
                .status(h.getStatus())
                .remarks(h.getRemarks())
                .timestamp(h.getCreatedAt())
                .build())
            .collect(Collectors.toList());

        return OrderTimelineDto.builder().history(events).build();
    }

    private void recordHistory(UUID orderId, String status, UUID actorId, String remarks) {
        OrderStatusHistoryEntity history = new OrderStatusHistoryEntity();
        history.setOrderId(orderId);
        history.setStatus(status);
        history.setChangedBy(actorId);
        history.setRemarks(remarks);
        historyRepository.save(history);
    }
}

package com.hyperlocal.order.infrastructure.dto;

import java.util.UUID;

public class OrderDto {
    private UUID id;
    private UUID customerId;
    private UUID branchId;
    private String serviceKey;
    private String status;
    private double totalPrice;

    public OrderDto() {}

    public OrderDto(UUID id, UUID customerId, UUID branchId, String serviceKey, String status, double totalPrice) {
        this.id = id;
        this.customerId = customerId;
        this.branchId = branchId;
        this.serviceKey = serviceKey;
        this.status = status;
        this.totalPrice = totalPrice;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getCustomerId() { return customerId; }
    public void setCustomerId(UUID customerId) { this.customerId = customerId; }

    public UUID getBranchId() { return branchId; }
    public void setBranchId(UUID branchId) { this.branchId = branchId; }

    public String getServiceKey() { return serviceKey; }
    public void setServiceKey(String serviceKey) { this.serviceKey = serviceKey; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public double getTotalPrice() { return totalPrice; }
    public void setTotalPrice(double totalPrice) { this.totalPrice = totalPrice; }

    public static OrderDtoBuilder builder() {
        return new OrderDtoBuilder();
    }

    public static class OrderDtoBuilder {
        private UUID id;
        private UUID customerId;
        private UUID branchId;
        private String serviceKey;
        private String status;
        private double totalPrice;

        OrderDtoBuilder() {}

        public OrderDtoBuilder id(UUID id) {
            this.id = id;
            return this;
        }

        public OrderDtoBuilder customerId(UUID customerId) {
            this.customerId = customerId;
            return this;
        }

        public OrderDtoBuilder branchId(UUID branchId) {
            this.branchId = branchId;
            return this;
        }

        public OrderDtoBuilder serviceKey(String serviceKey) {
            this.serviceKey = serviceKey;
            return this;
        }

        public OrderDtoBuilder status(String status) {
            this.status = status;
            return this;
        }

        public OrderDtoBuilder totalPrice(double totalPrice) {
            this.totalPrice = totalPrice;
            return this;
        }

        public OrderDto build() {
            return new OrderDto(id, customerId, branchId, serviceKey, status, totalPrice);
        }
    }
}

package com.hyperlocal.cart.infrastructure.dto;

import lombok.Builder;
import lombok.Data;
import java.util.List;

@Data
@Builder
public class CartSummaryDto {
    private List<CartItemDto> items;
    private double subtotal;
    private double packagingCharge;
    private double deliveryFee;
    private double tax;
    private double discount;
    private double grandTotal;
}

package com.hyperlocal.cart.application.service;

import com.hyperlocal.cart.infrastructure.entity.*;
import com.hyperlocal.cart.infrastructure.repository.*;
import com.hyperlocal.cart.infrastructure.dto.*;
import com.hyperlocal.common.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;


import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CartService {

    private final CartRepository cartRepository;
    private final CartItemRepository itemRepository;
    private final ProductVariantPriceRepository variantPriceRepository;

    @Value("${cart.tax.rate:0.05}")
    private double taxRate;

    @Value("${cart.delivery.free-threshold:30.00}")
    private double freeDeliveryThreshold;

    @Value("${cart.delivery.fee:5.00}")
    private double deliveryFee;

    @Value("${cart.packaging.charge:2.00}")
    private double packagingCharge;

    @Transactional
    public CartSummaryDto getCartSummary(UUID customerId) {
        CartEntity cart = cartRepository.findByCustomerId(customerId)
            .orElseGet(() -> {
                CartEntity newCart = new CartEntity();
                newCart.setCustomerId(customerId);
                return cartRepository.save(newCart);
            });

        List<CartItemDto> items = itemRepository.findByCartId(cart.getId()).stream()
            .map(item -> {
                UUID variantId = item.getProductVariantId();
                double unitPrice = 0.0;
                if (variantId != null) {
                    unitPrice = variantPriceRepository.findById(variantId)
                        .filter(v -> !v.isDeleted())
                        .map(v -> v.getPrice())
                        .orElse(0.0);

                }

                return CartItemDto.builder()
                    .id(item.getId())
                    .productVariantId(variantId)
                    .quantity(item.getQuantity())
                    .unitPrice(unitPrice)
                    .build();
            })
            .collect(Collectors.toList());


        double subtotal = items.stream()
            .mapToDouble(i -> i.getUnitPrice() * i.getQuantity())
            .sum();

        double appliedDeliveryFee = subtotal > freeDeliveryThreshold ? 0.00 : deliveryFee;
        double tax = subtotal * taxRate;
        double grandTotal = subtotal + appliedDeliveryFee + packagingCharge + tax;

        return CartSummaryDto.builder()
            .items(items)
            .subtotal(subtotal)
            .packagingCharge(packagingCharge)
            .deliveryFee(appliedDeliveryFee)
            .tax(tax)
            .discount(0.00)
            .grandTotal(grandTotal)
            .build();
    }

    @Transactional
    public void addItemToCart(UUID customerId, UUID variantId, int qty) {
        if (variantId == null) {
            throw new IllegalArgumentException("Variant ID cannot be null");
        }
        // Validate variant exists and is active before adding
        variantPriceRepository.findById(variantId)
            .filter(v -> !v.isDeleted())
            .orElseThrow(() -> new ResourceNotFoundException(
                "Product variant not found or unavailable: " + variantId, "VARIANT_NOT_FOUND"));


        CartEntity cart = cartRepository.findByCustomerId(customerId)
            .orElseGet(() -> {
                CartEntity newCart = new CartEntity();
                newCart.setCustomerId(customerId);
                return cartRepository.save(newCart);
            });

        CartItemEntity item = new CartItemEntity();
        item.setCartId(cart.getId());
        item.setProductVariantId(variantId);
        item.setQuantity(qty);
        itemRepository.save(item);
    }

    @Transactional
    public void clearCart(UUID customerId) {
        cartRepository.findByCustomerId(customerId)
            .ifPresent(cart -> itemRepository.deleteByCartId(cart.getId()));
    }
}

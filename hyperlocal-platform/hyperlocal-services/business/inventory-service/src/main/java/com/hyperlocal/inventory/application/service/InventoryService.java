package com.hyperlocal.inventory.application.service;

import com.hyperlocal.inventory.infrastructure.entity.*;
import com.hyperlocal.inventory.infrastructure.repository.*;
import com.hyperlocal.inventory.infrastructure.dto.*;
import com.hyperlocal.common.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class InventoryService {
    private final CategoryRepository categoryRepository;
    private final ProductRepository productRepository;
    private final ProductVariantRepository variantRepository;
    private final InventoryRepository inventoryRepository;

    @Transactional(readOnly = true)
    public List<CategoryDto> getCategories() {
        return categoryRepository.findByDeletedFalse().stream()
            .map(cat -> CategoryDto.builder()
                .id(cat.getId())
                .name(cat.getName())
                .iconUrl(cat.getIconUrl())
                .build())
            .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<ProductDto> getProductsByShop(UUID shopId) {
        return productRepository.findByShopIdAndDeletedFalse(shopId).stream()
            .map(prod -> ProductDto.builder()
                .id(prod.getId())
                .shopId(prod.getShopId())
                .categoryId(prod.getCategoryId())
                .name(prod.getName())
                .description(prod.getDescription())
                .build())
            .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public int getAvailableStock(UUID variantId) {
        return inventoryRepository.findByProductVariantId(variantId)
            .map(InventoryEntity::getAvailableQty)
            .orElse(0);
    }
}

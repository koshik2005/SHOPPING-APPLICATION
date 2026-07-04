package com.hyperlocal.inventory.application.service;

import com.hyperlocal.inventory.infrastructure.entity.*;
import com.hyperlocal.inventory.infrastructure.repository.*;
import com.hyperlocal.inventory.infrastructure.dto.*;
import com.hyperlocal.common.exception.ResourceNotFoundException;
import com.hyperlocal.common.context.AuthContext;
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
        AuthContext.AuthContextData ctx = AuthContext.get();
        if (ctx != null) {
            boolean isShopOwnerOrMgr = ctx.hasRole("ROLE_SHOP_OWNER") || ctx.hasRole("ROLE_SHOP_MANAGER");
            if (isShopOwnerOrMgr && !shopId.equals(ctx.shopId()) && !ctx.isSuperAdmin()) {
                throw new RuntimeException("FORBIDDEN: Access denied to other shop's products");
            }
        }

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

    @Transactional
    public CategoryDto createCategory(CategoryDto request) {
        AuthContext.AuthContextData ctx = AuthContext.get();
        if (ctx == null || (!ctx.isSuperAdmin() && !ctx.hasRole("ROLE_SYSTEM_ADMIN"))) {
            throw new RuntimeException("FORBIDDEN: Only administrators can create categories");
        }

        CategoryEntity entity = new CategoryEntity();
        entity.setName(request.getName());
        entity.setIconUrl(request.getIconUrl());
        CategoryEntity saved = categoryRepository.save(entity);
        return CategoryDto.builder()
            .id(saved.getId())
            .name(saved.getName())
            .iconUrl(saved.getIconUrl())
            .build();
    }

    @Transactional
    public ProductDto createProduct(ProductDto request) {
        AuthContext.AuthContextData ctx = AuthContext.get();
        if (ctx == null) {
            throw new RuntimeException("UNAUTHORIZED: Authentication context is missing");
        }

        boolean isAdmin = ctx.isSuperAdmin() || ctx.hasRole("ROLE_SYSTEM_ADMIN");
        boolean isShopOwnerOrMgr = ctx.hasRole("ROLE_SHOP_OWNER") || ctx.hasRole("ROLE_SHOP_MANAGER");
        boolean isBranchMgr = ctx.hasRole("ROLE_BRANCH_MANAGER");

        if (!isAdmin && !isShopOwnerOrMgr && !isBranchMgr) {
            throw new RuntimeException("FORBIDDEN: You do not have permission to create products");
        }

        if (isShopOwnerOrMgr && !request.getShopId().equals(ctx.shopId())) {
            throw new RuntimeException("FORBIDDEN: Cannot create products for another shop");
        }

        ProductEntity entity = new ProductEntity();
        entity.setShopId(request.getShopId());
        entity.setCategoryId(request.getCategoryId());
        entity.setName(request.getName());
        entity.setDescription(request.getDescription());
        ProductEntity saved = productRepository.save(entity);
        return ProductDto.builder()
            .id(saved.getId())
            .shopId(saved.getShopId())
            .categoryId(saved.getCategoryId())
            .name(saved.getName())
            .description(saved.getDescription())
            .build();
    }
}

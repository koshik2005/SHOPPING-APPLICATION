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
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * InventoryService — Zero Hardcoding Refactor
 *
 * REMOVED: All hardcoded role strings (ROLE_SHOP_OWNER, ROLE_SHOP_MANAGER, etc.)
 * REPLACED WITH: Permission-based checks via AuthContext.hasPermission()
 *
 * No role name ever appears in business logic. All access control is resolved
 * through the dynamic RBAC engine (RbacService → permission_definitions → DB).
 */
@Service
@RequiredArgsConstructor
public class InventoryService {

    private final CategoryRepository categoryRepository;
    private final ProductRepository productRepository;
    private final ProductVariantRepository variantRepository;
    private final InventoryRepository inventoryRepository;
    private final ProductAttributeSchemaRepository attributeSchemaRepository;
    private final ProductAttributeValueRepository attributeValueRepository;
    private final RolePermissionMappingRepository rolePermissionMappingRepository;

    private boolean checkPermission(AuthContext.AuthContextData ctx, String permission) {
        if (ctx == null) return false;
        if (ctx.isSuperAdmin()) return true;
        return rolePermissionMappingRepository.hasPermission(ctx.roles(), permission);
    }

    // ======================================================================
    // CATEGORIES
    // ======================================================================

    @Transactional(readOnly = true)
    public List<CategoryDto> getCategories() {
        return categoryRepository.findByDeletedFalse().stream()
            .map(this::toCategoryDto)
            .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<CategoryDto> getCategoriesByService(String serviceKey) {
        return categoryRepository.findByServiceKeyAndDeletedFalseOrderByDisplayOrderAsc(serviceKey).stream()
            .map(this::toCategoryDto)
            .collect(Collectors.toList());
    }

    @Transactional
    public CategoryDto createCategory(CategoryDto request) {
        // PERMISSION CHECK — no role name hardcoded
        AuthContext.AuthContextData ctx = AuthContext.get();
        if (!checkPermission(ctx, "categories:write")) {
            throw new RuntimeException("FORBIDDEN: You do not have permission to create categories");
        }
        CategoryEntity entity = new CategoryEntity();
        entity.setName(request.getName());
        entity.setIconUrl(request.getIconUrl());
        entity.setServiceKey(request.getServiceKey());
        entity.setParentCategoryId(request.getParentCategoryId());
        CategoryEntity saved = categoryRepository.save(entity);
        return toCategoryDto(saved);
    }

    // ======================================================================
    // PRODUCTS
    // ======================================================================

    @Transactional(readOnly = true)
    public List<ProductDto> getProductsByShop(UUID shopId) {
        // PERMISSION CHECK — no role name hardcoded
        AuthContext.AuthContextData ctx = AuthContext.get();
        if (ctx != null && !checkPermission(ctx, "products:view")) {
            throw new RuntimeException("FORBIDDEN: Access denied to products");
        }

        return productRepository.findByShopIdAndDeletedFalse(shopId).stream()
            .map(this::toProductDto)
            .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<ProductDto> getProductsByShopAndService(UUID shopId, String serviceKey) {
        return productRepository.findByShopIdAndServiceKeyAndDeletedFalse(shopId, serviceKey).stream()
            .map(this::toProductDto)
            .collect(Collectors.toList());
    }

    @Transactional
    public ProductDto createProduct(ProductDto request) {
        // PERMISSION CHECK — no role name hardcoded
        AuthContext.AuthContextData ctx = AuthContext.get();
        if (ctx == null) {
            throw new RuntimeException("UNAUTHORIZED: Authentication context is missing");
        }
        if (!checkPermission(ctx, "products:write")) {
            throw new RuntimeException("FORBIDDEN: You do not have permission to create products");
        }

        ProductEntity entity = new ProductEntity();
        entity.setShopId(request.getShopId());
        entity.setCategoryId(request.getCategoryId());
        entity.setServiceKey(request.getServiceKey());
        entity.setName(request.getName());
        entity.setDescription(request.getDescription());
        ProductEntity saved = productRepository.save(entity);

        // Persist dynamic attribute values if provided
        if (request.getAttributes() != null && !request.getAttributes().isEmpty()) {
            saveAttributeValues(saved.getId(), request.getAttributes());
        }

        return toProductDto(saved);
    }

    @Transactional
    public ProductDto updateProduct(UUID productId, ProductDto request) {
        AuthContext.AuthContextData ctx = AuthContext.get();
        if (!checkPermission(ctx, "products:write")) {
            throw new RuntimeException("FORBIDDEN: You do not have permission to update products");
        }
        ProductEntity entity = productRepository.findById(productId)
            .orElseThrow(() -> new ResourceNotFoundException("Product not found: " + productId, "PRODUCT_NOT_FOUND"));
        entity.setName(request.getName());
        entity.setDescription(request.getDescription());
        entity.setUpdatedAt(java.time.Instant.now());
        if (request.getAttributes() != null) {
            saveAttributeValues(productId, request.getAttributes());
        }
        return toProductDto(productRepository.save(entity));
    }

    // ======================================================================
    // DYNAMIC PRODUCT ATTRIBUTE SCHEMA
    // ======================================================================

    @Transactional(readOnly = true)
    public List<ProductAttributeSchemaEntity> getAttributeSchema(String serviceKey) {
        return attributeSchemaRepository
                .findByServiceKeyOrderByDisplayOrderAsc(serviceKey);
    }

    @Transactional(readOnly = true)
    public Map<String, String> getAttributeValues(UUID productId) {
        return attributeValueRepository.findByProductId(productId)
                .stream()
                .collect(Collectors.toMap(
                        ProductAttributeValueEntity::getAttributeKey,
                        v -> v.getAttributeValue() != null ? v.getAttributeValue() : ""
                ));
    }

    @Transactional
    private void saveAttributeValues(UUID productId, Map<String, String> attributes) {
        attributes.forEach((key, value) -> {
            ProductAttributeValueEntity av = attributeValueRepository
                    .findByProductIdAndAttributeKey(productId, key)
                    .orElseGet(ProductAttributeValueEntity::new);
            av.setProductId(productId);
            av.setAttributeKey(key);
            av.setAttributeValue(value);
            av.setUpdatedAt(java.time.Instant.now());
            attributeValueRepository.save(av);
        });
    }

    // ======================================================================
    // INVENTORY STOCK
    // ======================================================================

    @Transactional(readOnly = true)
    public int getAvailableStock(UUID variantId) {
        return inventoryRepository.findByProductVariantId(variantId)
                .map(InventoryEntity::getAvailableQty)
                .orElse(0);
    }

    // ======================================================================
    // MAPPERS
    // ======================================================================

    private CategoryDto toCategoryDto(CategoryEntity cat) {
        return CategoryDto.builder()
            .id(cat.getId())
            .name(cat.getName())
            .iconUrl(cat.getIconUrl())
            .serviceKey(cat.getServiceKey())
            .parentCategoryId(cat.getParentCategoryId())
            .displayOrder(cat.getDisplayOrder())
            .colorHex(cat.getColorHex())
            .active(cat.isActive())
            .build();
    }

    private ProductDto toProductDto(ProductEntity prod) {
        return ProductDto.builder()
            .id(prod.getId())
            .shopId(prod.getShopId())
            .categoryId(prod.getCategoryId())
            .serviceKey(prod.getServiceKey())
            .name(prod.getName())
            .description(prod.getDescription())
            .build();
    }
}

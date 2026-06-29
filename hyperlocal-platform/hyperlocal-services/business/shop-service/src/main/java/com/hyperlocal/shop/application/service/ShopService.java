package com.hyperlocal.shop.application.service;

import com.hyperlocal.shop.infrastructure.entity.ShopEntity;
import com.hyperlocal.shop.infrastructure.repository.ShopRepository;
import com.hyperlocal.shop.infrastructure.dto.ShopDto;
import com.hyperlocal.common.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ShopService {
    private final ShopRepository shopRepository;

    @Transactional(readOnly = true)
    public List<ShopDto> getShopsByBranch(UUID branchId) {
        return shopRepository.findByBranchIdAndDeletedFalse(branchId).stream()
            .map(shop -> ShopDto.builder()
                .id(shop.getId())
                .branchId(shop.getBranchId())
                .name(shop.getName())
                .isOpen(shop.isOpen())
                .build())
            .collect(Collectors.toList());
    }

    @Transactional
    public ShopDto registerShop(ShopDto dto) {
        ShopEntity shop = new ShopEntity();
        shop.setBranchId(dto.getBranchId());
        shop.setName(dto.getName());
        shop.setOpen(dto.isOpen());
        
        ShopEntity saved = shopRepository.save(shop);
        
        return ShopDto.builder()
            .id(saved.getId())
            .branchId(saved.getBranchId())
            .name(saved.getName())
            .isOpen(saved.isOpen())
            .build();
    }
}

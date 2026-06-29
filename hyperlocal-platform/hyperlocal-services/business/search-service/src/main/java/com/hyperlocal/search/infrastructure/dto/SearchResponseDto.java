package com.hyperlocal.search.infrastructure.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SearchResponseDto {
    private List<ProductResult> products;
    private List<ShopResult> shops;
    private long totalResults;
}

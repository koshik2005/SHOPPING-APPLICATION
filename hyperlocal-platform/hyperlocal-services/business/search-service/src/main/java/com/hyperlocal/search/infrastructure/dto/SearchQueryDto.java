package com.hyperlocal.search.infrastructure.dto;

import lombok.Data;

@Data
public class SearchQueryDto {
    private String query;
    private String categoryId;
    private Double minPrice;
    private Double maxPrice;
    private Double rating;
}

package com.hyperlocal.search.application.service;

import com.hyperlocal.search.infrastructure.entity.*;
import com.hyperlocal.search.infrastructure.repository.*;
import com.hyperlocal.search.infrastructure.dto.*;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class SearchService {

    private static final Logger log = LoggerFactory.getLogger(SearchService.class);

    private final SearchHistoryRepository historyRepository;
    private final PopularSearchRepository popularRepository;
    private final ProductSearchRepository productSearchRepository;
    private final ShopSearchRepository shopSearchRepository;

    @Transactional
    public SearchResponseDto executeSearch(String customerId, SearchQueryDto query) {

        String q = query.getQuery() != null ? query.getQuery().trim() : "";

        // Record search history for analytics and suggestions
        if (customerId != null && !q.isEmpty()) {
            SearchHistoryEntity history = new SearchHistoryEntity();
            history.setCustomerId(UUID.fromString(customerId));
            history.setSearchQuery(q);
            historyRepository.save(history);
        }

        if (q.isEmpty()) {
            return SearchResponseDto.builder()
                .products(Collections.emptyList())
                .shops(Collections.emptyList())
                .totalResults(0)
                .build();
        }

        // PostgreSQL full-text search (ILIKE) — zero Elasticsearch dependency
        List<ProductResult> products = productSearchRepository.fullTextSearch(q).stream()
            .map(p -> ProductResult.builder()
                .id(p.getId())
                .name(p.getName())
                .description(p.getDescription())
                .build())
            .collect(Collectors.toList());

        List<ShopResult> shops = shopSearchRepository.fullTextSearch(q).stream()
            .map(s -> ShopResult.builder()
                .id(s.getId())
                .name(s.getName())
                .description(s.getDescription())
                .build())
            .collect(Collectors.toList());

        int total = products.size() + shops.size();
        log.debug("[SEARCH] query='{}' products={} shops={}", q, products.size(), shops.size());

        return SearchResponseDto.builder()
            .products(products)
            .shops(shops)
            .totalResults(total)
            .build();
    }

    @Transactional(readOnly = true)
    public SearchSuggestionDto getSuggestions(String customerId) {

        List<String> recent = Collections.emptyList();
        if (customerId != null) {
            recent = historyRepository.findByCustomerIdOrderByCreatedAtDesc(UUID.fromString(customerId)).stream()
                .map(h -> h != null ? h.getSearchQuery() : "")
                .filter(s -> s != null && !s.isEmpty())
                .limit(10)
                .distinct()
                .collect(Collectors.toList());
        }

        List<String> trending = popularRepository.findTopPopularSearches().stream()
            .map(p -> p != null ? p.getSearchQuery() : "")
            .filter(s -> s != null && !s.isEmpty())
            .limit(10)
            .collect(Collectors.toList());

        return SearchSuggestionDto.builder()
            .autocomplete(recent.isEmpty() ? trending : recent)
            .trending(trending)
            .recent(recent)
            .build();
    }
}

package com.hyperlocal.search.infrastructure.adapter.inbound;

import com.hyperlocal.search.application.service.SearchService;
import com.hyperlocal.search.infrastructure.dto.*;
import com.hyperlocal.core.domain.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/search")
@RequiredArgsConstructor
public class SearchController {
    private final SearchService searchService;

    @PostMapping("/query")
    public ResponseEntity<ApiResponse<SearchResponseDto>> query(
            @RequestHeader(value = "X-User-ID", required = false) String userId,
            @RequestBody SearchQueryDto query) {
        SearchResponseDto response = searchService.executeSearch(userId, query);
        return ResponseEntity.ok(ApiResponse.ok(response, UUID.randomUUID().toString()));
    }

    @GetMapping("/suggestions")
    public ResponseEntity<ApiResponse<SearchSuggestionDto>> getSuggestions(
            @RequestHeader(value = "X-User-ID", required = false) String userId) {
        SearchSuggestionDto response = searchService.getSuggestions(userId);
        return ResponseEntity.ok(ApiResponse.ok(response, UUID.randomUUID().toString()));
    }
}

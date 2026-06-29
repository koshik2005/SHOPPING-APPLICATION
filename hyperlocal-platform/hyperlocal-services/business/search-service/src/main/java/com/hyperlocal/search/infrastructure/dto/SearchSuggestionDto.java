package com.hyperlocal.search.infrastructure.dto;

import lombok.Builder;
import lombok.Data;
import java.util.List;

@Data
@Builder
public class SearchSuggestionDto {
    private List<String> autocomplete;
    private List<String> trending;
    private List<String> recent;
}

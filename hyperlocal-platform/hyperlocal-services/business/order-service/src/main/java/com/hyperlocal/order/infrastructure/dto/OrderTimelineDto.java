package com.hyperlocal.order.infrastructure.dto;

import lombok.Builder;
import lombok.Data;
import java.time.Instant;
import java.util.List;

@Data
@Builder
public class OrderTimelineDto {
    private List<TimelineEvent> history;

    @Data
    @Builder
    public static class TimelineEvent {
        private String status;
        private String remarks;
        private Instant timestamp;
    }
}

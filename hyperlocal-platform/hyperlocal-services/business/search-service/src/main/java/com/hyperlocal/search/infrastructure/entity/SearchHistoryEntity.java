package com.hyperlocal.search.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "search_history")
public class SearchHistoryEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "customer_id", nullable = false)
    private UUID customerId;

    @Column(name = "search_query", nullable = false)
    private String searchQuery;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();
}

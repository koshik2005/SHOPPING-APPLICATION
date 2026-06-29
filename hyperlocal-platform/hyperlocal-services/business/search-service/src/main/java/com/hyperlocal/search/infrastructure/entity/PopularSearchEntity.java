package com.hyperlocal.search.infrastructure.entity;

import jakarta.persistence.*;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "popular_searches")
public class PopularSearchEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "search_query", nullable = false, unique = true)
    private String searchQuery;

    @Column(name = "search_count", nullable = false)
    private long searchCount = 1;
}

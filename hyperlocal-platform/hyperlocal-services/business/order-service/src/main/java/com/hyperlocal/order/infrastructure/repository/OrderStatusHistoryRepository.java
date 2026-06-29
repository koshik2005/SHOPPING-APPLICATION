package com.hyperlocal.order.infrastructure.repository;

import com.hyperlocal.order.infrastructure.entity.OrderStatusHistoryEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface OrderStatusHistoryRepository extends JpaRepository<OrderStatusHistoryEntity, UUID> {
    List<OrderStatusHistoryEntity> findByOrderIdOrderByCreatedAtAsc(UUID orderId);
}

package com.hyperlocal.gateway.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.function.RequestPredicates;
import org.springframework.web.servlet.function.RouterFunction;
import org.springframework.web.servlet.function.RouterFunctions;
import org.springframework.web.servlet.function.ServerResponse;

import static org.springframework.cloud.gateway.server.mvc.handler.HandlerFunctions.http;

@Configuration
public class GatewayRoutingConfig {

    @Value("${service.auth.url:http://localhost:8081}")
    private String authServiceUrl;

    @Value("${service.customer.url:http://localhost:8082}")
    private String customerServiceUrl;

    @Value("${service.inventory.url:http://localhost:8083}")
    private String inventoryServiceUrl;

    @Value("${service.order.url:http://localhost:8084}")
    private String orderServiceUrl;

    @Value("${service.payment.url:http://localhost:8085}")
    private String paymentServiceUrl;

    @Value("${service.wallet.url:http://localhost:8086}")
    private String walletServiceUrl;

    @Value("${service.delivery.url:http://localhost:8087}")
    private String deliveryServiceUrl;

    @Value("${service.branch.url:http://localhost:8088}")
    private String branchServiceUrl;

    @Value("${service.search.url:http://localhost:8089}")
    private String searchServiceUrl;

    @Value("${service.config.url:http://localhost:8090}")
    private String configServiceUrl;

    @Value("${service.audit.url:http://localhost:8091}")
    private String auditServiceUrl;

    @Value("${service.notification.url:http://localhost:8092}")
    private String notificationServiceUrl;

    @Value("${service.scheduler.url:http://localhost:8093}")
    private String schedulerServiceUrl;

    @Value("${service.shop.url:http://localhost:8094}")
    private String shopServiceUrl;

    @Value("${service.branch-manager.url:http://localhost:8095}")
    private String branchManagerServiceUrl;

    @Value("${service.cart.url:http://localhost:8096}")
    private String cartServiceUrl;

    @Bean
    @SuppressWarnings("null") // HandlerFunctions.http() is @Nullable in signature but non-null at runtime
    public RouterFunction<ServerResponse> gatewayRoutes() {
        return RouterFunctions.route()
            // 1. Auth Routing
            .route(RequestPredicates.path("/api/v1/auth/**"), http(authServiceUrl))
            // 2. Customer Routing
            .route(RequestPredicates.path("/api/v1/customers/**"), http(customerServiceUrl))
            // 3. Inventory Routing
            .route(RequestPredicates.path("/api/v1/inventory/**"), http(inventoryServiceUrl))
            // 4. Orders Routing
            .route(RequestPredicates.path("/api/v1/orders/**"), http(orderServiceUrl))
            // 5. Payments Routing
            .route(RequestPredicates.path("/api/v1/payments/**"), http(paymentServiceUrl))
            // 6. Wallet Routing
            .route(RequestPredicates.path("/api/v1/wallets/**"), http(walletServiceUrl))
            // 7. Delivery Routing
            .route(RequestPredicates.path("/api/v1/deliveries/**"), http(deliveryServiceUrl))
            // 8. Branch Routing
            .route(RequestPredicates.path("/api/v1/branches/**"), http(branchServiceUrl))
            // 9. Search Routing
            .route(RequestPredicates.path("/api/v1/search/**"), http(searchServiceUrl))
            // 10. Config Routing
            .route(RequestPredicates.path("/api/v1/config/**"), http(configServiceUrl))
            // 11. Audit Routing
            .route(RequestPredicates.path("/api/v1/audit/**"), http(auditServiceUrl))
            // 12. Notifications Routing
            .route(RequestPredicates.path("/api/v1/notifications/**"), http(notificationServiceUrl))
            // 13. Scheduler Routing
            .route(RequestPredicates.path("/api/v1/scheduler/**"), http(schedulerServiceUrl))
            // 14. Shop Routing
            .route(RequestPredicates.path("/api/v1/shops/**"), http(shopServiceUrl))
            // 15. Branch Manager Routing
            .route(RequestPredicates.path("/api/v1/branch-manager/**"), http(branchManagerServiceUrl))
            // 16. Cart Routing
            .route(RequestPredicates.path("/api/v1/cart/**"), http(cartServiceUrl))
            .build();
    }
}

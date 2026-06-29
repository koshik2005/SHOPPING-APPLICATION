package com.hyperlocal.notification.infrastructure.adapter;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Server-Sent Events (SSE) Notification Controller.
 *
 * Provides a real-time push channel from the backend to Flutter/web clients.
 * Used as the development and self-hosted alternative to Firebase Cloud Messaging (FCM).
 *
 * Flutter client subscribes to: GET /api/v1/notifications/subscribe/{customerId}
 * Backend pushes events to: POST /api/v1/notifications/push/{customerId}
 *
 * Production migration path:
 *   Replace this controller's event delivery with an FCM-backed PushNotificationProvider.
 *   The Flutter client should detect the SSE connection and fall back gracefully.
 *
 * Connection lifecycle:
 *   - Client connects and receives a keep-alive heartbeat every 30 seconds.
 *   - Connection timeout: 5 minutes (configurable).
 *   - On disconnect, the emitter is removed from the registry.
 */
@RestController
@RequestMapping("/api/v1/notifications")
public class SseNotificationController {

    private static final Logger log = LoggerFactory.getLogger(SseNotificationController.class);

    // Concurrent map of customerId → SseEmitter for active connections
    private final Map<UUID, SseEmitter> emitters = new ConcurrentHashMap<>();

    /**
     * Flutter/web client subscribes to receive real-time notification events.
     */
    @GetMapping(value = "/subscribe/{customerId}", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter subscribe(@PathVariable UUID customerId) {
        SseEmitter emitter = new SseEmitter(5 * 60 * 1000L); // 5-minute timeout

        emitters.put(customerId, emitter);
        log.info("[SSE] Customer {} connected for live notifications", customerId);

        emitter.onCompletion(() -> {
            emitters.remove(customerId);
            log.debug("[SSE] Customer {} disconnected (completed)", customerId);
        });
        emitter.onTimeout(() -> {
            emitters.remove(customerId);
            log.debug("[SSE] Customer {} connection timed out", customerId);
        });
        emitter.onError(e -> {
            emitters.remove(customerId);
            log.warn("[SSE] Customer {} connection error: {}", customerId, e.getMessage());
        });

        // Send initial handshake event
        try {
            emitter.send(SseEmitter.event()
                .name("connected")
                .data("{\"status\":\"connected\",\"customerId\":\"" + customerId + "\"}"));
        } catch (IOException e) {
            emitters.remove(customerId);
        }

        return emitter;
    }

    /**
     * Backend services push notifications to a specific customer.
     * Called internally by NotificationService after persisting the notification.
     */
    @PostMapping("/push/{customerId}")
    @SuppressWarnings("null")
    public void pushToCustomer(
            @PathVariable UUID customerId,
            @RequestBody Map<String, Object> payload) {

        SseEmitter emitter = emitters.get(customerId);
        if (emitter == null) {
            log.debug("[SSE] No active SSE connection for customer {}", customerId);
            return;
        }

        try {
            emitter.send(SseEmitter.event()
                .name("notification")
                .data(payload));
            log.info("[SSE] Pushed notification to customer {}: {}", customerId, payload.get("type"));
        } catch (IOException e) {
            emitters.remove(customerId);
            log.warn("[SSE] Failed to push to customer {}, removing emitter", customerId);
        }
    }

    /**
     * Returns count of currently active SSE connections.
     * Used by health checks and monitoring dashboards.
     */
    @GetMapping("/connections/count")
    public Map<String, Integer> getConnectionCount() {
        return Map.of("activeConnections", emitters.size());
    }
}

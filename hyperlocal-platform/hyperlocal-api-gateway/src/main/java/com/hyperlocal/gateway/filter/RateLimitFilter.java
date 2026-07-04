package com.hyperlocal.gateway.filter;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.annotation.Order;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.time.Instant;
import java.util.UUID;
import java.util.logging.Logger;

@Component
@Order(3)
public class RateLimitFilter implements Filter {

    private static final Logger logger = Logger.getLogger(RateLimitFilter.class.getName());

    @Autowired(required = false)
    private StringRedisTemplate redisTemplate;

    private static final long WINDOW_SIZE_MS = 60000; // 60 seconds sliding window
    private static final int DEFAULT_LIMIT = 300;     // default 300 req/min
    private static final int AUTH_LIMIT = 10;          // 10 req/min for auth endpoints
    private static final int SEARCH_LIMIT = 60;        // 60 req/min for search

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        if (redisTemplate == null) {
            // If Redis is not available or not configured in dev, bypass rate limiting
            chain.doFilter(request, response);
            return;
        }

        String path = httpRequest.getRequestURI();
        String clientIp = getClientIp(httpRequest);
        String userId = httpRequest.getHeader("X-User-Id");

        // Determine rate limit key and limit threshold
        String limitKey;
        int limit;

        if (path.startsWith("/api/v1/auth/")) {
            limitKey = "ratelimit:auth:" + clientIp;
            limit = AUTH_LIMIT;
        } else if (path.startsWith("/api/v1/search/")) {
            limitKey = "ratelimit:search:" + (userId != null ? userId : clientIp);
            limit = SEARCH_LIMIT;
        } else {
            limitKey = "ratelimit:api:" + (userId != null ? userId : clientIp);
            limit = DEFAULT_LIMIT;
        }

        try {
            boolean allowed = isAllowed(limitKey, limit);
            if (!allowed) {
                httpResponse.setStatus(429); // 429 Too Many Requests
                httpResponse.setContentType("application/json");
                httpResponse.setHeader("Retry-After", "60");
                httpResponse.getWriter().write(String.format(
                    "{\"errorCode\":\"TOO_MANY_REQUESTS\",\"message\":\"Too many requests. Please try again after 60 seconds.\",\"timestamp\":\"%s\"}",
                    Instant.now().toString()
                ));
                return;
            }
        } catch (Exception e) {
            // Fail open: log error and allow request to proceed if Redis fails
            logger.severe("Rate limiter Redis failure: " + e.getMessage());
        }

        chain.doFilter(request, response);
    }

    private boolean isAllowed(String key, int limit) {
        long now = System.currentTimeMillis();
        long clearBefore = now - WINDOW_SIZE_MS;
        String val = UUID.randomUUID().toString();

        try {
            // 1. Remove old requests outside the sliding window
            redisTemplate.opsForZSet().removeRangeByScore(key, 0, clearBefore);
            // 2. Add current request with timestamp score
            redisTemplate.opsForZSet().add(key, val, now);
            // 3. Set expiration to auto-cleanup inactive keys
            redisTemplate.expire(key, java.time.Duration.ofMillis(WINDOW_SIZE_MS + 10000));
            // 4. Count remaining requests inside the window
            Long count = redisTemplate.opsForZSet().zCard(key);
            return count != null && count <= limit;
        } catch (Exception e) {
            logger.severe("Failed to run sliding window rate limiter: " + e.getMessage());
            return true; // Fail open
        }
    }

    private String getClientIp(HttpServletRequest request) {
        String xff = request.getHeader("X-Forwarded-For");
        if (xff != null && !xff.trim().isEmpty()) {
            return xff.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}

package com.hyperlocal.scheduler.application.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@EnableScheduling
public class SchedulerService {

    @Scheduled(cron = "0 0 * * * *") // Every hour
    public void refreshConfigurationCache() {
        log.info("Executing scheduled job: Refreshing dynamic configuration cache");
    }

    @Scheduled(cron = "0 */10 * * * *") // Every 10 mins
    public void retryFailedNotifications() {
        log.info("Executing scheduled job: Retrying failed notifications in queue");
    }

    @Scheduled(cron = "0 0 2 * * *") // 2 AM daily
    public void executeSessionCleanup() {
        log.info("Executing scheduled job: Purging expired user refresh token families");
    }
}

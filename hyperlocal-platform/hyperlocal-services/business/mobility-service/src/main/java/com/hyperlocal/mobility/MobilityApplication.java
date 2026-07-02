package com.hyperlocal.mobility;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication(scanBasePackages = "com.hyperlocal")
public class MobilityApplication {
    public static void main(String[] args) {
        SpringApplication.run(MobilityApplication.class, args);
    }
}

package com.hyperlocal.branch;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication(scanBasePackages = "com.hyperlocal")
public class BranchApplication {
    public static void main(String[] args) {
        SpringApplication.run(BranchApplication.class, args);
    }
}

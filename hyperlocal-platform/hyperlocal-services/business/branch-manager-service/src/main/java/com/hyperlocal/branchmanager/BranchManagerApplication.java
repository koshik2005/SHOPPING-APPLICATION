package com.hyperlocal.branchmanager;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication(scanBasePackages = "com.hyperlocal")
public class BranchManagerApplication {
    public static void main(String[] args) {
        SpringApplication.run(BranchManagerApplication.class, args);
    }
}

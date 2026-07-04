package com.hyperlocal.auth.infrastructure.config;

import com.hyperlocal.auth.infrastructure.entity.UserEntity;
import com.hyperlocal.auth.infrastructure.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.ApplicationListener;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.logging.Logger;

@Component
public class RootAdminBootstrap implements ApplicationListener<ApplicationReadyEvent> {

    private static final Logger logger = Logger.getLogger(RootAdminBootstrap.class.getName());

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    public void onApplicationEvent(ApplicationReadyEvent event) {
        bootstrapRootSuperAdmin();
    }

    private void bootstrapRootSuperAdmin() {
        try {
            // Check if any user holds ROOT_SUPER_ADMIN role
            List<UserEntity> allUsers = userRepository.findAll();
            boolean rootExists = allUsers.stream()
                .anyMatch(user -> user.getRoles().contains("ROLE_ROOT_SUPER_ADMIN"));

            if (!rootExists) {
                logger.info("Initializing Root Super Admin account provisioning...");
                
                String rootEmail = System.getenv("ROOT_ADMIN_EMAIL");
                if (rootEmail == null || rootEmail.trim().isEmpty()) {
                    rootEmail = "root_admin@hyperlocal.app";
                }

                String rootPassword = System.getenv("ROOT_ADMIN_PASSWORD");
                if (rootPassword == null || rootPassword.trim().isEmpty()) {
                    rootPassword = "RootSecurePassword123!";
                }

                UserEntity rootUser = new UserEntity();
                rootUser.setEmail(rootEmail);
                rootUser.setPasswordHash(passwordEncoder.encode(rootPassword));
                rootUser.setStatus("PASSWORD_CHANGE_REQUIRED");
                rootUser.setMfaEnabled(true);

                Set<String> roles = new HashSet<>();
                roles.add("ROLE_ROOT_SUPER_ADMIN");
                roles.add("ROLE_SUPER_ADMIN");
                rootUser.setRoles(roles);

                userRepository.save(rootUser);
                logger.info("Successfully provisioned Root Super Admin account: " + rootEmail + " with PASSWORD_CHANGE_REQUIRED state.");
            } else {
                logger.info("Root Super Admin account already exists. Skipping bootstrap.");
            }
        } catch (Exception e) {
            logger.severe("Failed to bootstrap Root Super Admin: " + e.getMessage());
        }
    }
}

package com.lenslink.health;

import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.stereotype.Component;

@Component
public class RollbackTestHealthIndicator implements HealthIndicator {

    @Override
    public Health health() {
        return Health.down()
                .withDetail("reason", "intentional CD rollback test")
                .build();
    }
}

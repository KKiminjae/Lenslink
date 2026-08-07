package com.lenslink;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.test.context.ActiveProfiles;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

@SpringBootTest
@ActiveProfiles("test")
@Testcontainers
class LenslinkApplicationTests {

	@Container
	@ServiceConnection
	static MySQLContainer<?> mysql =
			new MySQLContainer<>("mysql:8.4")
					.withDatabaseName("lenslink_test")
					.withUsername("test")
					.withPassword("test");

	@Test
	void contextLoads() {
	}

}

package com.lenslink.global.exception;

import org.junit.jupiter.api.Test;
import org.springframework.http.ResponseEntity;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class GlobalExceptionHandlerTest {
    private final GlobalExceptionHandler exceptionHandler =
            new GlobalExceptionHandler();

    @Test
    void 이미지_검증예외_HTTP_400_변환(){
        InvalidImageException exception = new InvalidImageException("잘못된 이미지 입니다.");
        ResponseEntity<Map<String, String>> response = exceptionHandler.handleInvalidImageException(exception);
        assertThat(response.getStatusCode().value())
                .isEqualTo(400);
        assertThat(response.getBody())
                .containsEntry("code", "INVALID_IMAGE")
                .containsEntry("message", "잘못된 이미지 입니다.");
    }
}
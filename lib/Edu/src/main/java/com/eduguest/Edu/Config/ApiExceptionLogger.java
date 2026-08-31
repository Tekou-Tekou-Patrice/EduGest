package com.eduguest.Edu.Config;

import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.Map;

@RestControllerAdvice
public class ApiExceptionLogger {
    private static final Logger log = LoggerFactory.getLogger(ApiExceptionLogger.class);

    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<Map<String, String>> handleRuntime(RuntimeException exception,
                                                               HttpServletRequest request) {
        log.error("API ERROR {} {}: {}", request.getMethod(), request.getRequestURI(),
                exception.getMessage(), exception);
        return ResponseEntity.badRequest()
                .body(Map.of("message", exception.getMessage() == null
                        ? "Erreur interne du serveur" : exception.getMessage()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handle(Exception exception,
                                                       HttpServletRequest request) {
        log.error("API ERROR {} {}: {}", request.getMethod(), request.getRequestURI(),
                exception.getMessage(), exception);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("message", "Erreur interne du serveur"));
    }
}

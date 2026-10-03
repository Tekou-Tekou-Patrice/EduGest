package com.eduguest.Edu.Config;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import static org.assertj.core.api.Assertions.assertThat;

class GlobalExceptionHandlerTest {
    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();

    @Test
    void missingRouteIsNotReportedAsServerUnavailable() {
        var response = handler.handleNotFound(
                new NoResourceFoundException(
                        HttpMethod.GET, "/actuator/health", "Missing health resource"));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(response.getBody()).containsEntry("message", "Ressource introuvable");
    }

    @Test
    void unexpectedErrorsAreLoggedAndReturnSafeServerError() {
        var response = handler.handleGeneric(new IllegalStateException("database details"));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.INTERNAL_SERVER_ERROR);
        assertThat(response.getBody()).containsEntry("message", "Erreur interne du serveur");
    }
}

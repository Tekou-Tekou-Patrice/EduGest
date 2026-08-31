package com.eduguest.Edu;

import com.eduguest.Edu.DTO.RegisterRequest;
import com.eduguest.Edu.DTO.UserDto;
import com.eduguest.Edu.Entity.UserRole;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class ApiContractTest {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void shouldSerializeUserRoleWithFrontFriendlyLabels() throws Exception {
        UserDto dto = new UserDto();
        dto.setFullName("Alice Ndiaye");
        dto.setRole(UserRole.PROVISEUR);

        String json = objectMapper.writeValueAsString(dto);

        // @JsonProperty("name") on fullName + @JsonValue on UserRole
        assertThat(json).contains("Alice Ndiaye");
        assertThat(json).containsAnyOf("\"role\":\"Proviseur\"", "\"role\":\"PROVISEUR\"");
    }

    @Test
    void shouldDeserializeRegisterPayloadUsingNameField() throws Exception {
        String json = """
                {"username":"alice@example.com","name":"Alice Ndiaye","email":"alice@example.com","password":"secret","role":"Proviseur"}
                """;

        RegisterRequest request = objectMapper.readValue(json, RegisterRequest.class);

        assertThat(request.getFullName()).isEqualTo("Alice Ndiaye");
        assertThat(request.getRole()).isEqualTo(UserRole.PROVISEUR);
    }

    @Test
    void shouldParseAccentedSecretaireRole() {
        assertThat(UserRole.fromValue("Secrétaire")).isEqualTo(UserRole.SECRETAIRE);
        assertThat(UserRole.fromValue("secretaire")).isEqualTo(UserRole.SECRETAIRE);
    }
}

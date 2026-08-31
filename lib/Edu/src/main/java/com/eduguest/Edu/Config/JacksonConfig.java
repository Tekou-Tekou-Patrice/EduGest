package com.eduguest.Edu.Config;

import com.eduguest.Edu.Entity.UserRole;
import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.JsonDeserializer;
import com.fasterxml.jackson.databind.JsonSerializer;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.module.SimpleModule;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.converter.json.Jackson2ObjectMapperBuilder;

import java.io.IOException;

@Configuration
public class JacksonConfig {

    @Bean
    Jackson2ObjectMapperBuilder jackson2ObjectMapperBuilder() {
        Jackson2ObjectMapperBuilder builder = new Jackson2ObjectMapperBuilder();
        SimpleModule module = new SimpleModule();
        module.addSerializer(UserRole.class, new JsonSerializer<>() {
            @Override
            public void serialize(UserRole value, com.fasterxml.jackson.core.JsonGenerator gen, SerializerProvider serializers) throws IOException {
                if (value == null) {
                    gen.writeNull();
                } else {
                    gen.writeString(switch (value) {
                        case MEMBRE -> "Membre";
                        case FONDATEUR -> "Fondateur";
                        case PROVISEUR -> "Proviseur";
                        case CENSEUR -> "Censeur";
                        case SECRETAIRE -> "Secrétaire";
                        case COMPTABLE -> "Comptable";
                        case ENSEIGNANT -> "Enseignant";
                        case SURVEILLANT_GENERAL -> "Surveillant Général";
                        case PARENT -> "Parent";
                    });
                }
            }
        });
        module.addDeserializer(UserRole.class, new JsonDeserializer<>() {
            @Override
            public UserRole deserialize(JsonParser p, DeserializationContext ctxt) throws IOException {
                String value = p.getValueAsString();
                if (value == null) return null;
                String normalized = value.trim()
                        .toLowerCase()
                        .replace('é', 'e')
                        .replace('è', 'e')
                        .replace('ê', 'e');
                return switch (normalized) {
                    case "membre", "member" -> UserRole.MEMBRE;
                    case "fondateur" -> UserRole.FONDATEUR;
                    case "proviseur" -> UserRole.PROVISEUR;
                    case "censeur" -> UserRole.CENSEUR;
                    case "secretaire" -> UserRole.SECRETAIRE;
                    case "comptable" -> UserRole.COMPTABLE;
                    case "enseignant" -> UserRole.ENSEIGNANT;
                    case "surveillant general", "surveillant général" -> UserRole.SURVEILLANT_GENERAL;
                    default -> UserRole.MEMBRE;
                };
            }
        });
        builder.modules(module);
        return builder;
    }
}

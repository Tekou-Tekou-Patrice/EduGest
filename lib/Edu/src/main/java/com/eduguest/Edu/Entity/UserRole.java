package com.eduguest.Edu.Entity;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum UserRole {
    MEMBRE,
    FONDATEUR,
    PROVISEUR,
    CENSEUR,
    SECRETAIRE,
    COMPTABLE,
    ENSEIGNANT,
    SURVEILLANT_GENERAL,
    PARENT;

    @JsonCreator
    public static UserRole fromValue(String value) {
        if (value == null) {
            return null;
        }

        String normalized = value.trim()
                .toLowerCase()
                .replace('é', 'e')
                .replace('è', 'e')
                .replace('ê', 'e');
        return switch (normalized) {
            case "membre", "member" -> MEMBRE;
            case "fondateur" -> FONDATEUR;
            case "proviseur" -> PROVISEUR;
            case "censeur" -> CENSEUR;
            case "secretaire" -> SECRETAIRE;
            case "comptable" -> COMPTABLE;
            case "enseignant" -> ENSEIGNANT;
            case "surveillant general", "surveillant général" -> SURVEILLANT_GENERAL;
            case "parent" -> PARENT;
            default -> throw new IllegalArgumentException("Unknown role: " + value);
        };
    }

    @JsonValue
    public String toValue() {
        return switch (this) {
            case MEMBRE -> "Membre";
            case FONDATEUR -> "Fondateur";
            case PROVISEUR -> "Proviseur";
            case CENSEUR -> "Censeur";
            case SECRETAIRE -> "Secrétaire";
            case COMPTABLE -> "Comptable";
            case ENSEIGNANT -> "Enseignant";
            case SURVEILLANT_GENERAL -> "Surveillant Général";
            case PARENT -> "Parent";
        };
    }
}

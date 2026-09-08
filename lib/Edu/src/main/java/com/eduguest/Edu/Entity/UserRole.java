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
    SURVEILLANT,
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
                .replace('ê', 'e')
                .replace('à', 'a')
                .replace('ù', 'u')
                .replace('ç', 'c')
                .replace('î', 'i')
                .replace('ï', 'i')
                .replace('ô', 'o')
                .replace(" ", "");
        return switch (normalized) {
            case "membre", "member", "eleve", "student" -> MEMBRE;
            case "fondateur", "admin", "administrateur", "administrator" -> FONDATEUR;
            case "proviseur", "directeur", "directrice", "principal" -> PROVISEUR;
            case "censeur" -> CENSEUR;
            case "secretaire", "secretariat", "secretary" -> SECRETAIRE;
            case "comptable" -> COMPTABLE;
            case "enseignant", "professeur", "prof", "teacher" -> ENSEIGNANT;
            case "surveillantgeneral" -> SURVEILLANT_GENERAL;
            case "surveillant" -> SURVEILLANT;
            case "parent", "parents" -> PARENT;
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
            case SURVEILLANT -> "Surveillant";
            case PARENT -> "Parent";
        };
    }
}

package com.eduguest.Edu.Config;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.zip.GZIPInputStream;
import java.util.zip.GZIPOutputStream;

@Converter
public class CompressedStringConverter implements AttributeConverter<String, String> {
    private static final String PREFIX = "gz1:";

    @Override
    public String convertToDatabaseColumn(String value) {
        if (value == null || value.isEmpty() || value.startsWith(PREFIX)) {
            return value;
        }

        byte[] source = value.getBytes(StandardCharsets.UTF_8);
        try {
            ByteArrayOutputStream output = new ByteArrayOutputStream();
            try (GZIPOutputStream gzip = new GZIPOutputStream(output)) {
                gzip.write(source);
            }
            String compressed = PREFIX + Base64.getEncoder().encodeToString(output.toByteArray());
            return compressed.length() < value.length() ? compressed : value;
        } catch (IOException error) {
            throw new IllegalStateException("Impossible de compresser le contenu texte", error);
        }
    }

    @Override
    public String convertToEntityAttribute(String value) {
        if (value == null || value.isEmpty() || !value.startsWith(PREFIX)) {
            return value;
        }

        try {
            byte[] compressed = Base64.getDecoder().decode(value.substring(PREFIX.length()));
            try (GZIPInputStream gzip = new GZIPInputStream(new ByteArrayInputStream(compressed));
                 ByteArrayOutputStream output = new ByteArrayOutputStream()) {
                gzip.transferTo(output);
                return output.toString(StandardCharsets.UTF_8);
            }
        } catch (IOException | IllegalArgumentException error) {
            throw new IllegalStateException("Impossible de décompresser le contenu texte", error);
        }
    }
}

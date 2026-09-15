package com.eduguest.Edu.Service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.LinkedHashSet;
import java.util.Set;

@Service
public class PhoneNumberService {

    private final String defaultCountryCode;

    public PhoneNumberService(
            @Value("${edugest.phone.default-country-code:237}") String defaultCountryCode) {
        this.defaultCountryCode = digitsOnly(defaultCountryCode);
    }

    public String normalize(String phone) {
        String digits = digitsOnly(phone);
        if (digits.isBlank()) {
            return "";
        }
        if (phone != null && phone.trim().startsWith("00")) {
            return digits.substring(2);
        }
        if (phone != null && phone.trim().startsWith("+")) {
            return digits;
        }
        if (!defaultCountryCode.isBlank() && digits.startsWith("0")) {
            return defaultCountryCode + digits.substring(1);
        }
        if (!defaultCountryCode.isBlank() && digits.length() <= 10
                && !digits.startsWith(defaultCountryCode)) {
            return defaultCountryCode + digits;
        }
        return digits;
    }

    public Set<String> lookupCandidates(String phone) {
        String digits = digitsOnly(phone);
        Set<String> candidates = new LinkedHashSet<>();
        if (phone != null && !phone.trim().isBlank()) {
            candidates.add(phone.trim());
        }
        if (!digits.isBlank()) {
            candidates.add(digits);
        }

        String normalized = normalize(phone);
        if (!normalized.isBlank()) {
            candidates.add(normalized);
            if (!defaultCountryCode.isBlank() && normalized.startsWith(defaultCountryCode)) {
                String local = normalized.substring(defaultCountryCode.length());
                candidates.add(local);
                candidates.add("0" + local);
                candidates.add("+" + normalized);
                candidates.add("00" + normalized);
            }
        }
        return candidates;
    }

    private String digitsOnly(String value) {
        return value == null ? "" : value.replaceAll("\\D", "");
    }
}

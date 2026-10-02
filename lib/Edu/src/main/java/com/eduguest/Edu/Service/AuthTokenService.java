package com.eduguest.Edu.Service;

import com.eduguest.Edu.Entity.User;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;

/**
 * Stateless, signed access tokens. The user is looked up on every request so
 * disabled accounts and role changes take effect immediately.
 */
@Service
public class AuthTokenService {
    private static final String HMAC_ALGORITHM = "HmacSHA256";
    // Durée de validité de session fixée à 1 mois (30 jours). À expiration, l'utilisateur doit se reconnecter.
    private static final long TOKEN_LIFETIME_SECONDS = 30L * 24 * 60 * 60;

    private final byte[] secret;

    public AuthTokenService(@Value("${edugest.security.token-secret}") String secret) {
        if (secret == null || secret.length() < 32) {
            throw new IllegalStateException("edugest.security.token-secret doit contenir au moins 32 caractères");
        }
        this.secret = secret.getBytes(StandardCharsets.UTF_8);
    }

    public String issue(User user) {
        long expiresAt = Instant.now().getEpochSecond() + TOKEN_LIFETIME_SECONDS;
        String payload = user.getId() + "." + expiresAt;
        return payload + "." + sign(payload);
    }

    public Long verifyAndGetUserId(String authorizationHeader) {
        if (authorizationHeader == null || !authorizationHeader.startsWith("Bearer ")) {
            return null;
        }
        String token = authorizationHeader.substring("Bearer ".length()).trim();
        String[] parts = token.split("\\.", -1);
        if (parts.length != 3) return null;
        try {
            long userId = Long.parseLong(parts[0]);
            long expiresAt = Long.parseLong(parts[1]);
            if (expiresAt < Instant.now().getEpochSecond()) return null;
            String payload = parts[0] + "." + parts[1];
            if (!constantTimeEquals(parts[2], sign(payload))) return null;
            return userId;
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private String sign(String payload) {
        try {
            Mac mac = Mac.getInstance(HMAC_ALGORITHM);
            mac.init(new SecretKeySpec(secret, HMAC_ALGORITHM));
            return Base64.getUrlEncoder().withoutPadding()
                    .encodeToString(mac.doFinal(payload.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception ex) {
            throw new IllegalStateException("Impossible de signer le jeton d'authentification", ex);
        }
    }

    private boolean constantTimeEquals(String left, String right) {
        byte[] a = left.getBytes(StandardCharsets.UTF_8);
        byte[] b = right.getBytes(StandardCharsets.UTF_8);
        if (a.length != b.length) return false;
        int result = 0;
        for (int i = 0; i < a.length; i++) result |= a[i] ^ b[i];
        return result == 0;
    }
}

package com.eduguest.Edu.Service;

import com.eduguest.Edu.Entity.User;
import com.eduguest.Edu.Entity.VerificationCode;
import com.eduguest.Edu.Repository.VerificationCodeRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.HexFormat;

@Service
public class VerificationService {
    private static final Logger log = LoggerFactory.getLogger(VerificationService.class);
    private final VerificationCodeRepository repository;
    private final JavaMailSender mailSender;
    private final RestClient restClient;
    private final PhoneNumberService phoneNumberService;
    private final SecureRandom random = new SecureRandom();

    @Value("${edugest.verification.mail-from:${spring.mail.username:}}")
    private String mailFrom;
    @Value("${edugest.evolution.enabled:false}")
    private boolean evolutionEnabled;
    @Value("${edugest.evolution.base-url:}")
    private String evolutionBaseUrl;
    @Value("${edugest.evolution.api-key:}")
    private String evolutionApiKey;
    @Value("${edugest.evolution.instance:}")
    private String evolutionInstance;
    @Value("${edugest.verification.whatsapp-first:false}")
    private boolean whatsappFirst;
    @Value("${edugest.verification.local-code-enabled:false}")
    private boolean localCodeEnabled;

    public VerificationService(VerificationCodeRepository repository,
                               JavaMailSender mailSender,
                               PhoneNumberService phoneNumberService) {
        this.repository = repository;
        this.mailSender = mailSender;
        this.restClient = RestClient.builder().build();
        this.phoneNumberService = phoneNumberService;
    }

    public String issue(User user, String purpose) {
        String code = String.format("%06d", random.nextInt(1_000_000));
        VerificationCode verification = new VerificationCode();
        verification.setUser(user);
        verification.setCodeHash(hash(code));
        verification.setPurpose(purpose);
        verification.setExpiresAt(LocalDateTime.now().plusMinutes(15));
        verification.setUsed(false);
        repository.save(verification);
        send(user, code);
        return code;
    }

    public boolean isLocalCodeEnabled() {
        return localCodeEnabled;
    }

    public void sendWelcome(User user, String schoolName, String schoolEmail,
                            String schoolPhone, String language) {
        boolean english = "en".equalsIgnoreCase(language);
        String subject = english
                ? "Welcome to " + schoolName
                : "Bienvenue à " + schoolName;
        String message = english
                ? "Hello " + user.getFullName() + ",\n\n"
                + "Welcome to " + schoolName + ". Your staff account has been created.\n"
                + "You can now log in with your email and password.\n\n"
                + "School contact: " + (schoolPhone == null ? "" : schoolPhone)
                : "Bonjour " + user.getFullName() + ",\n\n"
                + "Bienvenue à " + schoolName + ". Votre compte du personnel a été créé.\n"
                + "Vous pouvez maintenant vous connecter avec votre adresse e-mail et votre mot de passe.\n\n"
                + "Contact de l'école : " + (schoolPhone == null ? "" : schoolPhone);
        boolean sent = false;
        if (user.getEmail() != null && !user.getEmail().isBlank()) {
            try {
                SimpleMailMessage mail = new SimpleMailMessage();
                mail.setTo(user.getEmail());
                if (mailFrom != null && !mailFrom.isBlank()) mail.setFrom(mailFrom);
                if (schoolEmail != null && !schoolEmail.isBlank()) mail.setReplyTo(schoolEmail);
                mail.setSubject(subject);
                mail.setText(message);
                mailSender.send(mail);
                sent = true;
            } catch (RuntimeException error) {
                log.warn("Envoi du message de bienvenue par e-mail impossible pour {}", user.getId(), error);
            }
        }
        if (evolutionEnabled && user.getPhone() != null && !user.getPhone().isBlank()) {
            try {
                sent = sendWhatsApp(user, message) || sent;
            } catch (RuntimeException error) {
                log.warn("Envoi du message de bienvenue par WhatsApp impossible pour {}", user.getId(), error);
            }
        }
        if (!sent) {
            log.info("Message de bienvenue non envoyé : aucun canal disponible pour {}", user.getId());
        }
    }

    public void verify(User user, String purpose, String code) {
        VerificationCode verification = repository
                .findTopByUserAndPurposeAndUsedFalseOrderByIdDesc(user, purpose)
                .orElseThrow(() -> new IllegalArgumentException("Code invalide ou expiré"));
        if (verification.getExpiresAt().isBefore(LocalDateTime.now())
                || !MessageDigest.isEqual(hash(code).getBytes(), verification.getCodeHash().getBytes())) {
            throw new IllegalArgumentException("Code invalide ou expiré");
        }
        verification.setUsed(true);
        repository.save(verification);
    }

    private void send(User user, String code) {
        String message = "Votre code EduGest est " + code + ". Il est valable 15 minutes.";
        if (whatsappFirst) {
            try {
                if (sendWhatsApp(user, message)) {
                    return;
                }
            } catch (RuntimeException error) {
                log.warn("Envoi WhatsApp prioritaire impossible pour {}, tentative e-mail", user.getId(), error);
            }
        }
        if (user.getEmail() != null && !user.getEmail().isBlank()) {
            try {
                SimpleMailMessage mail = new SimpleMailMessage();
                mail.setTo(user.getEmail());
                if (mailFrom != null && !mailFrom.isBlank()) mail.setFrom(mailFrom);
                mail.setSubject("Code de vérification EduGest");
                mail.setText(message);
                mailSender.send(mail);
                return;
            } catch (RuntimeException error) {
                // E-mail prioritaire, WhatsApp devient le relais si le SMTP est indisponible.
                log.warn("Envoi e-mail du code impossible, tentative WhatsApp pour {}", user.getId(), error);
            }
        }
        if (!sendWhatsApp(user, message)) {
            if (localCodeEnabled) {
                log.info("Code de vérification local pour {} : {}", user.getId(), code);
                return;
            }
            throw new IllegalStateException("Aucun canal de vérification configuré");
        }
    }

    private boolean sendWhatsApp(User user, String message) {
        if (!evolutionEnabled || user.getPhone() == null || user.getPhone().isBlank()
                || evolutionBaseUrl.isBlank() || evolutionInstance.isBlank()) {
            return false;
        }
        restClient.post()
                .uri(evolutionBaseUrl + "/message/sendText/" + evolutionInstance)
                .header("apikey", evolutionApiKey)
                .contentType(MediaType.APPLICATION_JSON)
                .body(java.util.Map.of(
                        "number", phoneNumberService.normalize(user.getPhone()),
                        "text", message))
                .retrieve()
                .toBodilessEntity();
        return true;
    }

    private String hash(String code) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                    .digest(code.getBytes(java.nio.charset.StandardCharsets.UTF_8)));
        } catch (Exception e) {
            throw new IllegalStateException("Impossible de sécuriser le code", e);
        }
    }
}

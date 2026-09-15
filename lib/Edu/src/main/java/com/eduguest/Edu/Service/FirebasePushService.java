package com.eduguest.Edu.Service;

import com.eduguest.Edu.Entity.AppNotification;
import com.eduguest.Edu.Entity.DeviceToken;
import com.eduguest.Edu.Entity.User;
import com.eduguest.Edu.Repository.DeviceTokenRepository;
import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.*;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.FileInputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

@Service
public class FirebasePushService {
    private final DeviceTokenRepository deviceTokenRepository;

    @Value("${edugest.firebase.service-account-path:}")
    private String serviceAccountPath;

    private boolean enabled;

    public FirebasePushService(DeviceTokenRepository deviceTokenRepository) {
        this.deviceTokenRepository = deviceTokenRepository;
    }

    @PostConstruct
    void initialize() {
        try {
            String configuredPath = serviceAccountPath;
            if (configuredPath == null || configuredPath.isBlank()) {
                configuredPath = System.getenv("GOOGLE_APPLICATION_CREDENTIALS");
            }
            if (FirebaseApp.getApps().isEmpty()) {
                if (configuredPath != null && !configuredPath.isBlank()
                        && Files.isRegularFile(Path.of(configuredPath))) {
                    try (FileInputStream credentials = new FileInputStream(configuredPath)) {
                        FirebaseApp.initializeApp(FirebaseOptions.builder()
                                .setCredentials(GoogleCredentials.fromStream(credentials))
                                .build());
                    }
                } else {
                    FirebaseApp.initializeApp(FirebaseOptions.builder()
                            .setCredentials(GoogleCredentials.getApplicationDefault())
                            .build());
                }
            }
            enabled = true;
            System.out.println("FCM activé pour les notifications push.");
        } catch (Exception error) {
            System.err.println("FCM indisponible : " + error.getMessage());
        }
    }

    public void register(User user, String token, String platform) {
        if (token == null || token.isBlank()) return;
        DeviceToken device = deviceTokenRepository.findByToken(token).orElseGet(DeviceToken::new);
        device.setUser(user);
        device.setToken(token);
        device.setPlatform(platform == null ? "unknown" : platform);
        deviceTokenRepository.save(device);
    }

    public void send(AppNotification notification) {
        User recipient = notification.getRecipient();
        if (!enabled || recipient == null || recipient.getId() == null) return;

        List<DeviceToken> devices = deviceTokenRepository.findByUserId(recipient.getId());
        for (DeviceToken device : devices) {
            try {
                Message message = Message.builder()
                        .setToken(device.getToken())
                        .setNotification(Notification.builder()
                                .setTitle(notification.getTitle())
                                .setBody(notification.getMessage())
                                .build())
                        .putData("notificationId", String.valueOf(notification.getId()))
                        .putData("type", notification.getType() == null ? "general" : notification.getType())
                        .setAndroidConfig(AndroidConfig.builder()
                                .setPriority(AndroidConfig.Priority.HIGH)
                                .setNotification(AndroidNotification.builder()
                                        .setChannelId("edugest_alerts")
                                        .setSound("default")
                                        .build())
                                .build())
                        .setApnsConfig(ApnsConfig.builder()
                                .setAps(Aps.builder().setSound("default").setContentAvailable(true).build())
                                .build())
                        .build();
                FirebaseMessaging.getInstance().send(message);
            } catch (FirebaseMessagingException error) {
                if (MessagingErrorCode.UNREGISTERED.equals(error.getMessagingErrorCode())) {
                    deviceTokenRepository.delete(device);
                }
            } catch (Exception ignored) {
                // A failing phone must never prevent the business operation.
            }
        }
    }
}

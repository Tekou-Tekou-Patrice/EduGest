package com.eduguest.Edu.Config;

import com.eduguest.Edu.Entity.UserRole;
import com.eduguest.Edu.Service.UserSecurityContextService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerInterceptor;

import java.io.IOException;
import java.util.Arrays;
import java.util.List;

@Component
public class RoleAuthorizationInterceptor implements HandlerInterceptor {

    private final UserSecurityContextService securityContextService;

    public RoleAuthorizationInterceptor(UserSecurityContextService securityContextService) {
        this.securityContextService = securityContextService;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        String method = request.getMethod();
        String uri = request.getRequestURI();

        if ("OPTIONS".equalsIgnoreCase(method)) {
            return true;
        }

        if (isPublicPath(uri, method)) {
            return true;
        }

        if (securityContextService.getCurrentUserId() == null) {
            sendError(response, HttpStatus.UNAUTHORIZED, "Authentification requise.");
            return false;
        }

        if (handler instanceof HandlerMethod handlerMethod) {
            RequireRoles methodAnnotation = handlerMethod.getMethodAnnotation(RequireRoles.class);
            RequireRoles classAnnotation = handlerMethod.getBeanType().getAnnotation(RequireRoles.class);
            RequireRoles annotation = methodAnnotation != null ? methodAnnotation : classAnnotation;

            if (annotation != null) {
                return validateRoles(request, response, annotation.value());
            }
        }

        if ("POST".equalsIgnoreCase(method) || "PUT".equalsIgnoreCase(method) ||
                "PATCH".equalsIgnoreCase(method) || "DELETE".equalsIgnoreCase(method)) {

            if (uri.startsWith("/api/academique/bulletin-publications/publish") ||
                    uri.startsWith("/api/academique/bulletin-publications/unpublish")) {
                return validateRoles(request, response, new UserRole[]{
                        UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.SECRETAIRE
                });
            }

            if (uri.startsWith("/api/academique/grades") || uri.startsWith("/api/academique/exams")) {
                return validateRoles(request, response, new UserRole[]{
                        UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.ENSEIGNANT
                });
            }

            if (uri.startsWith("/api/academique/lessons") || uri.startsWith("/api/lessons")) {
                return validateRoles(request, response, new UserRole[]{
                        UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR, UserRole.ENSEIGNANT
                });
            }

            if (uri.startsWith("/api/finance")) {
                return validateRoles(request, response, new UserRole[]{
                        UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR, UserRole.COMPTABLE
                });
            }

            if (uri.startsWith("/api/discipline")) {
                return validateRoles(request, response, new UserRole[]{
                        UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR, UserRole.SURVEILLANT_GENERAL, UserRole.SURVEILLANT, UserRole.ENSEIGNANT
                });
            }

            if (uri.startsWith("/api/scolarite")) {
                return validateRoles(request, response, new UserRole[]{
                        UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR, UserRole.SECRETAIRE
                });
            }

            if (uri.startsWith("/api/academique/subjects") || uri.startsWith("/api/academique/schedule")) {
                return validateRoles(request, response, new UserRole[]{
                        UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR
                });
            }

            if (uri.startsWith("/api/academique/events")) {
                return validateRoles(request, response, new UserRole[]{
                        UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR,
                        UserRole.SECRETAIRE, UserRole.COMPTABLE,
                        UserRole.SURVEILLANT_GENERAL, UserRole.SURVEILLANT
                });
            }

            if (uri.startsWith("/api/academique/program")) {
                return validateRoles(request, response, new UserRole[]{
                        UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR, UserRole.ENSEIGNANT
                });
            }

            if (uri.startsWith("/api/academique/teacher-room-checks")) {
                if (uri.contains("/justification")) {
                    return validateRoles(request, response, new UserRole[]{
                            UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.ENSEIGNANT
                    });
                }
                return validateRoles(request, response, new UserRole[]{
                        UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR, UserRole.SURVEILLANT_GENERAL, UserRole.SURVEILLANT
                });
            }

            if (uri.startsWith("/api/notifications/remind-payment")) {
                return validateRoles(request, response, new UserRole[]{
                        UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.COMPTABLE
                });
            }

            if (uri.startsWith("/api/notifications/announcement")) {
                return validateRoles(request, response, new UserRole[]{
                        UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR, UserRole.SECRETAIRE
                });
            }

            if (uri.startsWith("/api/backup")) {
                return validateRoles(request, response, new UserRole[]{
                        UserRole.FONDATEUR, UserRole.PROVISEUR
                });
            }

            if (uri.startsWith("/api/academique/years") || uri.startsWith("/api/school/years") || uri.startsWith("/api/academic-years")) {
                return validateRoles(request, response, new UserRole[]{
                        UserRole.FONDATEUR, UserRole.PROVISEUR
                });
            }

            if (uri.startsWith("/api/school/info")) {
                return validateRoles(request, response, new UserRole[]{
                        UserRole.FONDATEUR, UserRole.PROVISEUR
                });
            }
        }

        if (uri.startsWith("/api/backup/export")) {
            return validateRoles(request, response, new UserRole[]{
                    UserRole.FONDATEUR, UserRole.PROVISEUR
            });
        }

        return true;
    }

    private boolean validateRoles(HttpServletRequest request, HttpServletResponse response, UserRole[] allowedRoles) throws IOException {
        Long userId = securityContextService.getCurrentUserId();
        if (userId == null) {
            sendError(response, HttpStatus.UNAUTHORIZED, "Authentification requise pour effectuer cette opération.");
            return false;
        }

        UserRole userRole = securityContextService.getCurrentRole();
        if (userRole == null) {
            sendError(response, HttpStatus.FORBIDDEN, "Aucun rôle valide trouvé pour cet utilisateur.");
            return false;
        }

        if (userRole == UserRole.FONDATEUR) {
            return true;
        }

        boolean hasPermission = Arrays.asList(allowedRoles).contains(userRole);
        if (!hasPermission) {
            List<String> allowed = Arrays.stream(allowedRoles).map(UserRole::toValue).toList();
            sendError(response, HttpStatus.FORBIDDEN,
                    "Accès refusé : rôle insuffisant (" + userRole.toValue() + "). Rôles autorisés : " + String.join(", ", allowed));
            return false;
        }

        return true;
    }

    private boolean isPublicPath(String uri, String method) {
        return uri.equals("/api/users/login") ||
                (uri.equals("/api/users/register") && "POST".equalsIgnoreCase(method)) ||
                (uri.equals("/api/users/verify-registration") && "POST".equalsIgnoreCase(method)) ||
                (uri.equals("/api/users/request-password-reset") && "POST".equalsIgnoreCase(method)) ||
                (uri.equals("/api/users/reset-password") && "POST".equalsIgnoreCase(method)) ||
                ((("GET".equalsIgnoreCase(method) || "PUT".equalsIgnoreCase(method))
                        && uri.equals("/api/saas-settings")) ||
                 (("GET".equalsIgnoreCase(method) && (
                        uri.equals("/api/schools/all") ||
                        uri.equals("/api/schools/stats") ||
                        uri.equals("/api/schools/expiring-soon")
                 )) || ("PATCH".equalsIgnoreCase(method) && uri.matches("/api/schools/\\d+/toggle")))) ||
                uri.startsWith("/api/schools/search") ||
                uri.startsWith("/static/") ||
                uri.equals("/") ||
                uri.endsWith(".html") ||
                uri.endsWith(".js") ||
                uri.endsWith(".css") ||
                uri.endsWith(".png") ||
                uri.endsWith(".ico");
    }

    private void sendError(HttpServletResponse response, HttpStatus status, String message) throws IOException {
        response.setStatus(status.value());
        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write("{\"status\":" + status.value() + ",\"message\":\"" + message + "\"}");
    }
}

# --- Stage 1 : Build ---
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app

# Copier uniquement le pom.xml d'abord (meilleur cache Docker)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copier le reste du code et builder
COPY src ./src
RUN mvn clean package -DskipTests -B

# --- Stage 2 : Run ---
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

# Copier le jar généré depuis le stage de build
COPY --from=build /app/target/*.jar app.jar

# Render injecte la variable PORT automatiquement
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]

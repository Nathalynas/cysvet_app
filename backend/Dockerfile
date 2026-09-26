# Build e execucao do backend. As imagens base existem para amd64 e arm64
# (a VM Ampere da Oracle Cloud e arm64), entao o mesmo arquivo serve nos dois.

FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
# Dependencias primeiro: so baixam de novo quando o pom.xml muda.
COPY pom.xml .
RUN mvn -q -B dependency:go-offline
COPY src ./src
RUN mvn -q -B -DskipTests package

FROM eclipse-temurin:17-jre
WORKDIR /app
RUN useradd --system --uid 1001 cysvet
COPY --from=build /app/target/backend-0.0.1-SNAPSHOT.jar app.jar
USER cysvet
EXPOSE 8080
ENV SPRING_PROFILES_ACTIVE=prod \
    JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75"
ENTRYPOINT ["java", "-jar", "/app/app.jar"]

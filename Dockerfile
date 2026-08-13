# syntax=docker/dockerfile:1

FROM maven:3.9.11-eclipse-temurin-21 AS build

WORKDIR /workspace

COPY .mvn .mvn
COPY mvnw mvnw
COPY pom.xml pom.xml

COPY src src

RUN ./mvnw -q -DskipTests package


FROM eclipse-temurin:21-jre

WORKDIR /app

RUN groupadd --system spring \
    && useradd --system --gid spring spring

COPY --from=build /workspace/target/*.jar app.jar

ENV SERVER_PORT=8080

EXPOSE 8080

USER spring

ENTRYPOINT ["java", "-jar", "app.jar"]

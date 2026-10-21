# syntax=docker/dockerfile:1
FROM maven:3.9.6-eclipse-temurin-17-alpine AS builder

ARG STUDENT_ID
WORKDIR /build
COPY pom.xml ./
RUN mvn dependency:go-offline -B
COPY src/ ./src/
RUN test -n "$STUDENT_ID" && mvn package -DskipTests -B

FROM eclipse-temurin:17-jre-alpine AS runtime

ARG STUDENT_ID
ENV OPERATOR_ID=${STUDENT_ID} \
    JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75.0 -XX:InitialRAMPercentage=20.0 -XX:+UseSerialGC -Djava.security.egd=file:/dev/urandom"

RUN addgroup -S -g 10001 sensorgroup \
    && adduser -S -D -H -u 10001 -G sensorgroup sensor_user \
    && mkdir /app \
    && chown sensor_user:sensorgroup /app

WORKDIR /app
COPY --from=builder --chown=sensor_user:sensorgroup /build/target/eco-air-backend-1.0.0.jar /app/app.jar
USER sensor_user
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]

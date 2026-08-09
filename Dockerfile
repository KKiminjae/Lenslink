FROM eclipse-temurin:21-jdk AS builder

WORKDIR /app

COPY build.gradle .
COPY settings.gradle .
COPY gradlew .
COPY gradle gradle

RUN chmod +x gradlew

COPY src src

ARG GIT_COMMIT_SHA=unknown
ARG GIT_BRANCH=unknown

RUN printf 'git.commit.id=%s\ngit.branch=%s\n' \
    "$GIT_COMMIT_SHA" \
    "$GIT_BRANCH" \
    > src/main/resources/git.properties \
    && ./gradlew bootJar --no-daemon -PskipGitProperties

FROM eclipse-temurin:21-jre

WORKDIR /app

COPY --from=builder /app/build/libs/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java" ,"-jar", "app.jar"]
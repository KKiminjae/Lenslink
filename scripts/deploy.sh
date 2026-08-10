#!/usr/bin/env bash

set -euo pipefail

TARGET_IMAGE_TAG="${1:-}"

if [[ ! "${TARGET_IMAGE_TAG}" =~ ^sha-[0-9a-f]{7}$ ]]; then
  echo "Invalid image tag: ${TARGET_IMAGE_TAG}"
  echo "Expected format: sha-xxxxxxx"
  exit 1
fi

if [ ! -f .env ]; then
  echo ".env file not found."
  exit 1
fi

PREVIOUS_IMAGE_TAG="$(sed -n 's/^IMAGE_TAG=//p' .env | head -n 1)"

if [[ ! "${PREVIOUS_IMAGE_TAG}" =~ ^sha-[0-9a-f]{7}$ ]]; then
  echo "Could not determine valid previous IMAGE_TAG."
  exit 1
fi

echo "Previous image tag: ${PREVIOUS_IMAGE_TAG}"
echo "Target image tag: ${TARGET_IMAGE_TAG}"


set_image_tag() {
  local image_tag="$1"

  if ! grep -q '^IMAGE_TAG=' .env; then
    echo "IMAGE_TAG is missing from .env."
    return 1
  fi

  sed -i "s/^IMAGE_TAG=.*/IMAGE_TAG=${image_tag}/" .env
}


wait_for_health() {
  local attempt
  local health_response

  for ((attempt=1; attempt<=12; attempt++)); do
    health_response=$(curl -fsS --max-time 5 \
      https://lenslink.kro.kr/actuator/health || true)

    if echo "${health_response}" |
      grep -Eq '"status"[[:space:]]*:[[:space:]]*"UP"'; then
      echo "Application is healthy."
      return 0
    fi

    echo "Health check failed (${attempt}/12)"
    sleep 5
  done

  return 1
}

verify_version() {
  local image_tag="$1"
  local expected_sha="${image_tag#sha-}"
  local info_response

  if ! info_response=$(curl -fsS --max-time 5 \
    https://lenslink.kro.kr/actuator/info); then
    echo "Failed to retrieve actuator info."
    return 1
  fi

  echo "Expected SHA: ${expected_sha}"
  echo "Actuator info: ${info_response}"

  if ! echo "${info_response}" |
    grep -Eq "\"id\"[[:space:]]*:[[:space:]]*\"${expected_sha}"; then
    echo "Deployed version does not match expected SHA."
    return 1
  fi

  echo "Deployed version verified."
  return 0
}


rollback() {
  echo "Starting rollback to ${PREVIOUS_IMAGE_TAG}..."

  if ! set_image_tag "${PREVIOUS_IMAGE_TAG}"; then
    echo "Rollback failed: could not restore IMAGE_TAG."
    return 1
  fi

  if ! docker compose up -d --no-deps --pull never app; then
    echo "Rollback failed: could not start previous app."
    return 1
  fi

  echo "Waiting for rollback health..."

  if ! wait_for_health; then
    echo "Rollback failed: previous version is not healthy."
    docker compose logs --tail=100 app || true
    return 1
  fi

  if ! verify_version "${PREVIOUS_IMAGE_TAG}"; then
    echo "Rollback failed: previous version could not be verified."
    return 1
  fi

  echo "Rollback succeeded."
  return 0
}


deploy_target() {
  echo "Deploying ${TARGET_IMAGE_TAG}..."

  if ! set_image_tag "${TARGET_IMAGE_TAG}"; then
    echo "Deployment failed: could not update IMAGE_TAG."
    return 1
  fi

  if ! docker compose pull app; then
    echo "Deployment failed: could not pull target image."
    return 1
  fi

  if ! docker compose up -d --no-deps app; then
    echo "Deployment failed: could not start target app."
    return 1
  fi

  return 0
}


if ! deploy_target; then
  echo "Target deployment command failed."

  if ! rollback; then
    echo "CRITICAL: automatic rollback failed."
  fi

  exit 1
fi


echo "Waiting for application health..."

if ! wait_for_health; then
  echo "Application health check failed."

  docker compose logs --tail=100 app || true

  if ! rollback; then
    echo "CRITICAL: automatic rollback failed."
  fi

  exit 1
fi


echo "Verifying deployed version..."

if ! verify_version "${TARGET_IMAGE_TAG}"; then

  if ! rollback; then
    echo "CRITICAL: automatic rollback failed."
  fi

  exit 1
fi


echo "Deployment succeeded."
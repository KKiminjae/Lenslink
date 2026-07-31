# Architecture

## 프로젝트 목적

LensLink는 이미지를 업로드하면 AI가 상품 정보를 분석하고,
여러 쇼핑 플랫폼에서 동일하거나 유사한 상품을 검색하는 백엔드 프로젝트이다.

---

## 전체 흐름
```
Flutter
      │
      ▼
POST /api/searches/analyze
      │
      ▼
SearchController
      │
      ▼
SearchService
      │
      ▼
OpenAIService
      │
      ▼
AnalyzeResponse
      │
      ├──────────────┐
      ▼              │
SearchHistory 저장    │
(MySQL)              │
      │              │
      ▼              │
SearchPlatformService
      │
      ▼
NaverShoppingService
      │
      ├── SearchCandidateGenerator
      │       │
      │       ▼
      │   검색 후보 생성
      │
      ├── Naver Shopping API 호출
      │
      ├── SearchResultEvaluator
      │       │
      │       ▼
      │   검색 결과 평가
      │
      ▼
List<ProductResponse>
      │
      ▼
Flutter ResultPage
```

---


## 설계 목표

- 플랫폼별 검색 로직 분리
- 새로운 플랫폼 추가가 쉬운 구조
- SearchPlatform 인터페이스 기반 확장
- OpenAI와 검색 로직 분리
- 검색 후보 생성과 결과 평가 책임 분리
- 문자열 정규화 규칙을 공통으로 관리
- 공통 SearchResponse 반환
- SearchService에서 새상품과 중고 상품을 분리하여 프론트에 전달
- 검색 이력을 DB에 저장하여 추후 조회 및 분석 기능 확장 가능
- Pageable 기반 조회로 대량 데이터에도 확장 가능한 구조

---

## 핵심 컴포넌트

| 컴포넌트 | 역할 |
|----------|------|
| SearchService | 전체 검색 흐름을 조합하고 검색 이력을 저장 |
| SearchPlatform | 플랫폼별 검색 인터페이스 |
| SearchPlatformService | 등록된 플랫폼을 순회하며 검색 수행 |
| SearchCandidateGenerator | OpenAI 분석 결과를 기반으로 검색 후보 생성 |
| SearchNormalizer | 검색어와 검색 결과 문자열 정규화 |
| SearchResultEvaluator | 검색 결과의 품질을 평가하여 재검색 여부 결정 |
| SearchHistory | 검색 이력 저장 Entity |
| SearchHistoryService | 검색 이력 저장 및 조회 |
| SearchHistoryController | 검색 기록 조회 API 제공 |

## Recent Search API

## 전체 흐름

```
Flutter
        │
        ▼
GET /api/searches/history
        │
        ▼
SearchController
        │
        ▼
SearchHistoryService
        │
        ▼
SearchHistoryRepository
        │
        ▼
MySQL
        │
        ▼
Page<SearchHistory>
        │
        ▼
Page<SearchHistoryResponse>
        │
        ▼
JSON Response
```

### Recent Search API

#### GET /api/searches/history/recent

- 최근 검색 3건 조회
- Home 화면의 최근 검색 영역에서 사용

#### GET /api/searches/history

- 전체 검색 기록 조회
- Pageable 기반 페이지네이션
- 기본 30개 조회
- createdAt DESC 정렬

## Docker 환경 구성

### 목표

개발 환경과 Docker 환경을 분리하여 동일한 애플리케이션을 실행할 수 있도록 구성하였다.

또한 MySQL 데이터 영속성, 컨테이너 실행 순서, 환경별 설정 분리를 적용하여 운영 환경에 가까운 구조를 만들었다.

---

### 시스템 구조

IntelliJ(Local)

Spring Boot
│
localhost:3307
│
Docker MySQL

---

Docker Compose

Spring Container
│
mysql:3306
│
MySQL Container
│
Docker Volume

---

### 구성 요소

### Docker Volume

MySQL 데이터 디렉터리(`/var/lib/mysql`)를 Docker Named Volume과 연결하였다.

이를 통해 컨테이너가 삭제되더라도 데이터베이스 데이터는 유지된다.

---

### Health Check

MySQL 컨테이너가 실행되는 것만으로는 실제 DB 연결이 가능한 상태를 보장하지 않는다.

Health Check를 통해 MySQL이 정상적으로 준비된 이후에 Spring Boot가 실행되도록 구성하였다.

---

### Spring Profile

환경별 설정을 분리하기 위해 Spring Profile을 적용하였다.

application.yaml

공통 설정

application-local.yaml

IntelliJ 개발 환경

application-docker.yaml

Docker 실행 환경

환경에 따라 datasource 설정을 자동으로 선택하도록 구성하였다.

---

# CI/CD Architecture

## 전체 배포 흐름

```text
Developer
    │
git push (main)
    │
    ▼
GitHub Actions (CI)
    │
    ├─ Checkout
    ├─ JDK 설정
    ├─ Gradle Test
    ├─ Docker Image Build
    └─ GHCR Push
             │
             ▼
GitHub Actions (CD)
    │
    ├─ SSH to EC2
    ├─ docker compose pull
    └─ docker compose up -d
             │
             ▼
EC2
    │
Docker Container
    │
Spring Boot
    │
MySQL
```

## 구성 요소

- GitHub Actions : CI/CD 파이프라인
- GHCR : Docker 이미지 저장소
- EC2 : 서비스 실행 서버
- Docker Compose : 컨테이너 관리
- MySQL : 데이터베이스
---

## Spring Profile 구조

```
application.yaml
│
├──────────────┬──────────────┐
▼              ▼              ▼
application-local  application-docker  application-test
│              │               │
▼              ▼               ▼
localhost:3307     mysql:3306     localhost:3306
```

- local : 로컬 IntelliJ 실행
- docker : Docker Compose 실행
- test : GitHub Actions CI

---

# Nginx Reverse Proxy 구조

## 기존 구조

Browser

↓

Spring Boot (8080)

↓

MySQL

---

## 변경 후 구조

Browser

↓

Nginx (80)

↓

Spring Boot (8080)

↓

MySQL

---

## 요청 흐름

1. 사용자가 HTTP 요청을 보낸다.
2. Nginx가 80번 포트에서 요청을 수신한다.
3. Nginx가 Spring Boot(app:8080)로 요청을 전달한다.
4. Spring Boot가 비즈니스 로직을 처리한다.
5. 필요한 경우 MySQL에 접근한다.
6. 응답을 Nginx를 통해 사용자에게 반환한다.

---

## Docker Compose 구조

- nginx
    - 외부 요청 수신
    - Reverse Proxy 수행

- app
    - Spring Boot 애플리케이션
    - Docker 내부 네트워크에서만 접근(expose)

- mysql
    - 데이터 저장

Browser

↓

Spring Boot (8080)

↓

MySQL

---

## 변경 후 구조

Browser

↓

Nginx (80)

↓

Spring Boot (8080)

↓

MySQL

---

## 요청 흐름

1. 사용자가 HTTP 요청을 보낸다.
2. Nginx가 80번 포트에서 요청을 수신한다.
3. Nginx가 Spring Boot(app:8080)로 요청을 전달한다.
4. Spring Boot가 비즈니스 로직을 처리한다.
5. 필요한 경우 MySQL에 접근한다.
6. 응답을 Nginx를 통해 사용자에게 반환한다.

---

## Docker Compose 구조

- nginx
    - 외부 요청 수신
    - Reverse Proxy 수행

- app
    - Spring Boot 애플리케이션
    - Docker 내부 네트워크에서만 접근(expose)

- mysql
    - 데이터 저장

---

## 운영 환경 HTTPS 구조

LensLink 운영 환경은 Nginx가 외부 HTTPS 연결을 처리하고,
Spring Boot는 Docker 내부 네트워크에서 HTTP 요청을 처리한다.

```text
Client
  │
  │ HTTPS : 443
  ▼
lenslink.kro.kr
  │
  ▼
DNS A Record
  │
  ▼
Elastic IP
43.202.185.252
  │
  ▼
EC2
  │
  ▼
Nginx
  │
  │ HTTP : 8080
  ▼
Spring Boot
  │
  ▼
MySQL
```


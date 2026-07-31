# Troubleshooting

## 1.

### 문제

WebClient 요청 시

500 Internal Server Error

발생.

---

### 원인

브라우저 Header 부족.

---

### 해결

User-Agent

Accept

Referer

Accept-Language

추가.

HTML 수신 성공.

---

## 2.

### 문제

__NUXT_DATA__를 찾지 못함.

---

### 해결

HTML에서
```html
<script id = "__NUXT_DATA__">
 ```

추출 메서드 작성.

---


## 3.

### 문제

Nuxt 구조를 이해하기 어려움.

---

### 원인

Nuxt SSR Serialization.

Reference 기반 저장.

---

### 현재 상태

분석 진행 중.

## 4.

### 문제

무신사 API는 인증 및 내부 헤더(HMAC) 문제로 직접 호출이 어려움

---

### 해결

공식 NAVER Shopping Search API를 도입하여
안정적인 상품 검색 기능을 구현함.

---

### 배운 점

- WebClient를 이용한 외부 API 호출
- JSON → DTO 자동 변환
- DTO Mapping
- SearchPlatform 기반 확장 가능한 구조 설계

---

## 5.

### 문제

기존 SearchService와 SearchController는

List<ProductResponse>

를 반환하도록 구현되어 있었음.

SearchResponse를 도입하면서 반환 타입이 변경되어
Service와 Controller의 반환 타입이 서로 일치하지 않는 문제가 발생.

---

### 해결

SearchService의 반환 타입을 SearchResponse로 변경.

상품 검색 결과를

- newProducts
- usedProducts

로 분리한 뒤

SearchResponse에 담아 반환하도록 수정.

Controller 역시 반환 타입을 SearchResponse로 변경하여
API 응답 구조를 일치시킴.

## 6.

### 문제

Flutter에서 검색 결과를 파싱하는 과정에서 

```text
type 'int' is not a subtype of type 'String'
```

다음 오류가 발생하였다.

### 원인

Spring Boot의 ProductResponse는 price를 int로 반환하지만,
Flutter 모델은 String으로 선언되어 있었다.

### 해결

Flutter Product 모델의 price 타입을 int로 수정하고,
UI에서 문자열로 변환하여 출력하도록 변경하였다.

---

## 7.

### 문제

similarProducts.sort() 호출 시 다음 예외가 발생하였다.
```text
UnsupportedOperationException
```

### 원인

테스트 코드에서 List.of()를 사용하여 similarProducts를 생성하였다.

List.of()는 수정이 불가능한 Immutable List를 반환하므로 sort()를 호출할 수 없었다.

### 해결

정렬 전에 새로운 ArrayList를 생성하여 복사본을 만든 뒤 정렬하도록 수정하였다.

```java
List<AnalyzeResponse.SimilarProductResponse> similarProducts =
new ArrayList<>(analyzeResponse.getSimilarProducts());

similarProducts.sort(
Comparator.comparingInt(
AnalyzeResponse.SimilarProductResponse::getConfidence)
.reversed());
```

---

## 8.

### 문제

상품명이

```text
Nike Air Force 1
```

인데

예상 상품명이

```text
Air Force 1™
```

인 경우 검색 결과가 일치하지 않는 문제가 발생하였다.

또한 브랜드에 포함된

- ®
- ™

등의 특수문자 때문에 동일한 브랜드도 서로 다른 문자열로 인식하였다.

### 원인

단순 문자열 비교를 사용하고 있었기 때문이다.

### 해결

SearchNormalizer를 도입하여

- trim()
- toLowerCase()
- 특수문자 제거
- 공백 정규화

를 공통 적용하였다.

SearchCandidateGenerator와 SearchResultEvaluator 모두 동일한 정규화 규칙을 사용하도록 변경하였다.

---
## 9.

### 문제

검색 결과는 존재하지만 SearchResultEvaluator가 항상 false를 반환하였다.

로그

brandMatched=true

productMatched=false

원인

- OpenAI는 영문 상품명을 반환
- 네이버는 한글 상품명을 사용

또한 쇼핑몰마다 상품명 구성이 서로 달라 문자열 전체 비교가 실패하였다.

---

### 해결

1. OpenAI 프롬프트 수정

추가 필드

- brandKo
- productNameKo

2. SearchResultEvaluator 개선

- 영문/한글 브랜드 모두 비교
- 영문/한글 상품명 모두 비교
- 문자열 전체 비교 대신 토큰 기반 비교 적용

---

### 결과

brandMatched=true

productMatched=true

검색 품질이 개선되어 실제 검색 결과를 정상적으로 반환하였다.

___
## 10.

### 문제

검색 기록 저장 시 다음 오류가 발생하였다.
``` text
Field 'search_keyword' doesn't have a default value
```

### 원인 분석

원인 분석

ProductResponse.imageUrl

정상

SearchHistory.imageUrl

정상

Hibernate INSERT

정상 생성

MySQL에서 INSERT 실패

원인

Entity에서는 searchKeyword 필드를 삭제했지만 MySQL 테이블에는 search_keyword NOT NULL 컬럼이 그대로 남아 있었다.

Hibernate의 ddl-auto=update는 기존 컬럼을 자동으로 삭제하지 않는다.

### 해결

```sql
ALTER TABLE search_history
DROP COLUMN search_keyword;
``` 

### 배운점

* ddl-auto=update는 컬럼 삭제를 수행하지 않는다.
* 스키마 변경 시에는 직접 마이그레이션을 수행해야 한다.
* 로그를 API → DTO → Entity → Hibernate → DB 순서로 확인하면 원인을 빠르게 좁힐 수 있다.

---

## 11.

### 문제

Repository에서 Pageable을 사용하려고 했지만 오류가 발생하였다.

원인은 잘못된 import였다.

잘못된 코드

```java
import java.awt.print.Pageable;
```

---

## 11.

### 문제

IntelliJ에서 Spring Boot를 실행했을 때

UnknownHostException: mysql

오류가 발생하였다.

### 원인

Spring Boot는 Docker 밖(Mac)에서 실행되고 있었다.

하지만 datasource가

jdbc:mysql://mysql:3306

으로 설정되어 있었다.

mysql은 Docker Network 내부에서만 사용할 수 있는 서비스 이름이다.

### 해결

IntelliJ 실행 시

jdbc:mysql://localhost:3307

을 사용하도록 변경하였다.

Docker 실행 시에는

jdbc:mysql://mysql:3306

을 사용하도록 Spring Profile을 적용하였다.

---

## 2. 포트 충돌

### 문제

docker compose up 실행 시

Bind for 0.0.0.0:8080 failed

오류가 발생하였다.

### 원인

IntelliJ에서 실행 중인 Spring Boot가 이미 8080 포트를 사용하고 있었다.

Docker App 컨테이너도 동일한 포트를 사용하려고 하면서 충돌이 발생하였다.

### 해결

개발 단계에서는

- Spring Boot : IntelliJ 실행
- MySQL : Docker 실행

방식을 사용하였다.

---

## 3. 데이터가 삭제되는 문제

### 문제

docker compose down 이후

기존 검색 기록이 모두 사라졌다.

### 원인

MySQL 데이터가 컨테이너 내부에만 저장되고 있었다.

### 해결

Docker Named Volume을 적용하였다.

이후 컨테이너를 삭제하고 다시 생성해도 데이터가 유지되는 것을 확인하였다.

---

## 4. 환경별 datasource 변경

### 문제

Docker 실행과 IntelliJ 실행 시 datasource 주소가 달랐다.

매번 application.yaml을 수정해야 했다.

### 해결

application-local.yaml

application-docker.yaml

을 추가하고 Spring Profile을 적용하여 실행 환경에 따라 datasource를 자동으로 선택하도록 변경하였다.

---


## 12.

### 원인

GitHub Actions에는 MySQL이 존재하지 않아
Datasource 생성에 실패하였다.

### 해결

- GitHub Actions Service에 MySQL 추가
- application-test.yaml 생성
- SPRING_PROFILES_ACTIVE=test 적용

---

## 13.

### 원인

ports가 env 내부에 잘못 작성되어
Workflow YAML 파싱에 실패하였다.

### 해결

ports를 env 밖으로 이동하여
GitHub Actions 문법에 맞게 수정하였다.

---

## 14.

### 원인

GitHub Actions가 Local Profile을 사용하여
잘못된 Database 설정을 읽고 있었다.

### 해결

application-test.yaml을 생성하고

```yaml
env:
  SPRING_PROFILES_ACTIVE: test
```

를 적용하여 CI 환경에서 Test Profile을 사용하도록 수정하였다.

---

## 15.

curl http://localhost

실행 시

404 Not Found

### 원인

GET / 를 처리하는 Controller가 존재하지 않았다.

Reverse Proxy는 정상적으로 동작하고 있었으며,
Spring Boot가 404 응답을 반환한 것이다.

### 해결

실제 API

-> GET /api/searches/history
를 호출하여 Reverse Proxy가 정상 동작하는 것을 확인하였다.

---

## 16

### 증상

운영 Compose 실행 시 MySQL은 종료되고,
Spring Boot 앱은 재시작을 반복했으며 Nginx는 시작되지 않았다.

```text
lenslink-mysql   Exited (137)
lenslink-app     Restarting
lenslink-nginx   Created
```

Spring Boot 로그에는 다음 오류가 나타났다.

```text
Communications link failure
UnknownHostException: mysql
Unable to determine Dialect without JDBC metadata
```

### 초기 가설

- JDBC URL 누락
- 데이터베이스 비밀번호 불일치
- Docker 네트워크 설정 오류
- `mysql` 서비스명 DNS 해석 실패

### 확인 과정

컨테이너 상태를 확인했다.

```bash
docker inspect lenslink-mysql \
  --format='status={{.State.Status}} exit={{.State.ExitCode}} oom={{.State.OOMKilled}}'
```

결과:

```text
status=exited
exit=137
oom=true
```

EC2 메모리 상태도 확인했다.

```bash
free -h
```

EC2 RAM은 약 1GB였고 Swap은 설정되어 있지 않았다.

### 원인

EC2 메모리가 부족하여 Linux OOM Killer가
MySQL 프로세스를 강제 종료했다.

MySQL이 종료되면서 컨테이너의 네트워크 엔드포인트가 사라졌고,
Spring Boot가 `mysql` 서비스명을 해석하지 못했다.

```text
메모리 부족
→ MySQL OOM 종료
→ mysql 네트워크 주소 제거
→ Spring Boot DB 연결 실패
→ app unhealthy
→ nginx 시작 실패
```

Hibernate의 Dialect 오류는 최초 원인이 아니었다.

데이터베이스 연결 실패로 인해 DB 메타데이터를 읽지 못하면서
추가로 발생한 2차 오류였다.

### 해결

EC2에 2GB Swap을 추가했다.

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

재부팅 후에도 유지되도록 `/etc/fstab`에 다음 설정을 추가했다.

```text
/swapfile none swap sw 0 0
```

이후 Compose를 다시 실행하여
MySQL, Spring Boot, Nginx가 정상 상태가 되는 것을 확인했다.

### 운영 관점

Swap은 장애를 완화하는 안전장치이지
근본적인 성능 해결책은 아니다.

트래픽 증가 시 다음 대안을 검토해야 한다.

- RAM 2GB 이상 인스턴스로 변경
- MySQL을 RDS로 분리
- JVM Heap 크기 제한
- MySQL 메모리 설정 최적화
- 메모리 사용량 모니터링 및 알림 추가

---

## 17

### 증상

Spring Boot 애플리케이션은 실행됐지만
Docker health check가 계속 실패했다.

### 원인

Compose의 `app` 서비스는 `build:`가 아니라
원격 `image:`를 사용하고 있었다.

```yaml
image: ghcr.io/kkiminjae/linklink:latest
```

따라서 다음 명령의 `--build`는 앱 이미지를 새로 빌드하지 않았다.

```bash
docker compose up --build -d
```

로컬 Docker 또는 EC2에 남아 있던
이전 `latest` 이미지가 계속 사용됐다.

### 해결

최신 GHCR 이미지를 명시적으로 내려받았다.

```bash
docker compose -f compose.yaml pull
docker compose -f compose.yaml up -d
```

### 교훈

`build:` 서비스와 `image:` 서비스의 배포 방식은 다르다.

```text
build:
→ 로컬 Dockerfile로 이미지 생성

image:
→ 레지스트리에서 이미지 pull
```

`image:`만 사용하는 서비스는
`--build`만으로 최신 이미지가 갱신되지 않는다.

---

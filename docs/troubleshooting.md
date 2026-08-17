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

## 18

### 증상

Application 컨테이너를 강제 종료한 뒤 다음 상태가 확인됐다.

```text
lenslink-app Exited (137)
```

외부에서 Health API를 호출했을 때 Nginx는 실행 중이었지만 Application에 연결하지 못해 `HTTP 502`를 반환했다.

### 원인

종료 코드 `137`은 `SIGKILL`로 강제 종료됐음을 의미한다.

이번 테스트에서는 다음 명령으로 컨테이너를 직접 종료했다.

```bash
docker compose kill app
```

이 방식은 운영자가 Docker 명령으로 컨테이너를 명시적으로 중단한 상황이므로, 실제 JVM 크래시 상황과 동일하지 않다.

### 복구

다음 명령으로 Application 컨테이너를 수동 재시작했다.

```bash
docker compose up -d app
```

컨테이너가 시작된 직후에는 Spring Boot 초기화가 완료되지 않아 일시적으로 `HTTP 502`가 발생했다.

Spring Boot가 완전히 기동한 뒤 Health API는 `HTTP 200`으로 복구됐다.

### 확인 사항

* Docker 컨테이너 시작과 애플리케이션 준비 완료는 동일하지 않다.
* Nginx는 살아 있어도 upstream Application이 준비되지 않으면 `502 Bad Gateway`를 반환한다.
* `docker compose kill`은 자동 재시작 정책 검증에 적합하지 않았다.
* JVM 크래시나 OOM 기반 자동 재시작 테스트는 추후 별도로 수행한다.

---

## MySQL 컨테이너 장애 테스트

### 증상

MySQL 컨테이너를 중지한 상태에서 검색 기록 API를 호출했다.

```bash
docker compose stop mysql
```

DB를 사용하는 API는 응답까지 시간이 오래 걸렸고 최종적으로 `HTTP 500`을 반환했다.

Application 로그에서는 DB 연결 실패 관련 예외와 긴 스택트레이스가 확인됐다.

### 원인

MySQL이 중지된 상태에서 Application이 DB 커넥션 획득을 시도했다.

사용 가능한 커넥션을 얻지 못한 상태로 타임아웃까지 대기한 뒤 예외가 발생했다.

```text
API 요청
→ DB 커넥션 획득 시도
→ MySQL 연결 실패
→ 커넥션 타임아웃
→ HTTP 500
```

### 복구

MySQL 컨테이너를 다시 시작했다.

```bash
docker compose start mysql
```

MySQL이 `healthy` 상태가 된 뒤 동일 API를 다시 호출하자 `HTTP 200`으로 복구됐다.

Application 컨테이너는 재시작하지 않았다.

### 확인 사항

* MySQL이 중단돼도 Application 프로세스 자체는 계속 실행된다.
* DB 의존 API만 실패할 수 있다.
* MySQL 복구 후 HikariCP가 새 DB 연결을 확보해 Application 재시작 없이 정상화됐다.
* DB 장애 시 즉시 실패하지 않고 커넥션 타임아웃까지 대기해 사용자 응답이 늦어질 수 있다.

---

## 19

### 가벼운 API 반복 호출

검색 기록 API를 총 360회 호출하며 Application 컨테이너 메모리를 확인했다.

```text
부하 전:       190.7MiB
90회 후:       199.9MiB
180회 후:      206MiB
270회 후:      209MiB
360회 후:      217MiB
```

총 증가량은 약 `26.3MiB`였다.

요청 후 메모리는 즉시 감소하지 않았다.

이는 JVM이 확보한 힙 또는 네이티브 메모리를 운영체제에 바로 반환하지 않는 정상 동작일 수 있으므로, 해당 결과만으로 메모리 누수라고 판단하지 않았다.

### 실제 이미지 분석 API 호출

실제 이미지 분석 API를 1회 호출한 뒤 Application 컨테이너 메모리가 약 `312MiB`까지 증가했다.

```text
Application memory limit: 384MiB
관찰 메모리:             약 312MiB
사용률:                  약 81%
```

추가 요청 없이 기다려도 `docker stats` 기준 메모리는 크게 감소하지 않았다.

### 한계

`docker stats`는 다음 메모리를 합친 컨테이너 전체 사용량만 제공한다.

* JVM Heap
* Metaspace
* Direct Buffer
* Thread Stack
* JVM Native Memory

따라서 실제 Java 객체가 남아 있는지, JVM이 메모리만 확보해 둔 상태인지는 구분할 수 없다.

`/actuator/metrics/jvm.memory.used`는 `404`였고, 운영 컨테이너에는 `jcmd`가 포함돼 있지 않아 JVM 내부 메모리는 확인하지 못했다.

### 결론

* 가벼운 조회 API 반복 호출에서는 OOM이나 재시작이 발생하지 않았다.
* 실제 이미지 분석 요청은 조회 API보다 훨씬 큰 메모리를 사용했다.
* 현재 `384MiB` 제한은 단일 이미지 요청에서 약 81%까지 사용돼 운영 여유가 부족할 수 있다.
* 현재 EC2는 약 1GB 메모리이며 Swap도 사용 중이므로 Application 제한만 단순히 증가시키는 것은 적절하지 않다.
* 추후 이미지 크기 제한, 리사이징, 중복 `getBytes()` 및 Base64 생성 여부, 동시 요청 제한, JVM 내부 메트릭 수집을 검토한다.

---

## 20

각 컨테이너의 로그 설정을 `docker inspect`로 확인했다.

```text
driver=json-file
max-size=10m
max-file=3
```

로그 파일 하나는 최대 `10MB`, 최대 3개까지 유지된다.

이를 통해 Docker 로그의 무제한 증가와 EC2 디스크 고갈 위험을 줄였다.

단, 로그 발생량이 많으면 과거 로그가 빠르게 삭제될 수 있으므로 장기 보관이 필요할 경우 중앙 로그 수집 시스템이 필요하다.

---

## 21

Ubuntu 사용자 Cron에 다음 작업이 등록된 것을 확인했다.

```text
매일 03:00
→ Certbot renew 실행
→ 명령 성공 시 Nginx reload
```

다음 명령으로 인증서 모의 갱신을 검증했다.

```bash
docker compose run --rm certbot renew --dry-run
```

또한 `openssl s_client`로 현재 외부에 제공되는 인증서의 subject, issuer, 유효 시작일 및 만료일을 확인했다.

이번 작업에서는 Cron을 새로 구성한 것이 아니라, 기존 자동 갱신 구성을 확인하고 검증했다.


---

## 22

### 테스트 DB 미실행

MySQL이 꺼져 있으면 `contextLoads()`에서 Hibernate가 Dialect를 결정하지 못해 테스트가 실패했다.

```bash
docker compose \
  -f compose.yaml \
  -f compose.local.yaml \
  up -d mysql
```

MySQL이 `healthy` 상태가 된 후 전체 테스트가 통과했다.

장기적으로는 로컬 Docker 상태에 의존하지 않도록 Testcontainers 적용을 검토한다.

### 로컬 코드 미반영

Docker 이미지를 재빌드하지 않으면 변경된 코드가 컨테이너에 반영되지 않았다.

```bash
docker compose \
  -f compose.yaml \
  -f compose.local.yaml \
  up -d --build
```

### `expose`와 `ports`

* `expose`: 컨테이너 간 통신용
* `ports`: 호스트에서 컨테이너로 직접 접근할 때 사용

운영에서는 app 포트를 외부에 공개하지 않고, 로컬 환경에서만 `8080:8080`을 사용한다.

---

## 23
## 로컬 빌드 시 Java 26 / Gradle 호환성 문제

### 증상

```text
Unsupported class file major version 70
```

### 해결

Gradle 실행 JVM을 Java 21로 변경했다.
```text
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
export PATH="$JAVA_HOME/bin:$PATH"

./gradlew --stop
./gradlew --version
```
Gradle Launcher/Daemon JVM이 Java 21인 것을 확인 후 
빌드를 다시 수행했다.

### 교훈

빌드 오류 발생 시 다음을 함께 확인한다.

```text
java -version
./gradlew --version
```

---

## 24
## IntelliJ 로컬 실행 시 환경변수 미주입

### 증상
Spring Boot를 IntelliJ에서 직접 실행했을 때
DB 계정 및 외부 API Key placeholder를 해석하지 못해 시작에 실패했다.

예:

```text
Access denied for user '${SPRING_DATASOURCE_USERNAME}'
Could not resolve placeholder 'OPEN_API_KEY'
Could not resolve placeholder 'NAVER_CLIENT_ID'
```

### 원인

.env는 Docker compose가 읽는 파일이며,
IntelliJ에서 직접 실행한 Java 프로세스가 자동으로 읽지 않는다.

### 해결

IntelliJ의 LenslinkApplication Run Configuration에
로컬 실행에 필요한 환경변수를 등록했다.

### 교훈
```text
Docker Compose 실행
→ .env 사용

IntelliJ 직접 실행
→ Run Configuration의 환경변수 사용
```

---

## 25
## Docker 빌드에서 Git repository를 찾지 못하는 문제

### 증상

```text
No Git repository found.

```

### 원인

gradle-git-properties는 .git 정보를 사용하지만
Docker builder에는 .git 디렉터리를 복사하지 않는다.

### 해결

.git 전체를 Docker에 복사하지 않고,
GitHub Actions의 commit SHA와 branch를 Docker build argument로 전달했다.

Docker 내부에서는 전달받은 값으로 git.properties를 생성하고
generateGitProperties task를 비활성화했다.

### 교훈

빌드 metadata는 소스 저장소 구조에 암묵적으로 의존하기보다
CI가 알고 있는 배포 식별자를 명시적으로 artifact에 전달하는 편이
운영 추적성이 높다.

---

## 26
## GitHub Actions OIDC AssumeRole 실패

### 증상

`configure-aws-credentials`에서 다음 오류 발생:

`Not authorized to perform sts:AssumeRoleWithWebIdentity`

### 원인

IAM Trust Policy에 설정한 OIDC `sub`와
GitHub가 실제 발급한 `sub`가 일치하지 않았다.

예상:

repo:KKiminjae/Lenslink:ref:refs/heads/main

실제:

repo:KKiminjae@249421065/Lenslink@1295061276:ref:refs/heads/main

### 확인 방법

임시 GitHub Actions step에서 OIDC JWT의
aud, sub, repository_id, repository_owner_id 등을 확인했다.

### 해결

IAM Trust Policy의 `sub` 조건을 실제 GitHub OIDC subject로 수정했다.

### 결과

- Configure AWS credentials 성공
- LensLinkGitHubDeployRole Assume 성공
- AWS Account 검증 성공

---

## 27
## SSM Run Command 줄바꿈 소실

### 문제

SSM 기반 CD 첫 실행에서 `Wait for deployment`가 실패했다.

```text
bash: -c: line 1: syntax error near unexpected token `then'
```

실제 전달된 명령은 다음처럼 여러 명령이 붙어 있었다.

```text
set -euo pipefailcd /home/ubuntu/LensLinkgit fetch origin mainif ...
```

### 원인

`REMOTE_COMMAND`를 여러 줄 문자열로 전달했는데, SSM을 거치는 과정에서 줄바꿈이 명령 구분자로 유지되지 않았다.

### 해결

원격 명령마다 `;`를 명시하여 줄바꿈이 제거되어도 Bash 문법이 유지되도록 수정했다.

```bash
set -euo pipefail;
cd /home/ubuntu/LensLink;
git fetch origin main;

if ...; then
  ...
fi;

git checkout --detach "${DEPLOY_SHA}";
./scripts/deploy.sh "${IMAGE_TAG}";
```

### 검증

수정 후 실제 SSM CD가 정상 성공했고 다음 값이 모두 일치했다.

```text
EC2 Git HEAD   = a72850e
IMAGE_TAG      = sha-a72850e
/actuator/info = a72850e
health         = UP
```

존재하지 않는 이미지 태그를 사용한 rollback 테스트에서도 이전 정상 버전으로 복구되는 것을 확인했다.

### 배운 점

원격 shell 명령을 문자열로 전달할 때는 줄바꿈 보존을 가정하지 말고 명령 구분자를 명시적으로 관리해야 한다.
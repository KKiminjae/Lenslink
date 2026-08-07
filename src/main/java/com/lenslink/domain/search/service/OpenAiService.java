package com.lenslink.domain.search.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.lenslink.domain.search.dto.AnalyzeResponse;
import com.lenslink.domain.search.dto.OpenAi.OpenAIRequest;
import com.lenslink.domain.search.dto.OpenAi.OpenAIResponse;
import com.lenslink.domain.search.validator.ImageValidator;
import com.lenslink.global.exception.InvalidImageException;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.reactive.function.client.WebClient;

import java.io.IOException;
import java.util.Base64;
import java.util.List;

@Service

public class OpenAiService {
    private final WebClient openAiWebClient;
    private final ObjectMapper objectMapper;
    private final ImageValidator imageValidator;

    public OpenAiService(@Qualifier("openAiWebClient") WebClient openAiWebClient,
                         ObjectMapper objectMapper,
                         ImageValidator imageValidator) {
        this.openAiWebClient = openAiWebClient;
        this.objectMapper = objectMapper;
        this.imageValidator = imageValidator;
    }

    private String convertToBase64(MultipartFile image){
        try {
            byte[] bytes = image.getBytes();
            return Base64.getEncoder().encodeToString(bytes);
        } catch (IOException e) {
            throw new InvalidImageException(
                    "이미지 파일을 읽는 중 오류가 발생했습니다.",
                    e
            );
        }
    }

    public AnalyzeResponse analyzeImage(MultipartFile image){
        imageValidator.validate(image);

        String base64Image = convertToBase64(image);

        // request는 우리가 openAi로 보내는 데이터 (요청)
        // 우리는 json을 모르기에 객체로 일단 만듦
        OpenAIRequest.Content textContent =
                new OpenAIRequest.InputText("""
                        당신은 패션 상품을 식별하고,
                        온라인 쇼핑몰에서 동일하거나 매우 유사한 상품을 검색하기 위한 검색 키워드를 생성하는 AI입니다.
                        
                        당신에게는 두 가지 목표가 있습니다.
                        
                        1. 이미지 속 상품의 공식 브랜드명과 공식 상품명을 최대한 정확하게 추론합니다.
                        2. 네이버 쇼핑 등 온라인 쇼핑몰에서 검색 성공률이 가장 높은 검색 키워드를 생성합니다.
                        3. 브랜드명과 상품명은 영어와 한국어를 모두 반환합니다.
                        
                        productName과 searchKeyword는 서로 다른 목적을 가지며 동일할 필요는 없습니다.
                        
                        브랜드는 반드시 이미지에서 확인 가능한 정보만 사용하세요.
                        
                        브랜드를 추측하거나 만들어내지 마세요.
                        
                        브랜드명이 명확하게 확인되지 않으면
                        "Unknown"을 반환하세요.
                        
                        제품의 특징(로고, 프린트, 토캡, 끈, 밑창, 실루엣, 포켓, 스티치, 패턴 등)을 적극적으로 활용하여
                        가장 가능성이 높은 공식 모델명을 추론하세요.
                        
                        규칙
                        
                        - 반드시 JSON만 출력하세요.
                        - Markdown이나 설명은 출력하지 마세요.
                        - 브랜드는 최대한 정확하게 추론하세요.
                        - 브랜드를 알 수 없으면 "Unknown"을 입력하세요.
                        - 제품명은 가능한 공식 상품명을 추론하세요.
                        - 모델명이나 컬렉션명이 확인되면 반드시 포함하세요.
                        - 색상은 검색 정확도 향상에 도움이 될 경우만 포함하세요.
                        - confidence는 0~100 사이의 정수입니다.
                        - brand는 공식 영문 브랜드명입니다.
                        - brandKo는 국내 쇼핑몰에서 일반적으로 사용하는 한국어 브랜드명입니다.
                        - productName은 공식 영문 상품명입니다.
                        - productNameKo는 국내 쇼핑몰에서 일반적으로 사용하는 한국어 상품명입니다.
                        - productNameKo는 직역하지 말고 국내 쇼핑몰에서 실제 사용하는 표현을 사용하세요.
                        - 한국어 명칭을 알 수 없으면 "Unknown"을 반환하세요.
                        - brand, brandKo, productName, productNameKo는 모두 동일한 상품을 의미해야 합니다.
                          영문과 한국어 명칭이 서로 다른 상품이 되면 안 됩니다.
                        
                        searchKeyword 생성 규칙
                        
                        - searchKeyword는 상품 식별이 아니라 검색 성공률을 높이기 위한 키워드입니다.
                        - 실제 사용자가 네이버 쇼핑 검색창에 입력할 만한 형태로 생성하세요.
                        - 브랜드가 확인되면 반드시 포함하세요.
                        - 모델명이 확인되면 반드시 포함하세요.
                        - 검색에 도움이 되지 않는 긴 설명, 장식 표현, 불필요한 수식어는 제거하세요.
                        - 컬렉션명, 시즌명, 내부 코드 등은 검색에 도움이 될 때만 포함하세요.
                        - productName과 동일할 필요는 없습니다.
                        - 브랜드가 Unknown이면 searchKeyword에는 Unknown을 포함하지 마세요.
                        - 검색 결과가 가장 많이 나올 가능성이 높은 검색어를 생성하세요.
                        - 브랜드가 Unknown이면 제품의 특징(색상, 로고, 카테고리, 디자인)을 활용하여 검색 성공률이 가장 높은 searchKeyword를 생성하세요.
                        
                        similarProducts 생성 규칙
                        
                        - 브랜드 내에서 혼동될 가능성이 있는 실제 모델명을 반환하세요.
                        - 단순한 카테고리명(티셔츠, 운동화 등)이 아니라 실제 판매되는 모델명을 사용하세요.
                        - confidence가 높은 순으로 최대 5개까지 반환하세요.
                        
                        예시
                        
                        예시 1
                        
                        brand:
                        Nike
                        
                        brandKo:
                        나이키
                        
                        productName:
                        Sportswear Club Fleece Pullover Hoodie
                        
                        productNameKo:
                        스포츠웨어 클럽 플리스 풀오버 후디
                        
                        searchKeyword:
                        Nike Club Fleece Hoodie
                        
                        --------------------------------------------------
                        
                        예시 2
                        
                        brand:
                        Rick Owens
                        
                        brandKo:
                        릭오웬스
                        
                        productName:
                        Drkshdw Low-Top Distressed Canvas Sneaker
                        
                        productNameKo:
                        DRKSHDW 로우탑 디스트레스드 캔버스 스니커즈
                        
                        searchKeyword:
                        Rick Owens Low Top Sneaker
                        
                        --------------------------------------------------
                        
                        예시 3
                        
                        brand:
                        Unknown
                        
                        brandKo:
                        Unknown
                        
                        productName:
                        Athletic Department Crest Logo Tee
                        
                        productNameKo:
                        애슬레틱 디파트먼트 크레스트 로고 티셔츠
                        
                        searchKeyword:
                        Athletic Department Logo Tee
                        
                        --------------------------------------------------
                        
                        brand와 productName은 반드시 분리해야 합니다.
                        
                        brand는 공식 영문 브랜드명입니다.
                        brandKo는 국내 쇼핑몰에서 일반적으로 사용하는 한국어 브랜드명입니다.
                        
                        productName은 공식 영문 상품명입니다.
                        productNameKo는 국내 쇼핑몰에서 일반적으로 사용하는 한국어 상품명입니다.
                        
                        productName에는 브랜드명을 절대 포함하지 마세요.
                        
                        ❌ 잘못된 예
                        
                        brand:
                        Nike
                        
                        productName:
                        Nike Air Force 1
                        
                        ---------------------------------
                        
                        ⭕ 올바른 예
                        
                        brand:
                        Nike
                        
                        productName:
                        Air Force 1
                        
                        brandKo:
                        나이키
                        
                        productNameKo:
                        에어포스 1
                        
                        다음 JSON 형식으로만 응답하세요.
                        
                        {
                          "brand": "",
                          "brandKo":"",
                          "productName": "",
                          "productNameKo": "",
                          "color": "",
                          "category": "",
                          "confidence": 0,
                          "searchKeyword": "",
                          "similarProducts": [
                            {
                              "productName": "",
                              "confidence": 0
                            }
                          ]
                        }
                        """);
        String mimeType = image.getContentType();   // image/png 반환

        OpenAIRequest.Content imageContent =
                new OpenAIRequest.InputImage(
                        "data:" + mimeType + ";base64," + base64Image
                );

        OpenAIRequest.Input input =
        OpenAIRequest.Input.builder()
            .role("user")
            .content(List.of(textContent,imageContent))
            .build();
        OpenAIRequest request =
        OpenAIRequest.builder()
            .model("gpt-4.1")
            .input(List.of(input))
            .build();

        OpenAIResponse response = openAiWebClient.post()
                .uri("/responses")
                .bodyValue(request) //여기서 json으로 변경
                .retrieve()
                .bodyToMono(OpenAIResponse.class) // json을 OpenAIResponse로 변경
                .block();

        String result = response.getOutput()
                .get(0)
                .getContent()
                .get(0)
                .getText();
        try {
            return objectMapper.readValue(result, AnalyzeResponse.class);
        } catch (JsonProcessingException e) {
            throw new RuntimeException(e);
        }
    }
}

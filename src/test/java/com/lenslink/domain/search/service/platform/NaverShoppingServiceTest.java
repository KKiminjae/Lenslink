package com.lenslink.domain.search.service.platform;

import com.lenslink.domain.search.dto.AnalyzeResponse;
import com.lenslink.domain.search.dto.ProductResponse;
import com.lenslink.domain.search.service.candidate.SearchCandidateGenerator;
import com.lenslink.domain.search.service.evaluator.SearchResultEvaluator;
import okhttp3.mockwebserver.MockResponse;
import okhttp3.mockwebserver.MockWebServer;
import okhttp3.mockwebserver.RecordedRequest;
import org.assertj.core.api.Assertions;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.reactive.function.client.WebClient;

import java.io.IOException;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class NaverShoppingServiceTest {
    private MockWebServer mockWebServer; //naver에서 받아온 서버 대체
    private NaverShoppingService naverShoppingService;
    @Mock
    private SearchResultEvaluator searchResultEvaluator;
    @Mock
    private SearchCandidateGenerator candidateGenerator;

    @BeforeEach
    void setUp() throws IOException {
        mockWebServer = new MockWebServer();
        mockWebServer.start();

        WebClient webClient = WebClient.builder()
                .baseUrl(mockWebServer.url("/").toString())
                .build();

        naverShoppingService = new NaverShoppingService(webClient,searchResultEvaluator,candidateGenerator);
    }
    @AfterEach
    void tearDown() throws IOException {
        mockWebServer.shutdown();
    }
    @Test
    void search() throws InterruptedException {
        String json = """
                {
                  "items":[
                    {
                      "title":"<b>Nike</b> T-Shirt",
                      "brand":"Nike",
                      "mallName":"ABC Mall",
                      "lprice":"39000",
                      "link":"https://test.com",
                      "image":"https://image.com",
                      "productType":"1"
                    }
                  ]
                }
                """;
        mockWebServer.enqueue(
                new MockResponse()
                        .setResponseCode(200)
                        .setHeader("Content-Type", "application/json")
                        .setBody(json)
        );
        AnalyzeResponse analyzeResponse = AnalyzeResponse.builder()
                .brand("Nike")
                .productName("T-shirt")
                .build();

        when(candidateGenerator.createCandidates(any()))
                .thenReturn(List.of("Nike"));
        when(searchResultEvaluator.isGoodResult(any(), any()))
                .thenReturn(true);

        List<ProductResponse> result = naverShoppingService.search(analyzeResponse);
        Assertions.assertThat(result).hasSize(1);

        ProductResponse product = result.get(0);

        Assertions.assertThat(product.getBrand()).isEqualTo("Nike");
        Assertions.assertThat(product.getPrice()).isEqualTo(39000);
        Assertions.assertThat(product.getMall()).isEqualTo("ABC Mall");
        Assertions.assertThat(product.getProductName()).isEqualTo("Nike T-Shirt");

        RecordedRequest request = mockWebServer.takeRequest();

        Assertions.assertThat(request.getMethod()).isEqualTo("GET");
        Assertions.assertThat(request.getPath()).contains("/v1/search/shop.json");
        Assertions.assertThat(request.getPath()).contains("query=Nike");

    }
    @Test
    void search_emptyList_error(){
        mockWebServer.enqueue(
                new MockResponse()
                        .setResponseCode(500)
        );
        AnalyzeResponse analyzeResponse = AnalyzeResponse.builder()
                .brand("Nike")
                .productName("T-Shirt")
                .build();
        when(candidateGenerator.createCandidates(any()))
                .thenReturn(List.of("Nike"));
        List<ProductResponse> result = naverShoppingService.search(analyzeResponse);
        Assertions.assertThat(result).isEmpty();
    }
}
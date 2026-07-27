package com.lenslink.domain.search.service.candidate;

import com.lenslink.domain.search.dto.AnalyzeResponse;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.*;

class SearchCandidateGeneratorTest {

    private SearchCandidateGenerator generator;

    @BeforeEach
    void set_Up(){
        generator = new SearchCandidateGenerator();
    }

    @Test
    void 검색후보를_우선순위대로_생성한다() {

        AnalyzeResponse analyzeResponse =
                AnalyzeResponse.builder()
                        .brand("Nike")
                        .productName("Air Force 1")
                        .similarProducts(List.of(
                                AnalyzeResponse.SimilarProductResponse.builder()
                                        .productName("Air Force 1 '07")
                                        .confidence(95)
                                        .build(),

                                AnalyzeResponse.SimilarProductResponse.builder()
                                        .productName("Air Force Low")
                                        .confidence(82)
                                        .build()
                        ))
                        .build();

        List<String> candidates =
                generator.createCandidates(analyzeResponse);

        assertEquals(
                List.of(
                        "air force 1",
                        "air force 1 07",
                        "air force low",
                        "nike air force 1"
                ),
                candidates
        );
    }

    @Test
    void confidence가_낮은후보는_제외(){
        AnalyzeResponse analyzeResponse =
                AnalyzeResponse.builder()
                        .brand("Nike")
                        .productName("Air Force 1")
                        .similarProducts(List.of(

                                AnalyzeResponse.SimilarProductResponse.builder()
                                        .productName("Air Force Low")
                                        .confidence(90)
                                        .build(),

                                AnalyzeResponse.SimilarProductResponse.builder()
                                        .productName("Nike Dunk")
                                        .confidence(50)
                                        .build()
                        ))
                        .build();
        List<String> candidates = generator.createCandidates(analyzeResponse);
        assertFalse(candidates.contains("Nike Dunk"));
    }

    @Test
    void Unknown은_검색후보x(){
        AnalyzeResponse analyzeResponse =
                AnalyzeResponse.builder()
                        .brand("Unknown")
                        .productName("Unknown")
                        .build();
        List<String> candidates = generator.createCandidates(analyzeResponse);
        assertTrue(candidates.isEmpty());
    }

    @Test
    void 중복제거(){
        AnalyzeResponse analyzeResponse =
                AnalyzeResponse.builder()
                        .brand("Nike")
                        .productName("Air Force 1")
                        .similarProducts(List.of(

                                AnalyzeResponse.SimilarProductResponse.builder()
                                        .productName("Air Force 1")
                                        .confidence(95)
                                        .build()
                        ))
                        .build();
        List<String> candidates = generator.createCandidates(analyzeResponse);
        assertThat(candidates.size()).isEqualTo(2);
        assertEquals(List.of("air force 1", "nike air force 1"),candidates);
    }

    @Test
    void 특수문자변환체크(){
        AnalyzeResponse analyzeResponse =
                AnalyzeResponse.builder()
                        .brand(" Nike® ")
                        .productName("Air Force 1")
                        .build();
        List<String> candidates = generator.createCandidates(analyzeResponse);
        assertEquals(List.of("air force 1", "nike air force 1"), candidates);
    }


}
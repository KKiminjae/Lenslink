package com.lenslink.domain.search.service;

import com.lenslink.domain.search.dto.AnalyzeResponse;
import com.lenslink.domain.search.dto.ProductResponse;
import com.lenslink.domain.search.dto.SearchResponse;
import com.lenslink.domain.search.entity.SearchHistory;
import com.lenslink.domain.search.repository.SearchHistoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class SearchService {

    private final OpenAiService openAiService;

    private final SearchPlatformService searchPlatformService;

    private final SearchHistoryRepository repository;

    public SearchResponse search(MultipartFile image){

        AnalyzeResponse analyzeResponse = openAiService.analyzeImage(image);

        List<ProductResponse> products = searchPlatformService.search(analyzeResponse);

        if(!products.isEmpty()){
            SearchHistory history = createSearchHistory(analyzeResponse, products.get(0));
            repository.save(history);
        }

        List<ProductResponse> newProducts = products.stream()
                .filter(product -> !product.isUsed())
                .toList();
        List<ProductResponse> usedProducts = products.stream()
                .filter(ProductResponse::isUsed)
                .toList();
        return new SearchResponse(
                analyzeResponse,
                newProducts,
                usedProducts
        );
    }

    private SearchHistory createSearchHistory(AnalyzeResponse analyzeResponse, ProductResponse product){
        return SearchHistory.builder()
                .brand(analyzeResponse.getBrand())
                .productName(analyzeResponse.getProductName())
                .imageUrl(product.getImageUrl())
                .build();
    }
}

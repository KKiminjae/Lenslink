package com.lenslink.domain.search.validator;

import com.lenslink.global.exception.InvalidImageException;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import javax.imageio.ImageIO;
import javax.imageio.ImageReader;
import javax.imageio.stream.ImageInputStream;
import java.io.IOException;
import java.util.Iterator;
import java.util.Locale;
import java.util.Set;

@Component
public class ImageValidator {

    private static final int MAX_WIDTH = 4096;
    private static final int MAX_HEIGHT = 4096;

    private static final Set<String> ALLOWED_FORMATS =
            Set.of("jpeg", "jpg", "png");

    public void validate(MultipartFile image) {
        validateNotEmpty(image);

        try (ImageInputStream imageInputStream =
                     ImageIO.createImageInputStream(image.getInputStream())) {

            if (imageInputStream == null) {
                throw new InvalidImageException("이미지 파일을 읽을 수 없습니다.");
            }

            Iterator<ImageReader> readers =
                    ImageIO.getImageReaders(imageInputStream);

            if (!readers.hasNext()) {
                throw new InvalidImageException(
                        "지원되지 않거나 손상된 이미지 파일입니다."
                );
            }

            ImageReader reader = readers.next();

            try {
                reader.setInput(imageInputStream, true, true);

                validateFormat(reader);
                validateDimensions(reader);
            } finally {
                reader.dispose();
            }

        } catch (InvalidImageException e) {
            throw e;
        } catch (IOException e) {
            throw new InvalidImageException(
                    "이미지 파일을 처리하는 중 오류가 발생했습니다.",
                    e
            );
        }
    }

    private void validateNotEmpty(MultipartFile image) {
        if (image == null || image.isEmpty()) {
            throw new InvalidImageException(
                    "이미지 파일은 비어 있을 수 없습니다."
            );
        }
    }

    private void validateFormat(ImageReader reader) throws IOException {
        String formatName =
                reader.getFormatName().toLowerCase(Locale.ROOT);

        if (!ALLOWED_FORMATS.contains(formatName)) {
            throw new InvalidImageException(
                    "JPEG 또는 PNG 이미지만 업로드할 수 있습니다."
            );
        }
    }

    private void validateDimensions(ImageReader reader) throws IOException {
        int width = reader.getWidth(0);
        int height = reader.getHeight(0);

        if (width <= 0 || height <= 0) {
            throw new InvalidImageException(
                    "유효하지 않은 이미지 해상도입니다."
            );
        }

        if (width > MAX_WIDTH || height > MAX_HEIGHT) {
            throw new InvalidImageException(
                    "이미지 해상도는 최대 4096×4096까지 허용됩니다."
            );
        }
    }
}
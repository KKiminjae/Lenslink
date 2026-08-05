package com.lenslink.domain.search.validator;

import com.lenslink.global.exception.InvalidImageException;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;

import static org.assertj.core.api.Assertions.*;


class ImageValidatorTest {

    private final ImageValidator imageValidator = new ImageValidator();

    @Test
    void 빈_파일이면_예외가_발생(){
        MockMultipartFile image = new MockMultipartFile(
                "image", "empty.png", "image/png", new byte[0]
        );
        assertThatThrownBy(() -> imageValidator.validate(image))
                .isInstanceOf(InvalidImageException.class)
                .hasMessage("이미지 파일은 비어 있을 수 없습니다.");
    }

    @Test
    void 확장자와_ContentType만_PNG인_가짜이미지(){
        MockMultipartFile image = new MockMultipartFile(
                "image", "fake.png", "image/png", "not real png".getBytes()
        );
        assertThatThrownBy(() -> imageValidator.validate(image))
                .isInstanceOf(InvalidImageException.class)
                .hasMessage("지원되지 않거나 손상된 이미지 파일입니다.");
    }
    @Test
    void 정상_JPEG_이미지는_허용() throws Exception {
        byte[] imageBytes = createImageBytes("jpg", 100, 100);
        MockMultipartFile image = new MockMultipartFile(

                "image", "test.png", "image/png", imageBytes
        );
        assertThatCode(() -> imageValidator.validate(image))
                .doesNotThrowAnyException();
    }

    @Test
    void 정상_PNG_이미지는_허용() throws Exception {
        byte[] imageBytes = createImageBytes("png", 100, 100);
        MockMultipartFile image = new MockMultipartFile(
                "image", "test.png", "image/png", imageBytes
        );
        assertThatCode(() -> imageValidator.validate(image))
                .doesNotThrowAnyException();
    }

    private byte[] createImageBytes(String format, int width, int height) throws Exception {
        BufferedImage bufferedImage =
                new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);

        try (ByteArrayOutputStream outputStream =
                     new ByteArrayOutputStream()) {

            boolean written = ImageIO.write(
                    bufferedImage,
                    format,
                    outputStream
            );

            if (!written) {
                throw new IllegalStateException(
                        "테스트 이미지 생성 실패: " + format
                );
            }

            return outputStream.toByteArray();
        }
    }
    @Test
    void 최대_가로해상도는_허용() throws Exception {
        byte[] imageBytes = createImageBytes("png", 4096, 1);

        MockMultipartFile image = new MockMultipartFile(
                "image",
                "max-width.png",
                "image/png",
                imageBytes
        );
        assertThatCode(() -> imageValidator.validate(image))
                .doesNotThrowAnyException();
    }
    @Test
    void 최대_세로도_허용() throws Exception {
        byte[] imageBytes = createImageBytes("png", 1, 4096);

        MockMultipartFile image = new MockMultipartFile(
                "image",
                "max-width.png",
                "image/png",
                imageBytes
        );
        assertThatCode(() -> imageValidator.validate(image))
                .doesNotThrowAnyException();
    }
    @Test
    void 최대_가로초과() throws Exception {
        byte[] imageBytes = createImageBytes("png", 4097, 1);

        MockMultipartFile image = new MockMultipartFile(
                "image",
                "max-width.png",
                "image/png",
                imageBytes
        );
        assertThatThrownBy(() -> imageValidator.validate(image))
                .isInstanceOf(InvalidImageException.class)
                .hasMessage( "이미지 해상도는 최대 4096×4096까지 허용됩니다.");
    }
    @Test
    void 최대_세로초과() throws Exception {
        byte[] imageBytes = createImageBytes("png", 1, 4097);

        MockMultipartFile image = new MockMultipartFile(
                "image",
                "max-width.png",
                "image/png",
                imageBytes
        );
        assertThatThrownBy(() -> imageValidator.validate(image))
                .isInstanceOf(InvalidImageException.class)
                .hasMessage( "이미지 해상도는 최대 4096×4096까지 허용됩니다.");
    }


}
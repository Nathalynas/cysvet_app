package com.cysvet.backend.exception;

import com.cysvet.backend.config.AppProperties;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.TypeMismatchException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.ErrorResponse;
import org.springframework.web.HttpMediaTypeException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.ServletRequestBindingException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.multipart.support.MissingServletRequestPartException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

@Slf4j
@RestControllerAdvice
@RequiredArgsConstructor
public class GlobalExceptionHandler {

    private static final String GENERIC_SERVER_ERROR_MESSAGE = "Erro interno no servidor";
    private static final String GENERIC_BAD_REQUEST_MESSAGE = "Dados invalidos";
    private static final String INVALID_CREDENTIALS_MESSAGE = "E-mail ou senha invalidos";

    private final AppProperties appProperties;

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleNotFound(ResourceNotFoundException exception) {
        return buildResponse(HttpStatus.NOT_FOUND, exception.getMessage());
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, Object>> handleBadRequest(RuntimeException exception) {
        return buildResponse(HttpStatus.BAD_REQUEST, exception.getMessage());
    }

    // Mensagem unica para nao revelar se o e-mail existe.
    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<Map<String, Object>> handleAuthentication(AuthenticationException exception) {
        return buildResponse(HttpStatus.UNAUTHORIZED, INVALID_CREDENTIALS_MESSAGE);
    }

    @ExceptionHandler(TypeMismatchException.class)
    public ResponseEntity<Map<String, Object>> handleTypeMismatch(TypeMismatchException exception) {
        return buildResponse(HttpStatus.BAD_REQUEST, "Valor invalido para " + exception.getPropertyName());
    }

    // Erros da propria requisicao (rota inexistente, parametro ausente, metodo
    // nao suportado, upload grande demais) ja trazem o status HTTP adequado.
    @ExceptionHandler({
            NoResourceFoundException.class,
            ServletRequestBindingException.class,
            MissingServletRequestPartException.class,
            HttpRequestMethodNotSupportedException.class,
            HttpMediaTypeException.class,
            MaxUploadSizeExceededException.class
    })
    public ResponseEntity<Map<String, Object>> handleRequestError(Exception exception) {
        if (exception instanceof ErrorResponse errorResponse) {
            return buildResponse(
                    HttpStatus.valueOf(errorResponse.getStatusCode().value()),
                    errorResponse.getBody().getDetail());
        }
        return buildResponse(HttpStatus.BAD_REQUEST, GENERIC_BAD_REQUEST_MESSAGE);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidation(MethodArgumentNotValidException exception) {
        String message = exception.getBindingResult().getFieldErrors().stream()
                .findFirst()
                .map(error -> error.getDefaultMessage())
                .or(() -> exception.getBindingResult().getGlobalErrors().stream()
                        .findFirst()
                        .map(error -> error.getDefaultMessage()))
                .orElse("Dados invalidos");
        return buildResponse(HttpStatus.BAD_REQUEST, message);
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<Map<String, Object>> handleUnreadableMessage(HttpMessageNotReadableException exception) {
        String detailedMessage = exception.getMostSpecificCause() != null
                ? exception.getMostSpecificCause().getMessage()
                : GENERIC_BAD_REQUEST_MESSAGE;
        return buildResponse(
                HttpStatus.BAD_REQUEST,
                appProperties.getErrors().isIncludeDetails() ? detailedMessage : GENERIC_BAD_REQUEST_MESSAGE
        );
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<Map<String, Object>> handleAccessDenied(AccessDeniedException exception) {
        return buildResponse(HttpStatus.FORBIDDEN, exception.getMessage());
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleUnexpected(Exception exception) {
        String errorId = UUID.randomUUID().toString();
        log.error("Erro interno nao tratado. errorId={}", errorId, exception);

        if (appProperties.getErrors().isIncludeDetails()) {
            return buildResponse(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), errorId);
        }

        return buildResponse(HttpStatus.INTERNAL_SERVER_ERROR, GENERIC_SERVER_ERROR_MESSAGE, errorId);
    }

    private ResponseEntity<Map<String, Object>> buildResponse(HttpStatus status, String message) {
        return buildResponse(status, message, null);
    }

    private ResponseEntity<Map<String, Object>> buildResponse(HttpStatus status, String message, String errorId) {
        Map<String, Object> body = new HashMap<>();
        body.put("timestamp", Instant.now());
        body.put("status", status.value());
        body.put("message", message);
        if (errorId != null) {
            body = new LinkedHashMap<>(body);
            body.put("errorId", errorId);
        }
        return ResponseEntity.status(status).body(body);
    }
}

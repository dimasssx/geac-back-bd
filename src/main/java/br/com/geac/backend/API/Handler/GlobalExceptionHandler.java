package br.com.geac.backend.API.Handler;

import br.com.geac.backend.Domain.Exceptions.BadRequestException;
import br.com.geac.backend.Domain.Exceptions.ConflictException;
import br.com.geac.backend.Domain.Exceptions.ExceptionDetails;
import org.jspecify.annotations.Nullable;
import org.springframework.boot.json.JsonParseException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.*;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.Map;

@ControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

    @ExceptionHandler(ConflictException.class)
    public ResponseEntity<ExceptionDetails> handleConflictException(ConflictException ex) {

        return new ResponseEntity<>(
                ExceptionDetails.builder()
                        .title("Conflict")
                        .status(HttpStatus.CONFLICT.value())
                        .timestamp(LocalDateTime.now())
                        .details(ex.getClass().getSimpleName())
                        .message("Conflict occurred: " + ex.getMessage())
                        .build(), HttpStatus.CONFLICT

        );
    }

    @ExceptionHandler(BadRequestException.class)
    public ResponseEntity<ExceptionDetails> handleConflict(BadRequestException e) {
        return new ResponseEntity<>(
                ExceptionDetails.builder()
                        .title("Bad Request, algo deu errado")
                        .status(HttpStatus.BAD_REQUEST.value())
                        .timestamp(LocalDateTime.now())
                        .details(e.getClass().getSimpleName())
                        .message(e.getMessage())
                        .build(), HttpStatus.BAD_REQUEST
        );
    }

    @Override
    protected @Nullable ResponseEntity<Object> handleMethodArgumentNotValid(
            MethodArgumentNotValidException ex, HttpHeaders headers, HttpStatusCode status, WebRequest request) {

        Map<String, String> errorFields = new LinkedHashMap<>();
        ex.getBindingResult().getFieldErrors().forEach((error) -> {
            errorFields.put(error.getField(), error.getDefaultMessage());
        });

        return new ResponseEntity<>(
                ExceptionDetails.builder()
                        .title("BAD REQUEST, invalid fields")
                        .status(HttpStatus.BAD_REQUEST.value())
                        .timestamp(LocalDateTime.now())
                        .details(ex.getMessage().getClass().getSimpleName())
                        .message(errorFields)
                        .build(), HttpStatus.BAD_REQUEST
        );
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<Object> handleConflict(DataIntegrityViolationException e) {
        return new ResponseEntity<>(
                ExceptionDetails.builder()
                        .title("Erro de integridade de dados")
                        .status(HttpStatus.CONFLICT.value())
                        .timestamp(LocalDateTime.now())
                        .details(e.getClass().getSimpleName())
                        .message(e.getMessage())
                        .build(), HttpStatus.CONFLICT
        );
    }
@Override
    protected @Nullable ResponseEntity<Object> handleHttpMessageNotReadable(
            HttpMessageNotReadableException ex,
            HttpHeaders headers,
            HttpStatusCode status,
            WebRequest request) {

        ProblemDetail body = createProblemDetail(ex, status, ex.getLocalizedMessage(), ex.getMessage(), null, request);
        return handleExceptionInternal(ex, body, headers, status, request);
    }
}

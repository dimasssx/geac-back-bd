package br.com.geac.backend.API.Handler;

import br.com.geac.backend.Domain.Exceptions.ConflictException;
import br.com.geac.backend.Domain.Exceptions.ConflictExceptionDetails;
import br.com.geac.backend.Domain.Exceptions.ExceptionDetails;
import org.jspecify.annotations.Nullable;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import java.time.LocalDateTime;

@ControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

    @ExceptionHandler(ConflictException.class)
    public ResponseEntity<ConflictExceptionDetails> handleConflictException(ConflictException ex) {

            return new ResponseEntity<>(
                    ConflictExceptionDetails.builder()
                            .title("Conflict")
                            .status(HttpStatus.CONFLICT.value())
                            .timestamp(LocalDateTime.now())
                            .details(ex.getClass().getSimpleName())
                            .message("Conflict occurred: " + ex.getMessage())
                            .build(), HttpStatus.CONFLICT

            );
    }
@Override
protected @Nullable ResponseEntity<Object> handleMethodArgumentNotValid(
        MethodArgumentNotValidException ex, HttpHeaders headers, HttpStatusCode status, WebRequest request) {

    return new ResponseEntity<>(
            ExceptionDetails.builder()
                    .title("BAD REQUEST")
                    .status(HttpStatus.BAD_REQUEST.value())
                    .timestamp(LocalDateTime.now())
                    .details(ex.getClass().getSimpleName())
                    .message("Bad Request: check the fields and try again.")
                    .build(), HttpStatus.BAD_REQUEST
            );
}

}

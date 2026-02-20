package br.com.geac.backend.Domain.Exceptions;

import lombok.Data;
import lombok.experimental.SuperBuilder;

import java.time.LocalDateTime;

@SuperBuilder
@Data
public class ExceptionDetails {
    private String title;
    private int status;
    private String details;
    private String message;
    private LocalDateTime timestamp;

}

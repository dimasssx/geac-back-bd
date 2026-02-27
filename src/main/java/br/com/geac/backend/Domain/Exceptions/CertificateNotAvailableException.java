package br.com.geac.backend.Domain.Exceptions;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.FORBIDDEN)
public class CertificateNotAvailableException extends RuntimeException {
    public CertificateNotAvailableException(String message) {
        super(message);
    }
}
package br.com.geac.backend.Domain.Exceptions;

public class RegistrationNotFoundException extends BadRequestException {
    public RegistrationNotFoundException(String message) {
        super(message);
    }
}

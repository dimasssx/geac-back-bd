package br.com.geac.backend.Domain.Exceptions;

public class UserNotFoundException extends BadRequestException {
    public UserNotFoundException(String message) {
        super(message);
    }
}

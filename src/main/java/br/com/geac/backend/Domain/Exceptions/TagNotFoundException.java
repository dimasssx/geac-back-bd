package br.com.geac.backend.Domain.Exceptions;

public class TagNotFoundException extends BadRequestException {
    public TagNotFoundException(String message) {
        super(message);
    }
}

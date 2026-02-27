package br.com.geac.backend.Domain.Exceptions;

public class EventNotFoundException extends BadRequestException {
    public EventNotFoundException(String message) {
        super(message);
    }
}

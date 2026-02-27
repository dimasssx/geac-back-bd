package br.com.geac.backend.Domain.Exceptions;

public class EventNotAvailableException extends BadRequestException {
    public EventNotAvailableException(String message) {
        super(message);
    }
}

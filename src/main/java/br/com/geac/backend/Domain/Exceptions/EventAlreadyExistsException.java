package br.com.geac.backend.Domain.Exceptions;

public class EventAlreadyExistsException extends ConflictException {
    public EventAlreadyExistsException(String message) {
        super(message);
    }
}
package br.com.geac.backend.Domain.Exceptions;

public class LocationAlreadyExistsException extends ConflictException {
    public LocationAlreadyExistsException(String message) {
        super(message);
    }
}

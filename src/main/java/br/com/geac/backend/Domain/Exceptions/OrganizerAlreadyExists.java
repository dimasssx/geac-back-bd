package br.com.geac.backend.Domain.Exceptions;

public class OrganizerAlreadyExists extends ConflictException {
    public OrganizerAlreadyExists(String message) {
        super(message);
    }
}

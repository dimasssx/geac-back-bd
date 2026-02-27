package br.com.geac.backend.Domain.Exceptions;

public class OrganizerNotFoundExceptio extends BadRequestException {
    public OrganizerNotFoundExceptio(String message) {
        super(message);
    }
}

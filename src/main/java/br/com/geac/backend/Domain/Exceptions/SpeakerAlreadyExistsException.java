package br.com.geac.backend.Domain.Exceptions;

public class SpeakerAlreadyExistsException extends ConflictException {
    public SpeakerAlreadyExistsException(String message) {
        super(message);
    }
}

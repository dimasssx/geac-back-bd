package br.com.geac.backend.Domain.Exceptions;

public class SpeakerNotFoundException extends BadRequestException {
    public SpeakerNotFoundException(String message) {
        super(message);
    }
}

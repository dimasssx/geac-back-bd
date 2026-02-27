package br.com.geac.backend.Domain.Exceptions;

public class RequestAlreadyExists extends ConflictException {
    public RequestAlreadyExists(String message) {
        super(message);
    }
}

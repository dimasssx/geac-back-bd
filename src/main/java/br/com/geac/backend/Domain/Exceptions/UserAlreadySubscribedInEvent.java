package br.com.geac.backend.Domain.Exceptions;

public class UserAlreadySubscribedInEvent extends BadRequestException {
    public UserAlreadySubscribedInEvent(String message) {
        super(message);
    }
}

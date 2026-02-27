package br.com.geac.backend.Domain.Exceptions;

public class EventMaxCapacityAchievedException extends BadRequestException {
    public EventMaxCapacityAchievedException(String message) {
        super(message);
    }
}

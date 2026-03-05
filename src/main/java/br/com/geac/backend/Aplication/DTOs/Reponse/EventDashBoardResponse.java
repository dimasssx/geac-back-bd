package br.com.geac.backend.Aplication.DTOs.Reponse;

public record EventDashBoardResponse(
        Long totalEvents,
        Long activeEvents,
        Long completedEvents,
        Long cancelledEvents,
        Long upcomingEvents,
        Long totalInscritos,
        Long totalPresentes,
        Double taxaPresenca,
        Double avgRating
) {
}

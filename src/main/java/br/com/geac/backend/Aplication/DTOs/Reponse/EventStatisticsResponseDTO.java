package br.com.geac.backend.Aplication.DTOs.Reponse;

import java.util.UUID;

public record EventStatisticsResponseDTO(
        UUID eventId,
        String eventTitle,
        String eventStatus,
        Long totalInscritos,
        Long totalPresentes,
        Double mediaAvaliacao
) {
}

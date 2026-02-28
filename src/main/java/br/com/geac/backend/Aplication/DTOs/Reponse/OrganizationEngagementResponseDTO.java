package br.com.geac.backend.Aplication.DTOs.Reponse;

import java.util.UUID;

public record OrganizationEngagementResponseDTO(
        UUID organizerId,
        String organizerName,
        Long totalEventosRealizados,
        Long totalParticipantesEngajados
) {
}

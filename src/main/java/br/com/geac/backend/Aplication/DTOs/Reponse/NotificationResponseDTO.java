package br.com.geac.backend.Aplication.DTOs.Reponse;

import java.time.LocalDateTime;
import java.util.UUID;

public record NotificationResponseDTO(
        Integer id,
        UUID userId,
        UUID eventId,
        String eventTitle,
        boolean isRead,
        String type,
        String title,
        String message,
        LocalDateTime createdAt
) {
}
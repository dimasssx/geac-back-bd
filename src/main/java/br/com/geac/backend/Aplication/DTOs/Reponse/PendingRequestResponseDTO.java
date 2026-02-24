package br.com.geac.backend.Aplication.DTOs.Reponse;

import java.time.LocalDateTime;

public record PendingRequestResponseDTO(
        Integer id,
        String userName,
        String userEmail,
        String organizerName,
        String justification,
        LocalDateTime createdAt
) {}
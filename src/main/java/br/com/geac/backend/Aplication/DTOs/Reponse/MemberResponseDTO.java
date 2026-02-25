package br.com.geac.backend.Aplication.DTOs.Reponse;

import java.time.LocalDateTime;
import java.util.UUID;

public record MemberResponseDTO(
        UUID userId,
        String name,
        String email,
        LocalDateTime joinedAt
) {
}
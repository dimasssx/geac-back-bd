package br.com.geac.backend.Aplication.DTOs.Reponse;

import br.com.geac.backend.Domain.Enums.Role;

import java.time.LocalDateTime;
import java.util.UUID;

public record UserResponseDTO(
        UUID id,
        String email,
        String name,
        Role role,
        LocalDateTime created_at
) {
}

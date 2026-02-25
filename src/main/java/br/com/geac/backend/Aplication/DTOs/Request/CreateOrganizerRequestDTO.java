package br.com.geac.backend.Aplication.DTOs.Request;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record CreateOrganizerRequestDTO(
        @NotNull(message = "ID do usuário é obrigatório") UUID userId,
        @NotNull(message = "ID da organização é obrigatório") Integer organizerId,
        String justification
) {}
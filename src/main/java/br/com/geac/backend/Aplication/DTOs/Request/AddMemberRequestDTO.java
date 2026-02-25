package br.com.geac.backend.Aplication.DTOs.Request;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record AddMemberRequestDTO(
        @NotNull(message = "O ID do usuário é obrigatório")
        UUID userId
) {}
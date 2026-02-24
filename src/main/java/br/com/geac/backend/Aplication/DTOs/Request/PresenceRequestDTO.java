package br.com.geac.backend.Aplication.DTOs.Request;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import java.util.List;
import java.util.UUID;

public record PresenceRequestDTO(
    @NotEmpty(message = "A lista de usuários não pode estar vazia")
     List<UUID> userIds,

     @NotNull(message = "O status de presença é obrigatório")
     Boolean attended) {
}

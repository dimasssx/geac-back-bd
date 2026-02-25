package br.com.geac.backend.Aplication.DTOs.Reponse;

import java.util.UUID;

public record RegistrationResponseDTO(
        UUID userId,
        String userName,
        String userEmail,
        Boolean attended,
        String status
) {
}
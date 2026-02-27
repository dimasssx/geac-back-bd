package br.com.geac.backend.Aplication.DTOs.Reponse;

public record UserRegistrationContextResponseDTO(
        Boolean isRegistered,
        String status,
        Boolean attended
) {
}

package br.com.geac.backend.Aplication.DTOs.Request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

public record LocationRequestDTO(
        @NotBlank(message = "O nome do local é obrigatório")
        String name,

        @NotBlank(message = "A rua é obrigatória")
        String street,

        String number, // Pode ser "S/N"

        @NotBlank(message = "O bairro é obrigatório")
        String neighborhood,

        @NotBlank(message = "A cidade é obrigatória")
        String city,

        @NotBlank(message = "O estado é obrigatório")
        @Pattern(regexp = "[A-Z]{2}", message = "O estado deve ter 2 letras (sigla)")
        String state,

        @NotBlank(message = "O CEP é obrigatório")
        String zipCode,

        String referencePoint,

        @NotNull(message = "A capacidade é obrigatória")
        Integer capacity
) {}
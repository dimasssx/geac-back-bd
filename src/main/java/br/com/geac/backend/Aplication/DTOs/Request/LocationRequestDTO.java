package br.com.geac.backend.Aplication.DTOs.Request;

import br.com.geac.backend.Domain.Enums.Campus;
import jakarta.validation.constraints.*;

public record LocationRequestDTO(
        @NotBlank(message = "O nome do local é obrigatório")
        @Size(min = 3, max = 100, message = "O nome deve ter entre 3 e 100 caracteres")
        String name,

        @Size(max = 150, message = "O logradouro não pode exceder 150 caracteres")
        @NotBlank(message = "A rua é obrigatória")
        String street,

        @Size(max = 10, message = "O número não pode exceder 10 caracteres")
        String number, // Pode ser "S/N"

        @Size(max = 100, message = "O bairro não pode exceder 100 caracteres")
        @NotBlank(message = "O bairro é obrigatório")
        String neighborhood,

        @Size(max = 100, message = "A cidade não pode exceder 100 caracteres")
        @NotBlank(message = "A cidade é obrigatória")
        String city,


        @NotBlank(message = "O estado é obrigatório")
        @Pattern(regexp = "[A-Z]{2}", message = "O estado deve ter 2 letras maiusculas (sigla)")
        String state,


        @Pattern(regexp = "\\d{5}-\\d{3}", message = "O CEP deve seguir o formato 00000-000")
        @NotBlank(message = "O CEP é obrigatório")
        String zipCode,

        @Size(max = 255, message = "O ponto de referência é muito longo")
        String referencePoint,

        @NotNull(message = "A capacidade é obrigatória")
        @Positive(message = "A capacidade deve ser um número positivo")
        Integer capacity,

        @NotNull(message = "O campus é obrigatório")
        Campus campus
) {}
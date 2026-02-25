package br.com.geac.backend.Aplication.DTOs.Request;

import br.com.geac.backend.Domain.Enums.Campus;
import jakarta.validation.constraints.*;

public record LocationPatchRequestDTO(

        @Size(min = 3, max = 100, message = "O nome deve ter entre 3 e 100 caracteres")
        String name,

        @Size(max = 150, message = "O logradouro não pode exceder 150 caracteres")
        String street,

        @Size(max = 10, message = "O número não pode exceder 10 caracteres")
        String number, // Suporta "S/N"

        @Size(max = 50, message = "O bairro não pode exceder 50 caracteres")
        String neighborhood,

        @Size(max = 100, message = "A cidade não pode exceder 100 caracteres")
        String city,

        @Pattern(regexp = "[A-Z]{2}", message = "O estado deve ser uma sigla de 2 letras maiúsculas (ex: SP)")
        String state,

        @Pattern(regexp = "\\d{5}-\\d{3}", message = "O CEP deve seguir o formato 00000-000")
        String zipCode,

        @Size(max = 255, message = "O ponto de referência é muito longo")
        String referencePoint,

        @Positive(message = "A capacidade deve ser um número positivo")
        Integer capacity,

        @NotNull(message = "O campus é obrigatório")
        Campus campus
) {
}

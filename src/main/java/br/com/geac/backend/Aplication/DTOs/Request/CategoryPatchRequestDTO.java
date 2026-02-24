package br.com.geac.backend.Aplication.DTOs.Request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CategoryPatchRequestDTO (

        @Size(min = 2, max = 50, message = "O nome deve conter entre 2 e 50 caracteres")
        String name,
        @Size(min = 10, max = 255, message = "A descrição deve conter entre 10 e 255 caracteres")
        String description
) {
}
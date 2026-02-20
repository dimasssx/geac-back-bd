package br.com.geac.backend.Aplication.DTOs.Request;

import jakarta.validation.constraints.NotBlank;

public record TagRequestDTO(
        @NotBlank(message = "O nome da tag não pode ser vazio")
        String name
) {}
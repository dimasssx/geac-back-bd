package br.com.geac.backend.Aplication.DTOs.Request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record OrganizerRequestDTO(
        @NotBlank(message = "O nome da organização é obrigatório")
        @Size(min = 3, max = 100, message = "O nome deve ter entre 3 e 100 caracteres")
        String name,

        @NotBlank(message = "O email de contato é obrigatório")
        @Email(message = "Formato de email inválido")
        String contactEmail
) {}
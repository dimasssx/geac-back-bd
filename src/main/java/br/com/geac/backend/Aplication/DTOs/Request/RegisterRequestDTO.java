package br.com.geac.backend.Aplication.DTOs.Request;


import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RegisterRequestDTO(
        @NotBlank @Size(min = 3,max = 50) String name,
        @NotBlank @Email String email,
        @NotBlank @Size(min=6) String password,
        @NotBlank String role) {
}

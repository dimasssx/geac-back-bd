package br.com.geac.backend.Aplication.DTOs.Request;

import br.com.geac.backend.Domain.Enums.Role;

public record UserPatchRequestDTO(
        String email,
        String name,
        Role role
) {
}

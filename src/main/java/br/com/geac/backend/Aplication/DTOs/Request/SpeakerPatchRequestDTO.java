package br.com.geac.backend.Aplication.DTOs.Request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;

import java.util.Set;

public record SpeakerPatchRequestDTO(
        @Size(min = 3, max = 75, message = "O nome do palestrante deve ter entre) 3 e 75 caracteres")
        String name,
        @Size(min = 5, max = 255, message = "A biografia do palestrante deve ter entre 5 e 255 caracteres")
        String bio,
        @Email
        String email,
        Set<QualificationRequestDTO> qualifications
) {
}

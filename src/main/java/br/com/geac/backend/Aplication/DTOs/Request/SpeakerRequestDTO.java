package br.com.geac.backend.Aplication.DTOs.Request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;

import java.util.Set;

public record SpeakerRequestDTO(

        @NotBlank @Size(min = 3, max = 75, message = "O nome do palestrante deve ter entre) 3 e 75 caracteres")
        String name,
        @NotBlank @Size(min = 5, max = 255, message = "A biografia do palestrante deve ter entre 5 e 255 caracteres")
        String bio,
        @NotEmpty
        Set<QualificationRequestDTO> qualifications,
        @Email @NotBlank
        String email
) {
}

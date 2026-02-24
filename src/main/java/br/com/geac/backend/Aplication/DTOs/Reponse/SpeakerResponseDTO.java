package br.com.geac.backend.Aplication.DTOs.Reponse;

import java.util.Set;

public record SpeakerResponseDTO(
        Integer id,

        String name,

        String bio,

        Set<String> qualifications
) {
}

package br.com.geac.backend.Aplication.DTOs.Request;

import jakarta.validation.constraints.*;
import org.hibernate.validator.constraints.URL;

import java.time.LocalDateTime;
import java.util.Set;

public record EventPatchRequestDTO(
        @Size(min = 5, max = 100)
        String title,
        String description,
        @URL(message = "O link online deve ser uma URL válida")
        String onlineLink,
        @Future(message = "A data de início deve ser no futuro")
        LocalDateTime startTime,
        @Future(message = "A data de término deve ser no futuro")
        LocalDateTime endTime,

        @Positive( message = "A carga horária deve ser de no mínimo 1 hora")
        Integer workloadHours,
        @Positive( message = "A capacidade deve ser de no mínimo 1 pessoa")
        Integer maxCapacity,

        Integer categoryId,
        Integer requirementId,
        Set<Integer> tags, //TODO: mesma coisa dos de cima, mas já ta implementado pros 2 casos
        Integer locationId,
        Set<Integer> speakers
) {
}

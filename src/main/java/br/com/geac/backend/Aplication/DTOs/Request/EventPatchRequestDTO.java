package br.com.geac.backend.Aplication.DTOs.Request;

import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import org.hibernate.validator.constraints.URL;

import java.time.LocalDateTime;
import java.time.ZonedDateTime;
import java.util.Set;
import java.util.UUID;

public record EventPatchRequestDTO(
        @Size(min = 5, max = 100)
        String title,
        String description,
        @URL(message = "O link online deve ser uma URL válida")
        String onlineLink,
        @Future(message = "A data de início deve ser no futuro")
        ZonedDateTime startTime,
        @Future(message = "A data de término deve ser no futuro")
        ZonedDateTime endTime,

        @Positive(message = "A carga horária deve ser de no mínimo 1 hora")
        Integer workloadHours,
        @Positive(message = "A capacidade deve ser de no mínimo 1 pessoa")
        Integer maxCapacity,

        Integer categoryId,
        Set<Integer> requirementIds,
        Set<Integer> tags,
        Integer locationId,
        Set<Integer> speakers,
        UUID orgId
) {
}

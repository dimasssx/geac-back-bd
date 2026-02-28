package br.com.geac.backend.Aplication.DTOs.Request;

import jakarta.validation.constraints.*;
import org.hibernate.validator.constraints.URL;

import java.time.LocalDateTime;
import java.time.ZonedDateTime;
import java.util.List;
import java.util.Set;
import java.util.UUID;

public record EventRequestDTO(
        @NotBlank(message = "O título é obrigatório")
        String title,
        @NotBlank(message = "A descrição é obrigatória")
        String description,
        @URL(message = "O link online deve ser uma URL válida")
        String onlineLink,
        @NotNull(message = "A data de início é obrigatória")
        @Future(message = "A data de início deve ser no futuro")
        ZonedDateTime startTime,

        @NotNull(message = "A data de término é obrigatória")
        @Future(message = "A data de término deve ser no futuro")
        ZonedDateTime endTime,

        @NotNull(message = "A carga horária é obrigatória")
        @Min(value = 1, message = "A carga horária deve ser de no mínimo 1 hora")
        Integer workloadHours,

        @NotNull(message = "A capacidade máxima é obrigatória")
        @Min(value = 1, message = "A capacidade deve ser de no mínimo 1 pessoa")
        Integer maxCapacity,

        @NotNull(message = "O ID da categoria é obrigatório") //TODO: Verificar se vai ser 1 ou varias
        Integer categoryId,

        @NotNull(message = "A lista de requisitos do evento é obrigatório")
        Set<Integer> requirementIds,

        @NotNull
        @Size(min = 1, message = "O evento deve ter pelo menos uma tag")
        Set<Integer> tags,

        //pode ser nulo, pois o evento pode ser online
        Integer locationId,

        @NotNull
        @Size(min = 1, message = "O evento deve ter pelo menos um palestrante")
        Set<Integer> speakers,

        @NotNull
        UUID orgId
) {
}

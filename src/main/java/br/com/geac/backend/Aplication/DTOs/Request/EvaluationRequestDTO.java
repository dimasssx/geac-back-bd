package br.com.geac.backend.Aplication.DTOs.Request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record EvaluationRequestDTO(
        @NotNull(message = "Id da inscrição é obrigatório")
        UUID eventId,
        @Size(min = 4,max = 1000,message = "Comentário deve ter entre 4 e 1000 caracteres")
        String comment,
        @NotNull(message = "Rating é obrigatório")
        @Min(value = 1,message = "Rating minimo é um")
        @Max(value = 5,message = "Rating máximo é cinco")
        Integer rating
) {
}

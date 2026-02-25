package br.com.geac.backend.Aplication.DTOs.Reponse;

import br.com.geac.backend.Domain.Enums.Campus;

public record LocationResponseDTO (
        Integer id,
        String name,
        String street,
        String number,
        String neighborhood,
        String city,
        String state,
        String zipCode,
        Campus campus,
        String referencePoint,
        Integer capacity) {
}

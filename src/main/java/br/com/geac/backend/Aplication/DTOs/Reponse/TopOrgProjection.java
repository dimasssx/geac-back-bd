package br.com.geac.backend.Aplication.DTOs.Reponse;

import java.util.UUID;

public record TopOrgProjection(
        UUID organizerId,
        String organizerName,
        Long value) {
}

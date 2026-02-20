package br.com.geac.backend.Aplication.DTOs.Reponse;

public record LocationResponseDTO (
        Integer id,
        String name,
        String street,
        String number,
        String neighborhood,
        String city,
        String state,
        String zipCode,
        String referencePoint,
        Integer capacity){
}

package br.com.geac.backend.Aplication.DTOs.Reponse;

import lombok.Builder;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Builder

public record EventResponseDTO(
    UUID id,
    String title,
    String description,
    String onlineLink,
    LocalDateTime startTime,
    LocalDateTime endTime,
    Integer workloadHours,
    Integer maxCapacity,
    String status,
    LocalDateTime createdAt,

    Integer categoryId,
    String categoryName,

    LocationResponseDTO location,

    String organizerName,
    String organizerEmail,

    Integer reqId,
    List<String> requirementDescription,

    List<String> tags,
    List<String> speakers

) {}

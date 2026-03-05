package br.com.geac.backend.Aplication.DTOs.Reponse;

import java.util.UUID;

public record OrganizationDashBoard(
        Long totalOrgs,
        Long totalEvents,
        Long totalEngaged,
        Double avgEventsPerOrg,
        Double avgEngagedPerOrg,
        Long activeOrgs,
        Long inactiveCount,
        Long lowCount,
        Long mediumCount,
        Long highCount
) {
}

package br.com.geac.backend.Repositories;

import br.com.geac.backend.Domain.Entities.EventRequirement;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface EventRequirementRepository extends JpaRepository<EventRequirement, Integer> {
}
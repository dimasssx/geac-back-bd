package br.com.geac.backend.Infrastructure.Repositories;

import br.com.geac.backend.Domain.Entities.Organizer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface OrganizerRepository extends JpaRepository<Organizer, Integer> {
    boolean existsByName(String name);
}
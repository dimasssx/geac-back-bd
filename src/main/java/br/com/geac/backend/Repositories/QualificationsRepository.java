package br.com.geac.backend.Repositories;

import br.com.geac.backend.Domain.Entities.Qualification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface QualificationsRepository extends JpaRepository<Qualification, Integer> {
}

package br.com.geac.backend.Infrastructure.Repositories;

import br.com.geac.backend.Domain.Entities.OrganizerMember;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface OrganizerMemberRepository extends JpaRepository<OrganizerMember, Integer> {

    //utilizado para validar se o usuario tem os poderes necessarios
    boolean existsByOrganizerIdAndUserId(Integer organizerId, UUID userId);

    List<OrganizerMember> findAllByOrganizerId(Integer organizerId);

    // buscar um vínculo específico para podermos deletar
    Optional<OrganizerMember> findByOrganizerIdAndUserId(Integer organizerId, UUID userId);
}
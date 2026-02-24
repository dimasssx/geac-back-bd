package br.com.geac.backend.Repositories;

import br.com.geac.backend.Domain.Entities.Speaker;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.Set;

@Repository
public interface SpeakerRepository extends JpaRepository<Speaker, Integer> {

    Set<Speaker> findAllByIdIn(Collection<Integer> ids);

    boolean existsByNameAndBio(String name, String bio);

    boolean existsByNameAndEmail(String name, String email);

    boolean existsByNameAndEmailAndIdNot(String name, String email, Integer id);
}

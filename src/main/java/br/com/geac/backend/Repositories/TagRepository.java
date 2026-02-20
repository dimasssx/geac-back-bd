package br.com.geac.backend.Repositories;

import br.com.geac.backend.Domain.Entities.Tag;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.Set;

@Repository
public interface TagRepository extends JpaRepository<Tag, Integer> {

    Optional<Tag> findByName(String name);

    List<Tag> getAllById(Integer id);

    Set<Tag> findAllByIdIn(Collection<Integer> ids);
}
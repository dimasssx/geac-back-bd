package br.com.geac.backend.Infrastructure.Repositories;

import br.com.geac.backend.Domain.Entities.User;
import br.com.geac.backend.Domain.Enums.Role;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {

    UserDetails findByEmail(String email);
    boolean existsByEmail(String email);
    List<User> findAllByRole(Role role);

    Optional<User> getUsersByEmail(String email);
}

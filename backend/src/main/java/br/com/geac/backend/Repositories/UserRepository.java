package br.com.geac.backend.Repositories;

import br.com.geac.backend.Domain.Entities.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {
    UserDetails findByUsername(String username);

    boolean existsByEmail(String email);
}

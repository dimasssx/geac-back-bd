package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Aplication.DTOs.Reponse.UserResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.UserPatchRequestDTO;
import br.com.geac.backend.Domain.Entities.User;
import br.com.geac.backend.Domain.Exceptions.EmailAlreadyExistsException;
import br.com.geac.backend.Domain.Exceptions.UserNotFoundException;
import br.com.geac.backend.Infrastructure.Repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import org.jspecify.annotations.Nullable;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UserService implements UserDetailsService {
    private final UserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        return userRepository.findByEmail(username);
    }
    @Transactional
    public UserResponseDTO updateUser(UUID id, UserPatchRequestDTO requestDTO) {
        var user = userRepository.findById(id).orElseThrow(() -> new UserNotFoundException("Usuario nao encontrado"));
        if (requestDTO.name() != null) {
            user.setName(requestDTO.name());
        }
        if (requestDTO.email() != null) {
            userRepository.getUsersByEmail((requestDTO.email())).ifPresent(userEmail -> {
                if (!userEmail.getId().equals(id)) {
                    throw new EmailAlreadyExistsException("Email já cadastrado");
                }
            });
            user.setEmail(requestDTO.email());
        }
        if (requestDTO.role() != null) {
            user.setRole(requestDTO.role());
        }
        return mapUser(userRepository.save(user));
    }

    @Transactional
    public void deleteUser(UUID id) {
        if (!userRepository.existsById(id)) {
            throw new UserNotFoundException("Usuário não encontrado");
        }
        userRepository.deleteById(id);
    }

    public List<UserResponseDTO> getAllUsers() {
        return userRepository.findAll()
                .stream()
                .map(this::mapUser)
                .toList();

    }

    public UserResponseDTO mapUser(User user) {

        return new UserResponseDTO(
                user.getId(),
                user.getEmail(),
                user.getName(),
                user.getRole(),
                user.getCreated_at()
        );
    }

    public  UserResponseDTO getUserById(UUID id) {
        var user = userRepository.findById(id)
                .orElseThrow(()-> new UserNotFoundException("Use nao foi encontrado"));
        return mapUser(user);
    }
}

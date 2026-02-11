package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Aplication.DTOs.Reponse.RegisterResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.RegisterRequestDTO;
import br.com.geac.backend.Aplication.Mappers.UserMapper;
import br.com.geac.backend.Domain.Entities.User;
import br.com.geac.backend.Repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {
    private final UserRepository userRepository;
    private final PasswordEncoder encoder;
    public RegisterResponseDTO registerUser(RegisterRequestDTO request) {

        if(userRepository.existsByEmail(request.email())) {
            throw new IllegalArgumentException("Email already in use"); //tratar dps
        }

        User user = UserMapper.INSTANCE.registerToUser(request);
        String encriptedPass = encoder.encode(user.getPassword());
        user.setPassword(encriptedPass);

        return UserMapper.INSTANCE.userToRegisterResponse(userRepository.save(user));
    }
}

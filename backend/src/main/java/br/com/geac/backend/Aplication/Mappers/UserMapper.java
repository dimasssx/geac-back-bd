package br.com.geac.backend.Aplication.Mappers;

import br.com.geac.backend.Aplication.DTOs.Reponse.RegisterResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.RegisterRequestDTO;
import br.com.geac.backend.Domain.Entities.User;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.factory.Mappers;

@Mapper(componentModel = "spring")
public interface UserMapper {
    UserMapper INSTANCE = Mappers.getMapper(UserMapper.class);

    @Mapping(target = "password", ignore = true)
    User registerToUser(RegisterRequestDTO registerRequestDTO);

    RegisterResponseDTO userToRegisterResponse(User user);
}

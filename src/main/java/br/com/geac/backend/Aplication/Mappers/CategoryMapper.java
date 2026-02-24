package br.com.geac.backend.Aplication.Mappers;

import br.com.geac.backend.Aplication.DTOs.Reponse.CategoryResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.CategoryPatchRequestDTO;
import br.com.geac.backend.Aplication.DTOs.Request.CategoryRequestDTO;
import br.com.geac.backend.Domain.Entities.Category;
import org.mapstruct.BeanMapping;
import org.mapstruct.Mapper;
import org.mapstruct.MappingTarget;
import org.mapstruct.NullValuePropertyMappingStrategy;

@Mapper(componentModel = "spring")
public interface CategoryMapper {

    CategoryResponseDTO toResponse(Category category);

    Category toEntity(CategoryRequestDTO dto);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    void updateEntityFromDto(CategoryPatchRequestDTO dto, @MappingTarget Category entity);
}

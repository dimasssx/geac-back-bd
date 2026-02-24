package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Aplication.DTOs.Reponse.CategoryResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.CategoryPatchRequestDTO;
import br.com.geac.backend.Aplication.DTOs.Request.CategoryRequestDTO;
import br.com.geac.backend.Aplication.Mappers.CategoryMapper;
import br.com.geac.backend.Repositories.CategoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor //TODO: better error handling
public class CategoryService {
    private final CategoryRepository repository;
    private final CategoryMapper mapper;

    @Transactional
    public CategoryResponseDTO createCategory(CategoryRequestDTO dto) {
        var category = mapper.toEntity(dto); // add data integrity to handler
        return mapper.toResponse(repository.save(category));
    }

    public CategoryResponseDTO getCategoryById(Integer id) {
        var category = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Category not found"));
        return mapper.toResponse(category);
    }

    public List<CategoryResponseDTO> getAllCategory() {
        return repository.findAll().stream()
                .map(mapper::toResponse)
                .toList();
    }

    @Transactional
    public CategoryResponseDTO updateCategory(Integer id, CategoryPatchRequestDTO dto) {
        var category = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Category not found"));
        mapper.updateEntityFromDto(dto, category);
        return mapper.toResponse(repository.save(category));
    }

    @Transactional
    public void deleteCategory(Integer id) {
        var category = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Category not found"));
        repository.delete(category);
    }
}

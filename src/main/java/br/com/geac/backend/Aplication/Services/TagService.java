package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Aplication.DTOs.Reponse.TagResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.TagRequestDTO;
import br.com.geac.backend.Aplication.Mappers.TagMapper;
import br.com.geac.backend.Domain.Entities.Tag;
import br.com.geac.backend.Domain.Exceptions.TagNotFoundException;
import br.com.geac.backend.Infrastructure.Repositories.TagRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class TagService {

    private final TagRepository tagRepository;
    private final TagMapper mapper;

    @Transactional
    public TagResponseDTO createTag(TagRequestDTO dto) {

        var saving = mapper.toEntity(dto);
        return mapper.toDTO(tagRepository.save(saving)); // se der erro é a constraint do banco
    }

    public TagResponseDTO getById(Integer id) {
        var tag = getTagOrThrowBadRequest(id);
        return mapper.toDTO(tag);
    }

    public List<TagResponseDTO> getAll() {
        return tagRepository.findAll().stream()
                .map(mapper::toDTO)
                .toList();
    }

    public TagResponseDTO updateSpeaker(Integer id, TagRequestDTO dto) {
        var tag = getTagOrThrowBadRequest(id);
        tag.setName(dto.name());
        return mapper.toDTO(tagRepository.save(tag));
    }

    public void deleteTag(Integer id) {
        var tag = getTagOrThrowBadRequest(id);
        tagRepository.delete(tag);
    }

    private Tag getTagOrThrowBadRequest(Integer id) {
        return tagRepository.findById(id)
                .orElseThrow(() -> new TagNotFoundException("Tag not found"));
    }

}

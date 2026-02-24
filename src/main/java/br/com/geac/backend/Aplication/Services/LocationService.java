package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Aplication.DTOs.Reponse.LocationResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.LocationPatchRequestDTO;
import br.com.geac.backend.Aplication.DTOs.Request.LocationRequestDTO;
import br.com.geac.backend.Aplication.Mappers.LocationMapper;
import br.com.geac.backend.Repositories.LocationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class LocationService {

    private final LocationRepository locationRepository;
    private final LocationMapper locationMapper;

    @Transactional
    //TODO: constrain no banco para verificar unicidade
    public LocationResponseDTO createLocation(LocationRequestDTO dto) {
        if (locationRepository.existsByZipCodeAndNumberAndName(dto.zipCode(), dto.number(), dto.name())) { //TODO: Se precisar colocar referencepoint tbm
            throw new RuntimeException("Location with the same zip code,number and name already exists");
        }
        var location = locationMapper.toEntity(dto);
        return locationMapper.toDto(locationRepository.save(location));
    }

    public LocationResponseDTO getById(Integer id) {
        var location = locationRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Location not found"));
        return locationMapper.toDto(location);
    }

    public List<LocationResponseDTO> getAll() {
        return locationRepository.findAll().stream()
                .map(locationMapper::toDto)
                .toList();
    }

    @Transactional

    public LocationResponseDTO updateLocation(Integer id, LocationPatchRequestDTO dto) {

        var location = locationRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Location not found"));

        String newZipCode = dto.zipCode() != null ? dto.zipCode() : location.getZipCode();
        String newNumber = dto.number() != null ? dto.number() : location.getNumber();
        String newName = dto.name() != null ? dto.name() : location.getName();

        if (locationRepository.existsByZipCodeAndNumberAndNameAndIdNot(newZipCode, newNumber, newName, id)) { //TODO: Se precisar colocar referencepoint tbm
            throw new RuntimeException("Another location with the same zip code,number and name already exists");
        }

        locationMapper.updateEntityFromDTO(dto, location);

        return locationMapper.toDto(locationRepository.save(location));
    }

    @Transactional
    public void deleteLocation(Integer id) {

        var location = locationRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Location not found"));
        try {
            locationRepository.delete(location);
        } catch (DataIntegrityViolationException e) {
            throw new RuntimeException("Cannot delete location because it is referenced by other entities");
        }
    }
}

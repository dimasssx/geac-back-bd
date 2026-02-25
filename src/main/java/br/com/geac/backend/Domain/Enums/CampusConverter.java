package br.com.geac.backend.Domain.Enums;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.stream.Stream;

@Converter(autoApply = true)
public class CampusConverter implements AttributeConverter<Campus, String> {

    @Override
    public String convertToDatabaseColumn(Campus campus) {
        if (campus == null) {
            return null;
        }
        return campus.getDescricao();
    }

    @Override
    public Campus convertToEntityAttribute(String descricao) {
        if (descricao == null) {
            return null;
        }
        return Stream.of(Campus.values())
                .filter(c -> c.getDescricao().equals(descricao))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Campus inválido no banco de dados: " + descricao));
    }
}
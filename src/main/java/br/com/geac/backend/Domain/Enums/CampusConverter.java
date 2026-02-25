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
        // Salva o texto amigável ("Campus Central") no banco
        return campus.getDescricao();
    }

    @Override
    public Campus convertToEntityAttribute(String descricao) {
        if (descricao == null) {
            return null;
        }
        // Lê o texto amigável do banco e transforma no Enum correto
        return Stream.of(Campus.values())
                .filter(c -> c.getDescricao().equals(descricao))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Campus inválido no banco de dados: " + descricao));
    }
}
package br.com.geac.backend.Domain.Enums;

import com.fasterxml.jackson.annotation.JsonValue;

public enum Campus {

    CAMPUS_SURUBIM_ALFA("Campus Surubim Alfa"),
    CAMPUS_SURUBIM_BETA("Campus Surubim Beta"),
    CAMPUS_SURUBIM_CENTRAL("Campus Surubim Central"),
    CAMPUS_SURUBIM_CRIATIVO("Campus Surubim Criativo"),
    CAMPUS_SURUBIM_DELTA("Campus Surubim Delta"),
    CAMPUS_SURUBIM_GAMA("Campus Surubim Gama"),
    CAMPUS_SURUBIM_INOVACAO("Campus Surubim Inovação"),
    CAMPUS_SURUBIM_LESTE("Campus Surubim Leste"),
    CAMPUS_SURUBIM_NORTE("Campus Surubim Norte"),
    CAMPUS_SURUBIM_OESTE("Campus Surubim Oeste"),
    CAMPUS_SURUBIM_POS_GRADUACAO("Campus Surubim Pós-Graduação"),
    CAMPUS_SURUBIM_SAUDE("Campus Surubim Saúde"),
    CAMPUS_SURUBIM_SUL("Campus Surubim Sul"),

    CAMPUS_RECIFE_ALFA("Campus Recife Alfa"),
    CAMPUS_RECIFE_BETA("Campus Recife Beta"),
    CAMPUS_RECIFE_CENTRAL("Campus Recife Central"),
    CAMPUS_RECIFE_CRIATIVO("Campus Recife Criativo"),
    CAMPUS_RECIFE_DELTA("Campus Recife Delta"),
    CAMPUS_RECIFE_GAMA("Campus Recife Gama"),
    CAMPUS_RECIFE_INOVACAO("Campus Recife Inovação"),
    CAMPUS_RECIFE_LESTE("Campus Recife Leste"),
    CAMPUS_RECIFE_NORTE("Campus Recife Norte"),
    CAMPUS_RECIFE_OESTE("Campus Recife Oeste"),
    CAMPUS_RECIFE_POS_GRADUACAO("Campus Recife Pós-Graduação"),
    CAMPUS_RECIFE_SAUDE("Campus Recife Saúde"),
    CAMPUS_RECIFE_SUL("Campus Recife Sul"),

    CAMPUS_CARUARU_ALFA("Campus Caruaru Alfa"),
    CAMPUS_CARUARU_BETA("Campus Caruaru Beta"),
    CAMPUS_CARUARU_CENTRAL("Campus Caruaru Central"),
    CAMPUS_CARUARU_CRIATIVO("Campus Caruaru Criativo"),
    CAMPUS_CARUARU_DELTA("Campus Caruaru Delta"),
    CAMPUS_CARUARU_GAMA("Campus Caruaru Gama"),
    CAMPUS_CARUARU_INOVACAO("Campus Caruaru Inovação"),
    CAMPUS_CARUARU_LESTE("Campus Caruaru Leste"),
    CAMPUS_CARUARU_NORTE("Campus Caruaru Norte"),
    CAMPUS_CARUARU_OESTE("Campus Caruaru Oeste"),
    CAMPUS_CARUARU_POS_GRADUACAO("Campus Caruaru Pós-Graduação"),
    CAMPUS_CARUARU_SAUDE("Campus Caruaru Saúde"),
    CAMPUS_CARUARU_SUL("Campus Caruaru Sul");

    private final String descricao;

    Campus(String descricao) {
        this.descricao = descricao;
    }

    @JsonValue
    public String getDescricao() {
        return descricao;
    }
}

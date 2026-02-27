package br.com.geac.backend.Domain.Exceptions;

public class MemberOfPromoterOrgException extends BadRequestException {
    public MemberOfPromoterOrgException(String message) {
        super(message);
    }
}

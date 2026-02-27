package br.com.geac.backend.Domain.Exceptions;

public class UserIsAlreadyOrgMember extends BadRequestException {
    public UserIsAlreadyOrgMember(String message) {super(message);}
}

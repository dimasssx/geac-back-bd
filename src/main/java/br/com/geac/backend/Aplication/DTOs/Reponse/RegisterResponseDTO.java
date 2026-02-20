package br.com.geac.backend.Aplication.DTOs.Reponse;


//Verificar se ja vai redirecionar para o login ou ja logar direto
public record RegisterResponseDTO(String name, String email, String role, String message) {
}

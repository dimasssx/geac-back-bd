package br.com.geac.backend.API.Controller;

import br.com.geac.backend.Aplication.DTOs.Reponse.UserResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.UserPatchRequestDTO;
import br.com.geac.backend.Aplication.Services.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/admin/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity <List<UserResponseDTO>> getAllUsers(){
        return ResponseEntity.ok(userService.getAllUsers());
    }
    @GetMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity <UserResponseDTO> getById(@PathVariable UUID id){
        return ResponseEntity.ok(userService.getUserById(id));
    }
    @PatchMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<UserResponseDTO> updateUserInfo(@PathVariable UUID id, @RequestBody UserPatchRequestDTO requestDTO){
        return ResponseEntity.ok(userService.updateUser(id,requestDTO));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteUser(@PathVariable UUID id){
        userService.deleteUser(id);
        return ResponseEntity.noContent().build();
    }

}

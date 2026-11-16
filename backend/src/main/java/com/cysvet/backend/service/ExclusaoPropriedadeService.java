package com.cysvet.backend.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.cysvet.backend.entity.Propriedade;
import com.cysvet.backend.entity.Usuario;

import lombok.RequiredArgsConstructor;

/**
 * Excluir a propriedade leva junto os animais ativos dela (exclusao logica: ficam INATIVO e o
 * historico continua no banco). Fica fora do PropriedadeService porque o AnimalService ja depende dele.
 */
@Service
@RequiredArgsConstructor
public class ExclusaoPropriedadeService {

    private final PropriedadeService propriedadeService;
    private final AnimalService animalService;
    private final UsuarioAutenticadoProvider authenticatedUserProvider;

    @Transactional
    public void excluir(Long id) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        Propriedade property = propriedadeService.getEntity(id);
        propriedadeService.delete(id);
        animalService.inativarAnimaisDaPropriedade(property.getId(), user);
    }

    @Transactional
    public void excluirPorIdExterno(String idExterno, Usuario user) {
        Propriedade property = propriedadeService.getByExternalId(idExterno);
        propriedadeService.deleteByExternalId(idExterno, user);
        animalService.inativarAnimaisDaPropriedade(property.getId(), user);
    }
}

package com.cysvet.backend.service;

import com.cysvet.backend.entity.MutacaoCliente;
import com.cysvet.backend.repository.MutacaoClienteRepository;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class IdempotencyService {

    private final MutacaoClienteRepository clientMutationRepository;

    public Optional<MutacaoCliente> findByMutationKey(String chaveMutacao) {
        return clientMutationRepository.findByChaveMutacao(chaveMutacao);
    }

    public void register(String chaveMutacao, String nomeEntidade, Long idUsuario, Long idEntidade) {
        MutacaoCliente mutation = new MutacaoCliente();
        mutation.setChaveMutacao(chaveMutacao);
        mutation.setNomeEntidade(nomeEntidade);
        mutation.setIdUsuario(idUsuario);
        mutation.setIdEntidade(idEntidade);
        clientMutationRepository.save(mutation);
    }
}

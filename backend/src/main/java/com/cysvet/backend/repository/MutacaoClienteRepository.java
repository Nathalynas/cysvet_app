package com.cysvet.backend.repository;

import com.cysvet.backend.entity.MutacaoCliente;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MutacaoClienteRepository extends JpaRepository<MutacaoCliente, Long> {

    Optional<MutacaoCliente> findByChaveMutacao(String chaveMutacao);
}

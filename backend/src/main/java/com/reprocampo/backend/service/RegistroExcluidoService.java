package com.reprocampo.backend.service;

import com.reprocampo.backend.dto.sync.RegistroExcluidoResponse;
import com.reprocampo.backend.entity.RegistroExcluido;
import com.reprocampo.backend.repository.RegistroExcluidoRepository;
import java.time.Instant;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class RegistroExcluidoService {

    private final RegistroExcluidoRepository deletedRecordRepository;

    @Transactional
    public void registerDeletion(String nomeEntidade, String idExterno, Long idUsuario) {
        RegistroExcluido deletedRecord = deletedRecordRepository
                .findByIdUsuarioAndNomeEntidadeAndIdExterno(idUsuario, nomeEntidade, idExterno)
                .orElseGet(RegistroExcluido::new);

        deletedRecord.setNomeEntidade(nomeEntidade);
        deletedRecord.setIdExterno(idExterno);
        deletedRecord.setIdUsuario(idUsuario);
        deletedRecord.setDataExclusao(Instant.now());
        deletedRecordRepository.save(deletedRecord);
    }

    @Transactional
    public void clearDeletionMarker(String nomeEntidade, String idExterno, Long idUsuario) {
        deletedRecordRepository.findByIdUsuarioAndNomeEntidadeAndIdExterno(idUsuario, nomeEntidade, idExterno)
                .ifPresent(deletedRecordRepository::delete);
    }

    @Transactional(readOnly = true)
    public List<RegistroExcluidoResponse> findDeletedSince(Long idUsuario, Instant since) {
        return deletedRecordRepository.findAllByIdUsuarioAndDataAtualizacaoAfterOrderByDataAtualizacaoAsc(idUsuario, since).stream()
                .map(record -> new RegistroExcluidoResponse(record.getNomeEntidade(), record.getIdExterno(), record.getDataExclusao()))
                .toList();
    }
}

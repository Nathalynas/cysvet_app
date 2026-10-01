package com.cysvet.backend.service;

import com.cysvet.backend.dto.sync.RegistroExcluidoResponse;
import com.cysvet.backend.entity.RegistroExcluido;
import com.cysvet.backend.repository.RegistroExcluidoRepository;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class RegistroExcluidoService {

    private final RegistroExcluidoRepository deletedRecordRepository;

    @Transactional
    public void registerDeletion(String nomeEntidade, String idExterno, Long idUsuario) {
        registerDeletions(nomeEntidade, List.of(idExterno), idUsuario);
    }

    // Uma visita remove centenas de eventos de uma vez: os marcadores existentes
    // sao lidos numa consulta so, em vez de uma por evento.
    @Transactional
    public void registerDeletions(String nomeEntidade, Collection<String> idsExternos, Long idUsuario) {
        if (idsExternos.isEmpty()) {
            return;
        }
        Map<String, RegistroExcluido> existentes = deletedRecordRepository
                .findAllByNomeEntidadeAndIdExternoIn(nomeEntidade, idsExternos).stream()
                .collect(Collectors.toMap(RegistroExcluido::getIdExterno, Function.identity(), (a, b) -> a));

        for (String idExterno : idsExternos) {
            RegistroExcluido deletedRecord = existentes.computeIfAbsent(idExterno, id -> new RegistroExcluido());
            deletedRecord.setNomeEntidade(nomeEntidade);
            deletedRecord.setIdExterno(idExterno);
            deletedRecord.setIdUsuario(idUsuario);
            deletedRecord.setDataExclusao(Instant.now());
            deletedRecordRepository.save(deletedRecord);
        }
    }

    // Atualiza o marcador para ele voltar no proximo pull: o aparelho que editou
    // offline um registro ja excluido pode estar com checkpoint posterior a exclusao.
    @Transactional
    public boolean reannounceDeletion(String nomeEntidade, String idExterno) {
        return deletedRecordRepository.findByNomeEntidadeAndIdExterno(nomeEntidade, idExterno)
                .map(deletedRecord -> {
                    deletedRecord.setDataAtualizacao(Instant.now());
                    return true;
                })
                .orElse(false);
    }

    @Transactional
    public void clearDeletionMarker(String nomeEntidade, String idExterno) {
        clearDeletionMarkers(nomeEntidade, List.of(idExterno));
    }

    @Transactional
    public void clearDeletionMarkers(String nomeEntidade, Collection<String> idsExternos) {
        if (!idsExternos.isEmpty()) {
            deletedRecordRepository.deleteAllByNomeEntidadeAndIdExternoIn(nomeEntidade, idsExternos);
        }
    }

    @Transactional(readOnly = true)
    public List<RegistroExcluidoResponse> findDeletedSince(Instant since) {
        return deletedRecordRepository.findAllByDataAtualizacaoAfterOrderByDataAtualizacaoAsc(since).stream()
                .map(record -> new RegistroExcluidoResponse(record.getNomeEntidade(), record.getIdExterno(), record.getDataExclusao()))
                .toList();
    }
}

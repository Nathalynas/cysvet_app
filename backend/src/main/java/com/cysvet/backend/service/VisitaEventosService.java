package com.cysvet.backend.service;

import com.cysvet.backend.dto.sync.SyncEntityNames;
import com.cysvet.backend.dto.visita.VisitaAnimalItemDto;
import com.cysvet.backend.entity.Animal;
import com.cysvet.backend.entity.EventoReprodutivo;
import com.cysvet.backend.entity.StatusReprodutivoAnimal;
import com.cysvet.backend.entity.TipoEventoReprodutivo;
import com.cysvet.backend.entity.Visita;
import com.cysvet.backend.repository.AnimalRepository;
import com.cysvet.backend.repository.EventoReprodutivoRepository;
import com.cysvet.backend.repository.VisitaRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Transforma a coleta de cada animal da visita em eventos reprodutivos e
 * recalcula o resumo dos animais afetados.
 *
 * <p>Os eventos pertencem a visita (coluna id_visita) e tem idExterno
 * deterministico, derivado da visita, do animal e do tipo. Assim o reenvio da
 * mesma visita pelo sync atualiza os mesmos eventos em vez de duplica-los.
 */
@Service
@RequiredArgsConstructor
public class VisitaEventosService {

    // Tipos que representam um fato unico do animal: se outra visita ou um
    // registro direto ja tem o mesmo fato na mesma data, nao e criado outro.
    private static final Set<TipoEventoReprodutivo> FATOS_UNICOS = Set.of(
            TipoEventoReprodutivo.INSEMINATION,
            TipoEventoReprodutivo.CALVING,
            TipoEventoReprodutivo.DRY_OFF
    );
    private static final int LIMITE_OBSERVACOES = 2000;

    private final EventoReprodutivoRepository eventoReprodutivoRepository;
    private final AnimalRepository animalRepository;
    private final VisitaRepository visitaRepository;
    private final ResumoReprodutivoAnimalService resumoReprodutivoAnimalService;
    private final RegistroExcluidoService deletedRecordService;
    private final ObjectMapper objectMapper;

    @Transactional
    public void regenerar(Visita visita) {
        Map<Long, Animal> afetados = new LinkedHashMap<>();
        Set<FatoUnico> removidos = regenerarSemPropagar(visita, afetados);
        recriarEmOutrasVisitas(visita, removidos, afetados);
        recalcular(afetados);
    }

    @Transactional
    public void removerDaVisita(Visita visita, Long idUsuario) {
        Map<Long, Animal> afetados = new LinkedHashMap<>();
        Set<FatoUnico> removidos = new HashSet<>();
        for (EventoReprodutivo evento : eventoReprodutivoRepository.findAllByVisitaId(visita.getId())) {
            FatoUnico.de(evento).ifPresent(removidos::add);
            remover(evento, idUsuario, afetados);
        }
        eventoReprodutivoRepository.flush();
        recriarEmOutrasVisitas(visita, removidos, afetados);
        recalcular(afetados);
    }

    private Set<FatoUnico> regenerarSemPropagar(Visita visita, Map<Long, Animal> afetados) {
        Map<String, EventoReprodutivo> existentes = new LinkedHashMap<>();
        for (EventoReprodutivo evento : eventoReprodutivoRepository.findAllByVisitaId(visita.getId())) {
            existentes.put(evento.getIdExterno(), evento);
            afetados.put(evento.getAnimal().getId(), evento.getAnimal());
        }

        IndiceDeAnimais animais = new IndiceDeAnimais(
                animalRepository.findAllByPropriedadeIdOrderByCodigoAsc(visita.getPropriedade().getId()));
        Set<String> processados = new HashSet<>();

        for (VisitaAnimalItemDto item : lerItens(visita)) {
            Animal animal = animais.resolver(item);
            if (animal == null) {
                continue;
            }
            for (EventoGerado gerado : gerar(visita, item, animal)) {
                if (!processados.add(gerado.idExterno())) {
                    continue;
                }
                EventoReprodutivo evento = existentes.remove(gerado.idExterno());
                if (evento == null) {
                    if (FATOS_UNICOS.contains(gerado.tipo())
                            && eventoReprodutivoRepository.existsByAnimalIdAndTipoAndDataEvento(
                                    animal.getId(), gerado.tipo(), gerado.data())) {
                        continue;
                    }
                    evento = new EventoReprodutivo();
                    evento.setIdExterno(gerado.idExterno());
                    evento.setVisita(visita);
                }
                preencher(evento, visita, animal, gerado);
                eventoReprodutivoRepository.save(evento);
                deletedRecordService.clearDeletionMarker(SyncEntityNames.EVENT, evento.getIdExterno());
                afetados.put(animal.getId(), animal);
            }
        }

        Set<FatoUnico> removidos = new HashSet<>();
        for (EventoReprodutivo sobra : existentes.values()) {
            FatoUnico.de(sobra).ifPresent(removidos::add);
            remover(sobra, visita.getUsuario().getId(), afetados);
        }
        eventoReprodutivoRepository.flush();
        return removidos;
    }

    // Um fato unico (ex.: a IA de 10/05) informado por varias visitas fica com a
    // primeira que o registrou. Quando ele e removido, a visita mais recente que
    // tambem o informa passa a ser a dona. So esses eventos sao recriados e so
    // os animais deles recalculados; regenerar as visitas inteiras recalculava o
    // rebanho todo para recriar um ou dois eventos.
    private void recriarEmOutrasVisitas(Visita visita, Set<FatoUnico> removidos, Map<Long, Animal> afetados) {
        if (removidos.isEmpty()) {
            return;
        }
        Set<Long> animaisDosFatos = new HashSet<>();
        removidos.forEach(fato -> animaisDosFatos.add(fato.idAnimal()));
        IndiceDeAnimais animais = new IndiceDeAnimais(
                animalRepository.findAllByPropriedadeIdOrderByCodigoAsc(visita.getPropriedade().getId()));

        for (Visita outra : visitaRepository.findAllByPropriedadeIdOrderByDataVisitaDesc(visita.getPropriedade().getId())) {
            if (outra.getId().equals(visita.getId())) {
                continue;
            }
            for (VisitaAnimalItemDto item : lerItens(outra)) {
                Animal animal = animais.resolver(item);
                if (animal == null || !animaisDosFatos.contains(animal.getId())) {
                    continue;
                }
                for (EventoGerado gerado : gerar(outra, item, animal)) {
                    if (!removidos.contains(new FatoUnico(animal.getId(), gerado.tipo(), gerado.data()))
                            || eventoReprodutivoRepository.existsByAnimalIdAndTipoAndDataEvento(
                                    animal.getId(), gerado.tipo(), gerado.data())) {
                        continue;
                    }
                    EventoReprodutivo evento = eventoReprodutivoRepository.findByIdExterno(gerado.idExterno())
                            .orElseGet(EventoReprodutivo::new);
                    evento.setIdExterno(gerado.idExterno());
                    evento.setVisita(outra);
                    preencher(evento, outra, animal, gerado);
                    eventoReprodutivoRepository.save(evento);
                    deletedRecordService.clearDeletionMarker(SyncEntityNames.EVENT, evento.getIdExterno());
                    afetados.put(animal.getId(), animal);
                }
            }
        }
    }

    private List<EventoGerado> gerar(Visita visita, VisitaAnimalItemDto item, Animal animal) {
        List<EventoGerado> eventos = new ArrayList<>();

        if (item.dataUltimoParto() != null) {
            eventos.add(evento(visita, animal, TipoEventoReprodutivo.CALVING, item.dataUltimoParto(), Map.of(), null));
        }
        if (item.dataUltimaIa() != null) {
            Map<String, Object> detalhes = new LinkedHashMap<>();
            if (item.numeroIaRecebida() != null) {
                detalhes.put("numeroIa", item.numeroIaRecebida());
            }
            eventos.add(evento(visita, animal, TipoEventoReprodutivo.INSEMINATION, item.dataUltimaIa(), detalhes, null));
        }
        if (item.dataSecagemEfetiva() != null) {
            eventos.add(evento(visita, animal, TipoEventoReprodutivo.DRY_OFF, item.dataSecagemEfetiva(), Map.of(), null));
        }

        StatusReprodutivoAnimal status = statusInformado(item.situacaoReprodutiva());
        if (status != null) {
            Map<String, Object> detalhes = new LinkedHashMap<>();
            detalhes.put("status", status.getValue());
            putIfPresent(detalhes, "situacaoProdutiva", item.situacaoProdutiva());
            putIfPresent(detalhes, "diagnostico", item.diagnostico());
            eventos.add(evento(visita, animal, TipoEventoReprodutivo.REPRODUCTIVE_STATUS_CHECK,
                    visita.getDataVisita(), detalhes, textoOuNulo(item.decisao())));
        }
        return eventos;
    }

    private EventoGerado evento(Visita visita, Animal animal, TipoEventoReprodutivo tipo, LocalDate data,
                                Map<String, Object> detalhes, String observacoes) {
        String chave = "visita|" + visita.getIdExterno() + "|" + animal.getIdExterno() + "|" + tipo.name();
        String idExterno = UUID.nameUUIDFromBytes(chave.getBytes(StandardCharsets.UTF_8)).toString();
        return new EventoGerado(idExterno, tipo, data, detalhes, observacoes);
    }

    private void preencher(EventoReprodutivo evento, Visita visita, Animal animal, EventoGerado gerado) {
        evento.setPropriedade(visita.getPropriedade());
        evento.setAnimal(animal);
        evento.setUsuario(visita.getUsuario());
        evento.setTipo(gerado.tipo());
        evento.setDataEvento(gerado.data());
        evento.setDataPrevistaParto(EventoReprodutivoService.previsaoDeParto(gerado.tipo(), gerado.data()));
        evento.setPrenhezConfirmada(null);
        evento.setObservacoes(gerado.observacoes());
        evento.setDetalhesJson(escreverDetalhes(gerado.detalhes()));
    }

    private void remover(EventoReprodutivo evento, Long idUsuario, Map<Long, Animal> afetados) {
        afetados.put(evento.getAnimal().getId(), evento.getAnimal());
        eventoReprodutivoRepository.delete(evento);
        deletedRecordService.registerDeletion(SyncEntityNames.EVENT, evento.getIdExterno(), idUsuario);
    }

    private void recalcular(Map<Long, Animal> afetados) {
        afetados.values().forEach(resumoReprodutivoAnimalService::recalcular);
    }

    private StatusReprodutivoAnimal statusInformado(String situacaoReprodutiva) {
        String valor = textoOuNulo(situacaoReprodutiva);
        if (valor == null) {
            return null;
        }
        try {
            return StatusReprodutivoAnimal.fromValue(valor);
        } catch (IllegalArgumentException exception) {
            // Texto livre fora da lista de situacoes: continua so na visita.
            return null;
        }
    }

    private List<VisitaAnimalItemDto> lerItens(Visita visita) {
        if (visita.getAnimaisJson() == null || visita.getAnimaisJson().isBlank()) {
            return List.of();
        }
        try {
            return objectMapper.readValue(visita.getAnimaisJson(), new TypeReference<List<VisitaAnimalItemDto>>() {
            });
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Falha ao ler animais da visita " + visita.getIdExterno(), exception);
        }
    }

    private String escreverDetalhes(Map<String, Object> detalhes) {
        if (detalhes.isEmpty()) {
            return null;
        }
        try {
            return objectMapper.writeValueAsString(detalhes);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Falha ao gravar detalhes do evento da visita", exception);
        }
    }

    private static void putIfPresent(Map<String, Object> detalhes, String chave, String valor) {
        String texto = textoOuNulo(valor);
        if (texto != null) {
            detalhes.put(chave, texto);
        }
    }

    private static String textoOuNulo(String valor) {
        if (valor == null || valor.isBlank()) {
            return null;
        }
        String texto = valor.trim();
        return texto.length() > LIMITE_OBSERVACOES ? texto.substring(0, LIMITE_OBSERVACOES) : texto;
    }

    private record FatoUnico(Long idAnimal, TipoEventoReprodutivo tipo, LocalDate data) {
        static Optional<FatoUnico> de(EventoReprodutivo evento) {
            return FATOS_UNICOS.contains(evento.getTipo())
                    ? Optional.of(new FatoUnico(evento.getAnimal().getId(), evento.getTipo(), evento.getDataEvento()))
                    : Optional.empty();
        }
    }

    private record EventoGerado(
            String idExterno,
            TipoEventoReprodutivo tipo,
            LocalDate data,
            Map<String, Object> detalhes,
            String observacoes
    ) {
    }

    // O item da visita referencia o animal por id, idExterno ou codigo (brinco),
    // nesta ordem de preferencia, sempre dentro da propriedade visitada.
    private static final class IndiceDeAnimais {
        private final Map<Long, Animal> porId = new HashMap<>();
        private final Map<String, Animal> porIdExterno = new HashMap<>();
        private final Map<String, Animal> porCodigo = new HashMap<>();

        private IndiceDeAnimais(List<Animal> animais) {
            for (Animal animal : animais) {
                porId.put(animal.getId(), animal);
                porIdExterno.put(animal.getIdExterno(), animal);
                porCodigo.put(normalizarCodigo(animal.getCodigo()), animal);
            }
        }

        private Animal resolver(VisitaAnimalItemDto item) {
            if (item.animalId() != null && porId.containsKey(item.animalId())) {
                return porId.get(item.animalId());
            }
            if (item.animalIdExterno() != null && porIdExterno.containsKey(item.animalIdExterno().trim())) {
                return porIdExterno.get(item.animalIdExterno().trim());
            }
            if (item.animalCodigo() != null && !item.animalCodigo().isBlank()) {
                return porCodigo.get(normalizarCodigo(item.animalCodigo()));
            }
            return null;
        }

        private static String normalizarCodigo(String codigo) {
            return codigo == null ? "" : codigo.trim().toUpperCase(Locale.ROOT);
        }
    }
}

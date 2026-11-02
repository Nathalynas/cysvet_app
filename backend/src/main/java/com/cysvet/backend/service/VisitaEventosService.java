package com.cysvet.backend.service;

import com.cysvet.backend.dto.sync.SyncEntityNames;
import com.cysvet.backend.dto.visita.VisitaAnimalItemDto;
import com.cysvet.backend.entity.Animal;
import com.cysvet.backend.entity.EventoReprodutivo;
import com.cysvet.backend.entity.SituacaoProdutivaAnimal;
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
import java.util.Collection;
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
    static final int DIAS_MINIMOS_DG_ULTRASSOM = 28;
    static final int DIAS_MINIMOS_DG_PALPACAO = 45;
    private static final String METODO_ULTRASSOM = "ultrassom";
    private static final String METODO_PALPACAO = "palpacao";
    private static final Set<String> TIPOS_DE_PERDA = Set.of("reabsorcao", "aborto", "mumificacao", "natimorto");

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
        List<EventoReprodutivo> eventos = eventoReprodutivoRepository.findAllByVisitaId(visita.getId());
        Set<FatoUnico> removidos = new HashSet<>();
        eventos.forEach(evento -> FatoUnico.de(evento).ifPresent(removidos::add));
        remover(eventos, idUsuario, afetados);
        eventoReprodutivoRepository.flush();
        recriarEmOutrasVisitas(visita, removidos, afetados);
        recalcular(afetados);
    }

    // As consultas por animal e por evento (fato ja existe? marcador de exclusao?)
    // sao feitas uma vez para a visita inteira: com ~300 animais e 3 eventos cada,
    // consultar dentro do laco eram ~3 mil queries por visita sincronizada.
    private Set<FatoUnico> regenerarSemPropagar(Visita visita, Map<Long, Animal> afetados) {
        Map<String, EventoReprodutivo> existentes = new LinkedHashMap<>();
        for (EventoReprodutivo evento : eventoReprodutivoRepository.findAllByVisitaId(visita.getId())) {
            existentes.put(evento.getIdExterno(), evento);
            afetados.put(evento.getAnimal().getId(), evento.getAnimal());
        }

        IndiceDeAnimais animais = new IndiceDeAnimais(
                animalRepository.findAllByPropriedadeIdOrderByCodigoAsc(visita.getPropriedade().getId()));
        List<ItemDoAnimal> itens = new ArrayList<>();
        for (VisitaAnimalItemDto item : lerItens(visita)) {
            Animal animal = animais.resolver(item);
            if (animal != null) {
                itens.add(new ItemDoAnimal(item, animal));
            }
        }

        Set<FatoUnico> fatosGravados = fatosDosAnimais(itens.stream().map(i -> i.animal().getId()).toList());
        Set<String> processados = new HashSet<>();
        List<String> gravados = new ArrayList<>();

        for (ItemDoAnimal itemDoAnimal : itens) {
            Animal animal = itemDoAnimal.animal();
            for (EventoGerado gerado : gerar(visita, itemDoAnimal.item(), animal)) {
                if (!processados.add(gerado.idExterno())) {
                    continue;
                }
                FatoUnico fato = new FatoUnico(animal.getId(), gerado.tipo(), gerado.data());
                EventoReprodutivo evento = existentes.remove(gerado.idExterno());
                if (evento == null) {
                    if (FATOS_UNICOS.contains(gerado.tipo()) && fatosGravados.contains(fato)) {
                        continue;
                    }
                    evento = new EventoReprodutivo();
                    evento.setIdExterno(gerado.idExterno());
                    evento.setVisita(visita);
                }
                preencher(evento, visita, animal, gerado);
                eventoReprodutivoRepository.save(evento);
                if (FATOS_UNICOS.contains(gerado.tipo())) {
                    fatosGravados.add(fato);
                }
                gravados.add(evento.getIdExterno());
                afetados.put(animal.getId(), animal);
            }
        }
        deletedRecordService.clearDeletionMarkers(SyncEntityNames.EVENT, gravados);

        Set<FatoUnico> removidos = new HashSet<>();
        existentes.values().forEach(sobra -> FatoUnico.de(sobra).ifPresent(removidos::add));
        remover(existentes.values(), visita.getUsuario().getId(), afetados);
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

        // Candidatos na ordem de preferencia (visita mais recente primeiro).
        List<Candidato> candidatos = new ArrayList<>();
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
                    FatoUnico fato = new FatoUnico(animal.getId(), gerado.tipo(), gerado.data());
                    if (removidos.contains(fato)) {
                        candidatos.add(new Candidato(outra, animal, gerado, fato));
                    }
                }
            }
        }
        if (candidatos.isEmpty()) {
            return;
        }

        Set<FatoUnico> fatosGravados = fatosDosAnimais(animaisDosFatos);
        Map<String, EventoReprodutivo> porIdExterno = new HashMap<>();
        eventoReprodutivoRepository.findAllByIdExternoIn(
                        candidatos.stream().map(candidato -> candidato.gerado().idExterno()).distinct().toList())
                .forEach(evento -> porIdExterno.put(evento.getIdExterno(), evento));
        List<String> gravados = new ArrayList<>();

        for (Candidato candidato : candidatos) {
            if (fatosGravados.contains(candidato.fato())) {
                continue;
            }
            EventoGerado gerado = candidato.gerado();
            EventoReprodutivo evento = porIdExterno.computeIfAbsent(gerado.idExterno(), id -> new EventoReprodutivo());
            evento.setIdExterno(gerado.idExterno());
            evento.setVisita(candidato.visita());
            preencher(evento, candidato.visita(), candidato.animal(), gerado);
            eventoReprodutivoRepository.save(evento);
            fatosGravados.add(candidato.fato());
            gravados.add(evento.getIdExterno());
            afetados.put(candidato.animal().getId(), candidato.animal());
        }
        deletedRecordService.clearDeletionMarkers(SyncEntityNames.EVENT, gravados);
    }

    private Set<FatoUnico> fatosDosAnimais(Collection<Long> idsAnimais) {
        Set<FatoUnico> fatos = new HashSet<>();
        if (!idsAnimais.isEmpty()) {
            eventoReprodutivoRepository.findAllByAnimalIdIn(idsAnimais)
                    .forEach(evento -> FatoUnico.de(evento).ifPresent(fatos::add));
        }
        return fatos;
    }

    private List<EventoGerado> gerar(Visita visita, VisitaAnimalItemDto item, Animal animal) {
        List<EventoGerado> eventos = new ArrayList<>();

        // Fato com data depois da visita e erro de digitacao (ex.: IA em 2062):
        // nao vira evento, senao passaria a ser "o mais recente" para sempre.
        // A visita guarda o valor digitado; so o evento deixa de existir.
        if (item.informou("dataUltimoParto") && dataValida(item.dataUltimoParto(), visita)) {
            eventos.add(evento(visita, animal, TipoEventoReprodutivo.CALVING, item.dataUltimoParto(), Map.of(), null));
        }
        if (item.informou("dataUltimaIa") && dataValida(item.dataUltimaIa(), visita)) {
            Map<String, Object> detalhes = new LinkedHashMap<>();
            if (item.numeroIaRecebida() != null) {
                detalhes.put("numeroIa", item.numeroIaRecebida());
            }
            eventos.add(evento(visita, animal, TipoEventoReprodutivo.INSEMINATION, item.dataUltimaIa(), detalhes, null));
        }
        if (item.informou("dataSecagemEfetiva") && dataValida(item.dataSecagemEfetiva(), visita)) {
            eventos.add(evento(visita, animal, TipoEventoReprodutivo.DRY_OFF, item.dataSecagemEfetiva(), Map.of(), null));
        }

        // Situacao que veio do cache do aparelho sem o veterinario mexer nao vira
        // "situacao observada": senao uma visita offline com cache velho apagaria
        // o diagnostico mais novo de outro veterinario.
        StatusReprodutivoAnimal status = item.informou("situacaoReprodutiva")
                ? statusInformado(item.situacaoReprodutiva())
                : null;
        SituacaoProdutivaAnimal situacaoProdutiva = item.informou("situacaoProdutiva")
                ? SituacaoProdutivaAnimal.fromValueOrNull(item.situacaoProdutiva())
                : null;
        if (status == StatusReprodutivoAnimal.DRY) {
            // "Seca" na coluna reprodutiva e a situacao produtiva.
            status = null;
            if (situacaoProdutiva == null) {
                situacaoProdutiva = SituacaoProdutivaAnimal.SECA;
            }
        }
        if (status != null || situacaoProdutiva != null) {
            Map<String, Object> detalhes = new LinkedHashMap<>();
            if (status != null) {
                detalhes.put("status", status.getValue());
            }
            if (situacaoProdutiva != null) {
                detalhes.put("situacaoProdutiva", situacaoProdutiva.getValue());
            }
            putIfPresent(detalhes, "diagnostico", item.diagnostico());
            eventos.add(evento(visita, animal, TipoEventoReprodutivo.REPRODUCTIVE_STATUS_CHECK,
                    visita.getDataVisita(), detalhes, textoOuNulo(item.decisao())));
        }

        EventoGerado diagnostico = diagnosticoDeGestacao(visita, item, animal, status);
        if (diagnostico != null) {
            eventos.add(diagnostico);
        }
        EventoGerado perda = perdaGestacional(visita, item, animal);
        if (perda != null) {
            eventos.add(perda);
        }
        return eventos;
    }

    /**
     * "Prenha" ou "vazia" informada numa vaca com IA conhecida tambem e um
     * diagnostico de gestacao (DG), desde que ja tenha passado o tempo minimo
     * do metodo: {@value #DIAS_MINIMOS_DG_ULTRASSOM} dias por ultrassom,
     * {@value #DIAS_MINIMOS_DG_PALPACAO} por palpacao. Primeiro DG ou
     * reconfirmacao e deduzido na leitura (depende das outras visitas).
     */
    private EventoGerado diagnosticoDeGestacao(Visita visita, VisitaAnimalItemDto item, Animal animal,
                                               StatusReprodutivoAnimal status) {
        if (status != StatusReprodutivoAnimal.PREGNANT && status != StatusReprodutivoAnimal.EMPTY) {
            return null;
        }
        LocalDate ia = item.dataUltimaIa();
        if (ia == null || ia.isAfter(visita.getDataVisita())) {
            return null;
        }
        String metodo = metodoDiagnostico(item.metodoDiagnostico());
        long diasPosIa = java.time.temporal.ChronoUnit.DAYS.between(ia, visita.getDataVisita());
        int minimo = METODO_PALPACAO.equals(metodo) ? DIAS_MINIMOS_DG_PALPACAO : DIAS_MINIMOS_DG_ULTRASSOM;
        if (diasPosIa < minimo) {
            return null;
        }
        Map<String, Object> detalhes = new LinkedHashMap<>();
        detalhes.put("metodo", metodo);
        detalhes.put("diasPosIa", diasPosIa);
        detalhes.put("dataIa", ia.toString());
        EventoGerado base = evento(visita, animal, TipoEventoReprodutivo.PREGNANCY_DIAGNOSIS,
                visita.getDataVisita(), detalhes, null);
        return new EventoGerado(base.idExterno(), base.tipo(), base.data(), base.detalhes(), base.observacoes(),
                status == StatusReprodutivoAnimal.PREGNANT);
    }

    /** Perda informada pelo veterinario (reabsorcao, aborto, mumificacao, natimorto). */
    private EventoGerado perdaGestacional(Visita visita, VisitaAnimalItemDto item, Animal animal) {
        String tipo = tipoPerda(item.tipoPerda());
        if (tipo == null) {
            return null;
        }
        Map<String, Object> detalhes = new LinkedHashMap<>();
        detalhes.put("tipo", tipo);
        LocalDate ia = item.dataUltimaIa();
        if (ia != null && !ia.isAfter(visita.getDataVisita())) {
            detalhes.put("diasGestacao", java.time.temporal.ChronoUnit.DAYS.between(ia, visita.getDataVisita()));
        }
        putIfPresent(detalhes, "causaSuspeita", item.causaPerda());
        return evento(visita, animal, TipoEventoReprodutivo.GESTATIONAL_LOSS, visita.getDataVisita(), detalhes, null);
    }

    private static String metodoDiagnostico(String valor) {
        String normalizado = valor == null ? "" : com.cysvet.backend.util.Textos.semAcentos(valor)
                .trim().toLowerCase(java.util.Locale.ROOT);
        return normalizado.startsWith("palp") ? METODO_PALPACAO : METODO_ULTRASSOM;
    }

    private static String tipoPerda(String valor) {
        if (valor == null || valor.isBlank()) {
            return null;
        }
        String normalizado = com.cysvet.backend.util.Textos.semAcentos(valor).trim().toLowerCase(java.util.Locale.ROOT);
        return TIPOS_DE_PERDA.contains(normalizado) ? normalizado : "outra";
    }

    private static boolean dataValida(LocalDate data, Visita visita) {
        return data != null && !data.isAfter(visita.getDataVisita());
    }

    private EventoGerado evento(Visita visita, Animal animal, TipoEventoReprodutivo tipo, LocalDate data,
                                Map<String, Object> detalhes, String observacoes) {
        String chave = "visita|" + visita.getIdExterno() + "|" + animal.getIdExterno() + "|" + tipo.name();
        String idExterno = UUID.nameUUIDFromBytes(chave.getBytes(StandardCharsets.UTF_8)).toString();
        return new EventoGerado(idExterno, tipo, data, detalhes, observacoes, null);
    }

    private void preencher(EventoReprodutivo evento, Visita visita, Animal animal, EventoGerado gerado) {
        evento.setPropriedade(visita.getPropriedade());
        evento.setAnimal(animal);
        evento.setUsuario(visita.getUsuario());
        evento.setTipo(gerado.tipo());
        evento.setDataEvento(gerado.data());
        evento.setDataPrevistaParto(EventoReprodutivoService.previsaoDeParto(gerado.tipo(), gerado.data()));
        evento.setPrenhezConfirmada(gerado.prenhezConfirmada());
        evento.setObservacoes(gerado.observacoes());
        evento.setDetalhesJson(escreverDetalhes(gerado.detalhes()));
    }

    private void remover(Collection<EventoReprodutivo> eventos, Long idUsuario, Map<Long, Animal> afetados) {
        List<String> removidos = new ArrayList<>();
        for (EventoReprodutivo evento : eventos) {
            afetados.put(evento.getAnimal().getId(), evento.getAnimal());
            eventoReprodutivoRepository.delete(evento);
            removidos.add(evento.getIdExterno());
        }
        deletedRecordService.registerDeletions(SyncEntityNames.EVENT, removidos, idUsuario);
    }

    private void recalcular(Map<Long, Animal> afetados) {
        resumoReprodutivoAnimalService.recalcularTodos(afetados.values());
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

    private record ItemDoAnimal(VisitaAnimalItemDto item, Animal animal) {
    }

    private record Candidato(Visita visita, Animal animal, EventoGerado gerado, FatoUnico fato) {
    }

    private record EventoGerado(
            String idExterno,
            TipoEventoReprodutivo tipo,
            LocalDate data,
            Map<String, Object> detalhes,
            String observacoes,
            Boolean prenhezConfirmada
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

package com.cysvet.backend.service;

import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Objects;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.cysvet.backend.dto.animal.AnimalRequest;
import com.cysvet.backend.dto.animal.AnimalResponse;
import com.cysvet.backend.dto.sync.SyncEntityNames;
import com.cysvet.backend.entity.Animal;
import com.cysvet.backend.entity.AnimalHistorico;
import com.cysvet.backend.entity.Lote;
import com.cysvet.backend.entity.Propriedade;
import com.cysvet.backend.entity.StatusAnimal;
import com.cysvet.backend.entity.StatusReprodutivoAnimal;
import com.cysvet.backend.entity.TipoHistoricoAnimal;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.exception.ResourceNotFoundException;
import com.cysvet.backend.repository.AnimalRepository;
import com.cysvet.backend.repository.AnimalHistoricoRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class AnimalService {

    private final AnimalRepository animalRepository;
    private final AnimalHistoricoRepository animalHistoricoRepository;
    private final PropriedadeService propriedadeService;
    private final LoteService loteService;
    private final UsuarioAutenticadoProvider authenticatedUserProvider;
    private final RegistroExcluidoService deletedRecordService;
    private final ResumoReprodutivoAnimalService resumoReprodutivoAnimalService;

    @Transactional(readOnly = true)
    public List<AnimalResponse> list(Long idPropriedade, Long idLote, String search, String status) {
        List<Animal> animals = animalRepository.search(idPropriedade, idLote, normalizeSearch(search), parseStatus(status));
        return animals.stream().map(this::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<AnimalResponse> listUpdatedSince(Instant dataAtualizacao) {
        return animalRepository.findAllByDataAtualizacaoAfterOrderByDataAtualizacaoAsc(dataAtualizacao).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public Animal getEntity(Long id) {
        return animalRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Animal nao encontrado"));
    }

    @Transactional(readOnly = true)
    public Animal getByExternalId(String idExterno) {
        return animalRepository.findByIdExterno(idExterno)
                .orElseThrow(() -> new ResourceNotFoundException("Animal nao encontrado"));
    }

    @Transactional
    public AnimalResponse create(AnimalRequest request) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        Animal animal = new Animal();
        apply(animal, request, user);
        Animal saved = animalRepository.save(animal);
        registerHistory(saved, user, TipoHistoricoAnimal.CADASTRO, "Animal cadastrado.");
        deletedRecordService.clearDeletionMarker(SyncEntityNames.ANIMAL, saved.getIdExterno());
        return toResponse(saved);
    }

    @Transactional
    public AnimalResponse createOrUpdateFromImport(AnimalRequest request) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        Animal animal = animalRepository
                .findAllByPropriedadeIdAndCodigoIgnoreCaseOrderByIdAsc(request.idPropriedade(), request.codigo())
                .stream()
                .findFirst()
                .orElseGet(Animal::new);
        AnimalSnapshot previous = animal.getId() == null ? null : AnimalSnapshot.from(animal);
        String idExterno = animal.getId() == null ? request.idExterno() : animal.getIdExterno();

        apply(animal, request, user);
        animal.setIdExterno(idExterno);
        Animal saved = animalRepository.save(animal);
        resumoReprodutivoAnimalService.recalcular(saved);
        if (previous == null) {
            registerHistory(saved, user, TipoHistoricoAnimal.CADASTRO, "Animal cadastrado pela importação.");
        } else {
            registerChanges(previous, saved, user, "importação");
        }
        deletedRecordService.clearDeletionMarker(SyncEntityNames.ANIMAL, saved.getIdExterno());
        return toResponse(saved);
    }

    @Transactional
    public AnimalResponse update(Long id, AnimalRequest request) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        Animal animal = getEntity(id);
        AnimalSnapshot previous = AnimalSnapshot.from(animal);
        apply(animal, request, user);
        Animal saved = animalRepository.save(animal);
        resumoReprodutivoAnimalService.recalcular(saved);
        registerChanges(previous, saved, user, "cadastro");
        deletedRecordService.clearDeletionMarker(SyncEntityNames.ANIMAL, saved.getIdExterno());
        return toResponse(saved);
    }

    @Transactional
    public void delete(Long id) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        Animal animal = getEntity(id);
        updateStatus(animal, StatusAnimal.INATIVO, user);
    }

    @Transactional
    public AnimalResponse updateStatus(Long id, StatusAnimal status) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        Animal animal = getEntity(id);
        Animal saved = updateStatus(animal, status, user);
        return toResponse(saved);
    }

    @Transactional
    public SyncUpsertResult<Animal> upsertForSync(AnimalRequest request, Instant dataAtualizacaoCliente, Usuario user) {
        Animal animal = animalRepository.findByIdExterno(request.idExterno())
                .orElseGet(Animal::new);

        if (animal.getId() != null && dataAtualizacaoCliente != null && animal.getDataAtualizacao().isAfter(dataAtualizacaoCliente)) {
            return SyncUpsertResult.conflicted(animal);
        }

        AnimalSnapshot previous = animal.getId() == null ? null : AnimalSnapshot.from(animal);
        apply(animal, request, user);
        Animal saved = animalRepository.save(animal);
        resumoReprodutivoAnimalService.recalcular(saved);
        if (previous == null) {
            registerHistory(saved, user, TipoHistoricoAnimal.CADASTRO, "Animal cadastrado pela sincronização.");
        } else {
            registerChanges(previous, saved, user, "sincronização");
        }
        deletedRecordService.clearDeletionMarker(SyncEntityNames.ANIMAL, saved.getIdExterno());
        return SyncUpsertResult.applied(saved);
    }

    // Cadastros antigos podem ter o mesmo codigo repetido (a validacao veio
    // depois); a importacao nao sabe qual atualizar e recusa a linha.
    @Transactional(readOnly = true)
    public boolean hasRepeatedCode(Long idPropriedade, String codigo) {
        return animalRepository.findAllByPropriedadeIdAndCodigoIgnoreCaseOrderByIdAsc(idPropriedade, codigo).size() > 1;
    }

    @Transactional
    public void deleteByExternalId(String idExterno, Usuario user) {
        Animal animal = getByExternalId(idExterno);
        updateStatus(animal, StatusAnimal.INATIVO, user);
    }

    private void apply(Animal animal, AnimalRequest request, Usuario user) {
        Propriedade property = propriedadeService.resolve(request.idPropriedade(), request.idExternoPropriedade(), "Animal");
        Lote lote = resolveLote(request);

        if (lote != null && !lote.getPropriedade().getId().equals(property.getId())) {
            throw new IllegalArgumentException("Lote informado nao pertence a propriedade do animal");
        }
        ensureCodeIsUnique(animal, property, request.codigo());

        applyReproductiveBase(animal, request);

        animal.setIdExterno(request.idExterno());
        animal.setPropriedade(property);
        animal.setLote(lote);
        animal.setUsuario(user);
        animal.setCodigo(request.codigo());
        animal.setDataNascimento(request.dataNascimento());
        animal.setNumeroLactacao(request.numeroLactacao());
        animal.setDataUltimoParto(request.dataUltimoParto());
        animal.setDataInseminacao(request.dataInseminacao());
        animal.setTouroIa(request.touroIa());
        animal.setHistoricoReprodutivo(request.historicoReprodutivo());
        animal.setStatusReprodutivo(request.statusReprodutivo());
        if (request.status() != null) {
            animal.setStatus(request.status());
        } else if (animal.getStatus() == null) {
            animal.setStatus(StatusAnimal.ATIVO);
        }
    }

    // Codigo (brinco) e unico por propriedade, sem diferenciar maiusculas.
    // Animais inativos contam: reativar e o caminho, nao cadastrar de novo.
    private void ensureCodeIsUnique(Animal animal, Propriedade property, String codigo) {
        animalRepository.findAllByPropriedadeIdAndCodigoIgnoreCaseOrderByIdAsc(property.getId(), codigo).stream()
                .filter(other -> !other.getId().equals(animal.getId()))
                .findFirst()
                .ifPresent(other -> {
                    throw new IllegalArgumentException(other.getStatus() == StatusAnimal.INATIVO
                            ? "Ja existe um animal inativo com o codigo %s nesta propriedade; reative-o em vez de cadastrar de novo".formatted(codigo)
                            : "Ja existe um animal com o codigo %s nesta propriedade".formatted(codigo));
                });
    }

    // So os campos alterados pelo usuario viram base. O cliente reenvia o
    // resumo inteiro a cada edicao; tratar valores inalterados como correcao
    // faria a base sobrepor eventos que ainda estao chegando pelo sync.
    private void applyReproductiveBase(Animal animal, AnimalRequest request) {
        boolean isNew = animal.getId() == null;

        if (isNew
                || !Objects.equals(animal.getNumeroLactacao(), request.numeroLactacao())
                || !Objects.equals(animal.getDataUltimoParto(), request.dataUltimoParto())) {
            animal.setBaseNumeroLactacao(request.numeroLactacao());
            animal.setBaseDataUltimoParto(request.dataUltimoParto());
        }
        if (isNew
                || !Objects.equals(animal.getDataInseminacao(), request.dataInseminacao())
                || !Objects.equals(animal.getTouroIa(), request.touroIa())) {
            animal.setBaseDataInseminacao(request.dataInseminacao());
            animal.setBaseTouroIa(request.touroIa());
        }
        if (isNew || animal.getStatusReprodutivo() != request.statusReprodutivo()) {
            animal.setBaseStatusReprodutivo(request.statusReprodutivo());
            animal.setBaseStatusReprodutivoEm(Instant.now());
        }
    }

    private Lote resolveLote(AnimalRequest request) {
        if (request.idLote() != null) {
            return loteService.getEntity(request.idLote());
        }
        if (request.idExternoLote() != null && !request.idExternoLote().isBlank()) {
            return loteService.getByExternalId(request.idExternoLote());
        }
        return null;
    }

    private Animal updateStatus(Animal animal, StatusAnimal status, Usuario user) {
        StatusAnimal previousStatus = animal.getStatus();
        animal.setStatus(status);
        Animal saved = animalRepository.save(animal);
        if (!Objects.equals(previousStatus, saved.getStatus())) {
            registerHistory(
                    saved,
                    user,
                    TipoHistoricoAnimal.STATUS,
                    "Status alterado de %s para %s.".formatted(
                            statusLabel(previousStatus),
                            statusLabel(saved.getStatus())));
        }
        deletedRecordService.clearDeletionMarker(SyncEntityNames.ANIMAL, saved.getIdExterno());
        return saved;
    }

    private void registerChanges(AnimalSnapshot previous, Animal animal, Usuario user, String source) {
        if (!Objects.equals(previous.propriedadeId(), animal.getPropriedade().getId())) {
            registerHistory(animal, user, TipoHistoricoAnimal.MOVIMENTACAO,
                    "Propriedade alterada para %s.".formatted(animal.getPropriedade().getNome()));
        }
        if (!Objects.equals(previous.loteId(), loteId(animal))) {
            registerHistory(animal, user, TipoHistoricoAnimal.MOVIMENTACAO,
                    "Lote alterado de %s para %s.".formatted(previous.loteNome(), loteName(animal)));
        }
        if (!Objects.equals(previous.status(), animal.getStatus())) {
            registerHistory(animal, user, TipoHistoricoAnimal.STATUS,
                    "Status alterado de %s para %s.".formatted(
                            statusLabel(previous.status()),
                            statusLabel(animal.getStatus())));
        }
        if (!Objects.equals(previous.statusReprodutivo(), animal.getStatusReprodutivo())) {
            registerHistory(animal, user, TipoHistoricoAnimal.STATUS_REPRODUTIVO,
                    "Status reprodutivo alterado de %s para %s.".formatted(
                            reproductiveStatusLabel(previous.statusReprodutivo()),
                            reproductiveStatusLabel(animal.getStatusReprodutivo())));
        }
        if (previous.hasOtherChanges(animal)) {
            registerHistory(animal, user, TipoHistoricoAnimal.ATUALIZACAO,
                    "Dados do animal atualizados pela %s.".formatted(source));
        }
    }

    private void registerHistory(Animal animal, Usuario user, TipoHistoricoAnimal type, String description) {
        AnimalHistorico history = new AnimalHistorico();
        history.setAnimal(animal);
        history.setUsuario(user);
        history.setTipo(type);
        history.setDescricao(description);
        animalHistoricoRepository.save(history);
    }

    private Long loteId(Animal animal) {
        return animal.getLote() == null ? null : animal.getLote().getId();
    }

    private String loteName(Animal animal) {
        return animal.getLote() == null ? "Sem lote" : animal.getLote().getNome();
    }

    private String statusLabel(StatusAnimal status) {
        return status == null ? "Não informado" : status.name();
    }

    private String reproductiveStatusLabel(StatusReprodutivoAnimal status) {
        return status == null ? "Não informado" : status.getValue();
    }

    private record AnimalSnapshot(
            Long propriedadeId,
            Long loteId,
            String loteNome,
            String codigo,
            LocalDate dataNascimento,
            Integer numeroLactacao,
            LocalDate dataUltimoParto,
            LocalDate dataInseminacao,
            String touroIa,
            String historicoReprodutivo,
            StatusReprodutivoAnimal statusReprodutivo,
            StatusAnimal status
    ) {
        private static AnimalSnapshot from(Animal animal) {
            return new AnimalSnapshot(
                    animal.getPropriedade().getId(),
                    animal.getLote() == null ? null : animal.getLote().getId(),
                    animal.getLote() == null ? "Sem lote" : animal.getLote().getNome(),
                    animal.getCodigo(),
                    animal.getDataNascimento(),
                    animal.getNumeroLactacao(),
                    animal.getDataUltimoParto(),
                    animal.getDataInseminacao(),
                    animal.getTouroIa(),
                    animal.getHistoricoReprodutivo(),
                    animal.getStatusReprodutivo(),
                    animal.getStatus());
        }

        private boolean hasOtherChanges(Animal animal) {
            return !Objects.equals(codigo, animal.getCodigo())
                    || !Objects.equals(dataNascimento, animal.getDataNascimento())
                    || !Objects.equals(numeroLactacao, animal.getNumeroLactacao())
                    || !Objects.equals(dataUltimoParto, animal.getDataUltimoParto())
                    || !Objects.equals(dataInseminacao, animal.getDataInseminacao())
                    || !Objects.equals(touroIa, animal.getTouroIa())
                    || !Objects.equals(historicoReprodutivo, animal.getHistoricoReprodutivo());
        }
    }

    private StatusAnimal parseStatus(String status) {
        if (status == null || status.isBlank()) {
            return null;
        }
        return StatusAnimal.fromValue(status);
    }

    private String normalizeSearch(String search) {
        if (search == null || search.isBlank()) {
            return null;
        }
        return search.trim();
    }

    public AnimalResponse toResponse(Animal animal) {
        Long diasEmLactacao = animal.getDataUltimoParto() == null
                ? null
                : ChronoUnit.DAYS.between(animal.getDataUltimoParto(), LocalDate.now());

        return new AnimalResponse(
                animal.getId(),
                animal.getIdExterno(),
                animal.getPropriedade().getId(),
                animal.getPropriedade().getIdExterno(),
                animal.getLote() != null ? animal.getLote().getId() : null,
                animal.getLote() != null ? animal.getLote().getIdExterno() : null,
                animal.getLote() != null ? animal.getLote().getNome() : null,
                animal.getCodigo(),
                animal.getDataNascimento(),
                animal.getNumeroLactacao(),
                animal.getDataUltimoParto(),
                animal.getDataInseminacao(),
                animal.getTouroIa(),
                diasEmLactacao,
                animal.getHistoricoReprodutivo(),
                animal.getStatusReprodutivo(),
                animal.getStatus(),
                animal.getDataCriacao(),
                animal.getDataAtualizacao(),
                animal.getVersao()
        );
    }
}

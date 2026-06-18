package com.cysvet.backend.service;

import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.cysvet.backend.dto.animal.AnimalRequest;
import com.cysvet.backend.dto.animal.AnimalResponse;
import com.cysvet.backend.dto.sync.SyncEntityNames;
import com.cysvet.backend.entity.Animal;
import com.cysvet.backend.entity.Lote;
import com.cysvet.backend.entity.Propriedade;
import com.cysvet.backend.entity.StatusAnimal;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.exception.ResourceNotFoundException;
import com.cysvet.backend.repository.AnimalRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class AnimalService {

    private final AnimalRepository animalRepository;
    private final PropriedadeService propriedadeService;
    private final LoteService loteService;
    private final UsuarioAutenticadoProvider authenticatedUserProvider;
    private final RegistroExcluidoService deletedRecordService;

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
        deletedRecordService.clearDeletionMarker(SyncEntityNames.ANIMAL, saved.getIdExterno());
        return toResponse(saved);
    }

    @Transactional
    public AnimalResponse update(Long id, AnimalRequest request) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        Animal animal = getEntity(id);
        apply(animal, request, user);
        Animal saved = animalRepository.save(animal);
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

        apply(animal, request, user);
        Animal saved = animalRepository.save(animal);
        deletedRecordService.clearDeletionMarker(SyncEntityNames.ANIMAL, saved.getIdExterno());
        return SyncUpsertResult.applied(saved);
    }

    @Transactional
    public void deleteByExternalId(String idExterno, Usuario user) {
        Animal animal = getByExternalId(idExterno);
        updateStatus(animal, StatusAnimal.INATIVO, user);
    }

    private void apply(Animal animal, AnimalRequest request, Usuario user) {
        Propriedade property = resolveProperty(request.idPropriedade(), request.idExternoPropriedade());
        Lote lote = resolveLote(request);

        if (lote != null && !lote.getPropriedade().getId().equals(property.getId())) {
            throw new IllegalArgumentException("Lote informado nao pertence a propriedade do animal");
        }

        animal.setIdExterno(request.idExterno());
        animal.setPropriedade(property);
        animal.setLote(lote);
        animal.setUsuario(user);
        animal.setCodigo(request.codigo());
        animal.setCategoria(request.categoria());
        animal.setSexo(request.sexo());
        animal.setDataNascimento(request.dataNascimento());
        animal.setNumeroLactacao(request.numeroLactacao());
        animal.setDataUltimoParto(request.dataUltimoParto());
        animal.setDataInseminacao(request.dataInseminacao());
        animal.setHistoricoReprodutivo(request.historicoReprodutivo());
        animal.setStatusReprodutivo(request.statusReprodutivo());
        if (request.status() != null) {
            animal.setStatus(request.status());
        } else if (animal.getStatus() == null) {
            animal.setStatus(StatusAnimal.ATIVO);
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
        animal.setStatus(status);
        Animal saved = animalRepository.save(animal);
        deletedRecordService.clearDeletionMarker(SyncEntityNames.ANIMAL, saved.getIdExterno());
        return saved;
    }

    private Propriedade resolveProperty(Long idPropriedade, String idExternoPropriedade) {
        if (idPropriedade != null) {
            return propriedadeService.getEntity(idPropriedade);
        }
        if (idExternoPropriedade != null && !idExternoPropriedade.isBlank()) {
            return propriedadeService.getByExternalId(idExternoPropriedade);
        }
        throw new IllegalArgumentException("Animal deve informar idPropriedade ou idExternoPropriedade");
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
                animal.getCategoria(),
                animal.getSexo(),
                animal.getDataNascimento(),
                animal.getNumeroLactacao(),
                animal.getDataUltimoParto(),
                animal.getDataInseminacao(),
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

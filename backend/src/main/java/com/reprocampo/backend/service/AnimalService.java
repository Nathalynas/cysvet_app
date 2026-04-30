package com.reprocampo.backend.service;

import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.reprocampo.backend.dto.animal.AnimalRequest;
import com.reprocampo.backend.dto.animal.AnimalResponse;
import com.reprocampo.backend.entity.Animal;
import com.reprocampo.backend.entity.Propriedade;
import com.reprocampo.backend.entity.Usuario;
import com.reprocampo.backend.exception.ResourceNotFoundException;
import com.reprocampo.backend.repository.AnimalRepository;
import com.reprocampo.backend.repository.EventoReprodutivoRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class AnimalService {

    private final AnimalRepository animalRepository;
    private final EventoReprodutivoRepository reproductiveEventRepository;
    private final PropriedadeService propriedadeService;
    private final UsuarioAutenticadoProvider authenticatedUserProvider;
    private final RegistroExcluidoService deletedRecordService;

    @Transactional(readOnly = true)
    public List<AnimalResponse> list(Long idPropriedade) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        List<Animal> animals = idPropriedade == null
                ? animalRepository.findAllByUsuarioIdOrderByCodigoAsc(user.getId())
                : animalRepository.findAllByUsuarioIdAndPropriedadeIdOrderByCodigoAsc(user.getId(), idPropriedade);
        return animals.stream().map(this::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<AnimalResponse> listUpdatedSince(Long idUsuario, Instant dataAtualizacao) {
        return animalRepository.findAllByUsuarioIdAndDataAtualizacaoAfterOrderByDataAtualizacaoAsc(idUsuario, dataAtualizacao).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public Animal getEntity(Long id, Long idUsuario) {
        return animalRepository.findByIdAndUsuarioId(id, idUsuario)
                .orElseThrow(() -> new ResourceNotFoundException("Animal nao encontrado"));
    }

    @Transactional(readOnly = true)
    public Animal getByExternalId(String idExterno, Long idUsuario) {
        return animalRepository.findByIdExternoAndUsuarioId(idExterno, idUsuario)
                .orElseThrow(() -> new ResourceNotFoundException("Animal nao encontrado"));
    }

    @Transactional
    public AnimalResponse create(AnimalRequest request) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        Animal animal = new Animal();
        apply(animal, request, user);
        Animal saved = animalRepository.save(animal);
        deletedRecordService.clearDeletionMarker("animal", saved.getIdExterno(), user.getId());
        return toResponse(saved);
    }

    @Transactional
    public AnimalResponse update(Long id, AnimalRequest request) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        Animal animal = getEntity(id, user.getId());
        apply(animal, request, user);
        Animal saved = animalRepository.save(animal);
        deletedRecordService.clearDeletionMarker("animal", saved.getIdExterno(), user.getId());
        return toResponse(saved);
    }

    @Transactional
    public void delete(Long id) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        Animal animal = getEntity(id, user.getId());
        reproductiveEventRepository.findAllByUsuarioIdAndAnimalIdOrderByDataEventoDesc(user.getId(), animal.getId())
                .forEach(event -> {
                    reproductiveEventRepository.delete(event);
                    deletedRecordService.registerDeletion("event", event.getIdExterno(), user.getId());
                });
        animalRepository.delete(animal);
        deletedRecordService.registerDeletion("animal", animal.getIdExterno(), user.getId());
    }

    @Transactional
    public Animal upsertForSync(AnimalRequest request, Instant dataAtualizacaoCliente, Usuario user) {
        Animal animal = animalRepository.findByIdExternoAndUsuarioId(request.idExterno(), user.getId())
                .orElseGet(Animal::new);

        if (animal.getId() != null && dataAtualizacaoCliente != null && animal.getDataAtualizacao().isAfter(dataAtualizacaoCliente)) {
            return animal;
        }

        apply(animal, request, user);
        Animal saved = animalRepository.save(animal);
        deletedRecordService.clearDeletionMarker("animal", saved.getIdExterno(), user.getId());
        return saved;
    }

    @Transactional
    public void deleteByExternalId(String idExterno, Usuario user) {
        Animal animal = getByExternalId(idExterno, user.getId());
        reproductiveEventRepository.findAllByUsuarioIdAndAnimalIdOrderByDataEventoDesc(user.getId(), animal.getId())
                .forEach(event -> {
                    reproductiveEventRepository.delete(event);
                    deletedRecordService.registerDeletion("event", event.getIdExterno(), user.getId());
                });
        animalRepository.delete(animal);
        deletedRecordService.registerDeletion("animal", animal.getIdExterno(), user.getId());
    }

    private void apply(Animal animal, AnimalRequest request, Usuario user) {
        Propriedade property = request.idPropriedade() != null
                ? propriedadeService.getEntity(request.idPropriedade(), user.getId())
                : propriedadeService.getByExternalId(request.idExternoPropriedade(), user.getId());

        animal.setIdExterno(request.idExterno());
        animal.setPropriedade(property);
        animal.setUsuario(user);
        animal.setCodigo(request.codigo());
        animal.setCategoria(request.categoria());
        animal.setDataNascimento(request.dataNascimento());
        animal.setNumeroLactacao(request.numeroLactacao());
        animal.setDataUltimoParto(request.dataUltimoParto());
        animal.setHistoricoReprodutivo(request.historicoReprodutivo());
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
                animal.getCodigo(),
                animal.getCategoria(),
                animal.getDataNascimento(),
                animal.getNumeroLactacao(),
                animal.getDataUltimoParto(),
                diasEmLactacao,
                animal.getHistoricoReprodutivo(),
                animal.getDataCriacao(),
                animal.getDataAtualizacao(),
                animal.getVersao()
        );
    }
}

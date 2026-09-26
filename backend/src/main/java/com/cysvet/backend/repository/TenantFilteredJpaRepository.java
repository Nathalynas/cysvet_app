package com.cysvet.backend.repository;

import com.cysvet.backend.entity.TenantAwareEntity;
import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityNotFoundException;
import java.util.Optional;
import org.springframework.data.jpa.repository.support.JpaEntityInformation;
import org.springframework.data.jpa.repository.support.SimpleJpaRepository;
import org.springframework.util.Assert;

/**
 * Base de todos os repositorios. Para entidades de empresa, a busca por id vira
 * uma consulta JPQL.
 *
 * <p>O isolamento entre empresas usa o {@code @TenantId} do Hibernate, que e
 * aplicado como filtro. Filtros valem para consultas, mas nao para o
 * carregamento direto por id ({@code EntityManager.find}); sem esta classe, um
 * usuario conseguia ler e alterar registros de outra empresa informando o id.
 */
public class TenantFilteredJpaRepository<T, ID> extends SimpleJpaRepository<T, ID> {

    private final JpaEntityInformation<T, ?> entityInformation;
    private final EntityManager entityManager;
    private final boolean tenantAware;

    public TenantFilteredJpaRepository(JpaEntityInformation<T, ?> entityInformation, EntityManager entityManager) {
        super(entityInformation, entityManager);
        this.entityInformation = entityInformation;
        this.entityManager = entityManager;
        this.tenantAware = TenantAwareEntity.class.isAssignableFrom(entityInformation.getJavaType());
    }

    @Override
    public Optional<T> findById(ID id) {
        if (!tenantAware) {
            return super.findById(id);
        }
        Assert.notNull(id, "O id nao pode ser nulo");

        String jpql = "select e from %s e where e.%s = :id".formatted(
                entityInformation.getEntityName(),
                entityInformation.getRequiredIdAttribute().getName());
        return entityManager.createQuery(jpql, getDomainClass())
                .setParameter("id", id)
                .getResultStream()
                .findFirst();
    }

    @Override
    public boolean existsById(ID id) {
        return tenantAware ? findById(id).isPresent() : super.existsById(id);
    }

    // A referencia preguicosa seria carregada depois por id, sem o filtro.
    @Override
    public T getReferenceById(ID id) {
        if (!tenantAware) {
            return super.getReferenceById(id);
        }
        return findById(id).orElseThrow(() -> new EntityNotFoundException(
                "%s %s nao encontrado".formatted(entityInformation.getEntityName(), id)));
    }
}

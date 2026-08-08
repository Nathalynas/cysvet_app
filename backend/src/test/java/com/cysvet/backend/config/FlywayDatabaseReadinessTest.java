package com.cysvet.backend.config;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.UUID;
import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.output.MigrateResult;
import org.junit.jupiter.api.Test;

class FlywayDatabaseReadinessTest {

    private static final String MIGRATION_LOCATION = "classpath:db/migration";

    @Test
    void shouldBuildLatestSchemaFromZero() throws Exception {
        String jdbcUrl = newJdbcUrl("zero");

        MigrateResult result = Flyway.configure()
                .dataSource(jdbcUrl, "sa", "")
                .locations(MIGRATION_LOCATION)
                .baselineOnMigrate(true)
                .load()
                .migrate();

        assertThat(result.success).isTrue();
        assertThat(result.migrationsExecuted).isEqualTo(9);

        try (Connection connection = DriverManager.getConnection(jdbcUrl, "sa", "")) {
            assertTableExists(connection, "empresa");
            assertTableExists(connection, "usuario_empresa");
            assertTableExists(connection, "lote");
            assertColumnExists(connection, "propriedade", "tenant_id");
            assertColumnExists(connection, "propriedade", "status");
            assertColumnExists(connection, "animal", "status_reprodutivo");
            assertColumnExists(connection, "animal", "data_inseminacao");
            assertColumnExists(connection, "visita", "animais_json");
        }
    }

    @Test
    void shouldSupportIncrementalUpgrade() throws Exception {
        String jdbcUrl = newJdbcUrl("incremental");

        MigrateResult partial = Flyway.configure()
                .dataSource(jdbcUrl, "sa", "")
                .locations(MIGRATION_LOCATION)
                .target("3")
                .baselineOnMigrate(true)
                .load()
                .migrate();

        assertThat(partial.success).isTrue();
        assertThat(partial.migrationsExecuted).isEqualTo(3);

        MigrateResult full = Flyway.configure()
                .dataSource(jdbcUrl, "sa", "")
                .locations(MIGRATION_LOCATION)
                .baselineOnMigrate(true)
                .load()
                .migrate();

        assertThat(full.success).isTrue();
        assertThat(full.migrationsExecuted).isEqualTo(6);

        try (Connection connection = DriverManager.getConnection(jdbcUrl, "sa", "")) {
            assertColumnExists(connection, "animal", "id_lote");
            assertColumnExists(connection, "registro_excluido", "tenant_id");
            assertHistoryVersionExists(connection, "9");
        }
    }

    private static String newJdbcUrl(String suffix) {
        return "jdbc:h2:mem:flyway-" + suffix + "-" + UUID.randomUUID()
                + ";MODE=MySQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE";
    }

    private static void assertTableExists(Connection connection, String tableName) throws SQLException {
        assertThat(rowExists(connection,
                "SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = ?",
                tableName))
                .as("table %s should exist", tableName)
                .isTrue();
    }

    private static void assertColumnExists(Connection connection, String tableName, String columnName) throws SQLException {
        assertThat(rowExists(connection,
                "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = ? AND column_name = ?",
                tableName,
                columnName))
                .as("column %s.%s should exist", tableName, columnName)
                .isTrue();
    }

    private static void assertHistoryVersionExists(Connection connection, String version) throws SQLException {
        assertThat(rowExists(connection,
                "SELECT 1 FROM flyway_schema_history WHERE version = ?",
                version))
                .as("flyway version %s should exist", version)
                .isTrue();
    }

    private static boolean rowExists(Connection connection, String sql, String... params) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            for (int index = 0; index < params.length; index++) {
                statement.setString(index + 1, params[index]);
            }

            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next();
            }
        }
    }
}

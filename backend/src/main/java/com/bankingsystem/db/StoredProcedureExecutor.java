package com.bankingsystem.db;

import java.util.*;
import java.sql.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.ConnectionCallback;

@Component
public class StoredProcedureExecutor {
    private final JdbcTemplate jdbc;
    public StoredProcedureExecutor (JbdcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<Map<String , Object>> call(String proc , Object... args) {
        String ph = args.length == 0 ? "" : 
            String.join(", " , Collections.nCopies(args.length, "?"));     
        String sql = "{call dbo." + proc + "(" + ph + ")}";
        return jdbc.execute(new CallProcedure(sql , args));
    }

    // Execute call proc on a connection
    private static class CallProcedure implements ConnectionCallback<List<Map<String , Object>>> {
        private final String sql;
        private final Object[] args;

        public CallProcedure(String sql , Object[] args) {
            this.sql = sql;
            this.args = args;
        }

        @Override
        public List<Map<String , Object>> doInConnection(Connection con) throws SQLException {
            try (CallableStatement cs = con.prepareCall(sql)) {
                for (int i = 0; i < args.length; i++)
                    cs.setObject(i + 1, args[i]);
                if (!cs.execute()) return List.of();
                try (ResultSet rs = cs.executeQuery()) {
                    return Rows.toMaps(rs);
                }
            }
        }
    }

    public Map<String , Object> one (String proc , Object... args) {
        List<Map<String , Object>> rows = call(proc , args);
        if (rows.isEmpty()) return new IllegalStateException("No rows returned from stored procedure: " + proc);
        return rows.get(0);
    }

    public String message (Map<String , Object> row) {
        Object m = row.containtsKey("message") ? row.get("message") : row.get("result_message");
        return m == null ? null : m.toString();
    }
}
package com.bankingsystem.db;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.*;
import java.time.*;
import java.util.*; 

public final class Rows {
    private Rows() {}

    public static List<Map<String , Object>> toMaps (ResultSet rs) throws SQLException {
        ResultSetMetaData md = rs.getMetaData();
        int n = md.getColumnCount();
        List<Map<String , Object>> res = new ArrayList<>();
        
        while(rs.next()) {
            Map<String , Object> row = new LinkedHashMap<>();
            for (int i = 1; i <= n; i++)
                row.put(md.getColumnName(i), rs.getObject(i));
        
            res.add(row);
        }
        return res;
    }

    // SQL Server adding padding so we need to trim it
    // NCHAR(10)
    public static String str(Map<String , Object> m , String k) {
        Object v = m.get(k);
        return v == null ? null : v.toString().trim();
    }

    public static Long lng(Map<String , Object> m , String k) {
        Object v = m.get(k);
        return v == null ? null : ((Number) v).longValue();
    }
    public static BigDecimal money (Map<String , Object> m , String k) {
        Object v = m.get(k);
        return v == null ? null : ((BigDecimal) v).setScale(2, RoundingMode.HALF_UP);
    }
    public static LocalDateTime lt(Map<String , Object> m , String k) {
        Object v = m.get(k);
        return v == null ? null : ((Timestamp) v).toLocalDateTime();
    }
    public static LocalDate date(Map<String , Object> m , String k) {
        Object v = m.get(k);
        return v == null ? null : ((Date) v).toLocalDate();
    }
}
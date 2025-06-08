<%@ page contentType="application/json; charset=UTF-8" %>
<%@ page import="java.sql.*, java.util.Map, java.util.HashMap, com.google.gson.Gson" %>
<%@ include file="config.jsp" %>
<%
    response.setHeader("Cache-Control", "no-cache");
    String userId = (String) session.getAttribute("userId");
    if (userId == null) {
        response.setStatus(401);
        out.print("{\"error\": \"Not logged in\"}");
        return;
    }

    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        conn = con;
        sql = "SELECT id, email, displayName, photoURL FROM users WHERE id = ?"; // 修正：明確宣告 sql 變數
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, userId);
        rs = pstmt.executeQuery();

        Map<String, Object> userData = new HashMap<>(); // 修正：改用 userData 避免名稱衝突
        if (rs.next()) {
            userData.put("id", rs.getString("id"));
            userData.put("email", rs.getString("email"));
            userData.put("displayName", rs.getString("displayName"));
            userData.put("photoURL", rs.getString("photoURL"));
        } else {
            response.setStatus(404);
            out.print("{\"error\": \"User not found\"}");
            return;
        }

        Gson gson = new Gson();
        out.print(gson.toJson(userData)); // 修正：使用 userData
    } catch (Exception e) {
        response.setStatus(500);
        out.print("{\"error\": \"" + e.getMessage().replace("\"", "\\\"") + "\"}");
    } finally {
        try { if (rs != null) rs.close(); } catch (SQLException e) {}
        try { if (pstmt != null) pstmt.close(); } catch (SQLException e) {}
        // 不關閉共享連線，由 config.jsp 處理
    }
%>
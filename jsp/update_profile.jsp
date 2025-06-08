<%@ page contentType="application/json; charset=UTF-8" %>
<%@ page import="java.sql.*, java.io.*, org.json.JSONObject, com.google.gson.Gson" %>
<%@ include file="config.jsp" %>
<%
    request.setCharacterEncoding("UTF-8");
    response.setHeader("Cache-Control", "no-cache");
    String userId = (String) session.getAttribute("userId");
    if (userId == null) {
        response.setStatus(401);
        out.print("{\"status\": \"error\", \"message\": \"Not logged in\"}");
        return;
    }

    StringBuilder sb = new StringBuilder();
    String line;
    try (BufferedReader reader = request.getReader()) {
        while ((line = reader.readLine()) != null) {
            sb.append(line);
        }
    }
    JSONObject jsonInput = new JSONObject(sb.toString());
    String field = jsonInput.optString("field");
    String value = jsonInput.optString("value");

    if (field.isEmpty() || value.isEmpty()) {
        response.setStatus(400);
        out.print("{\"status\": \"error\", \"message\": \"Field or value cannot be empty\"}");
        return;
    }

    Connection conn = null;
    PreparedStatement pstmt = null;

    try {
        conn = con;
        if (field.equals("email")) {
            if (!value.matches("^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$")) {
                out.print("{\"status\": \"error\", \"message\": \"Invalid email format\"}");
                return;
            }
            sql = "UPDATE users SET email = ? WHERE id = ?";
        } else if (field.equals("displayName")) {
            sql = "UPDATE users SET displayName = ? WHERE id = ?";
        } else if (field.equals("photoURL")) {
            sql = "UPDATE users SET photoURL = ? WHERE id = ?";
        } else {
            response.setStatus(400);
            out.print("{\"status\": \"error\", \"message\": \"Invalid field\"}");
            return;
        }

        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, value);
        pstmt.setString(2, userId);
        int rows = pstmt.executeUpdate();

        if (rows > 0) {
            if (field.equals("email")) {
                session.setAttribute("userEmail", value);
            }
            out.print("{\"status\": \"success\"}");
        } else {
            response.setStatus(400);
            out.print("{\"status\": \"error\", \"message\": \"No user found or update failed\"}");
        }
    } catch (SQLException e) {
        response.setStatus(500);
        out.print("{\"status\": \"error\", \"message\": \"Database error: " + e.getMessage().replace("\"", "\\\"") + "\"}");
    } catch (Exception e) {
        response.setStatus(500);
        out.print("{\"status\": \"error\", \"message\": \"Server error: " + e.getMessage().replace("\"", "\\\"") + "\"}");
    } finally {
        try { if (pstmt != null) pstmt.close(); } catch (SQLException e) {}
        // 不關閉共享連線，由 config.jsp 處理
    }
%>
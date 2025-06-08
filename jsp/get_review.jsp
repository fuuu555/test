<%@ page import="java.sql.*, java.util.*, java.text.*" %>
<%@ page contentType="application/json; charset=UTF-8" %>
<%@ include file="config.jsp" %>
<%
    response.setCharacterEncoding("UTF-8");// 強制回傳內容編碼為 UTF-8 (Force response encoding to UTF-8)
    response.setContentType("application/json; charset=UTF-8");

      // 取得查詢參數 (Get query parameters)
    String productId = request.getParameter("productId");
    int pageNum = Integer.parseInt(request.getParameter("page") != null ? request.getParameter("page") : "1");
    int limit = Integer.parseInt(request.getParameter("limit") != null ? request.getParameter("limit") : "5");
    int offset = (pageNum - 1) * limit;

    // 建立 StringBuilder用來產生 JSON (StringBuilder for building JSON output)
    StringBuilder json = new StringBuilder();
    if (productId == null || productId.trim().isEmpty()) {
        response.setStatus(400);
        json.append("{\"error\":\"Missing or invalid productId\"}");
        out.print(json.toString());
        out.flush();
        return;
    }

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    try {
        conn = con; // 從 config.jsp 獲取共用資料庫連線 (Get DB connection from config.jsp)
        if (conn == null || conn.isClosed()) {
            throw new SQLException("Database connection is null or closed");
        }

        json.append("[");// 開始 JSON 陣列 (Start JSON array)
        sql = "SELECT r.id, r.userId, r.rating, r.content, r.date, u.displayName " +
              "FROM reviews r LEFT JOIN users u ON r.userId = u.id " +
              "WHERE r.productId = ? ORDER BY r.date DESC LIMIT ? OFFSET ?";
        ps = conn.prepareStatement(sql);
        ps.setString(1, productId);
        ps.setInt(2, limit);
        ps.setInt(3, offset);
        rs = ps.executeQuery();

        boolean first = true;// 是否為第一筆 (Is first record)
        while (rs.next()) {
            if (!first) json.append(",");
            json.append("{");
            json.append("\"id\":\"").append(rs.getString("id")).append("\",");
            json.append("\"userId\":\"").append(rs.getString("userId")).append("\",");
            json.append("\"displayName\":\"").append(rs.getString("displayName") != null ? rs.getString("displayName").replace("\"", "\\\"") : "Anonymous").append("\",");
            json.append("\"rating\":").append(rs.getInt("rating")).append(",");// 內容需跳脫雙引號 (Escape double quotes in content)
            json.append("\"content\":\"").append(rs.getString("content").replace("\"", "\\\"")).append("\",");
            json.append("\"date\":\"").append(rs.getTimestamp("date").toInstant().toString()).append("\"");// 日期轉 ISO 格式 (Date in ISO format)
            json.append("}");
            first = false;
        }
        json.append("]");
    } catch (Exception e) {
        response.setStatus(500);
        json.setLength(0);
        json.append("{\"error\":\"").append(e.getMessage().replace("\"", "\\\"")).append("\"}");
        System.out.println("Error in get_review.jsp: " + e.getMessage());
    } finally {
        try {
            if (rs != null) rs.close();
            if (ps != null) ps.close();
            // 不關閉共享連線，由 config.jsp 的 jspDestroy 處理
        } catch (SQLException e) {
            System.out.println("Error closing resources: " + e.getMessage());
        }
    }

    out.print(json.toString());
    out.flush();
%>
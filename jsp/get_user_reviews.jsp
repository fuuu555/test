<%@ page contentType="application/json; charset=UTF-8" %>
<%@ page import="java.sql.*, java.util.*, com.google.gson.Gson" %>
<%@ include file="config.jsp" %>
<%
    response.setHeader("Cache-Control", "no-cache");
    String userId = request.getParameter("userId");
    if (userId == null || userId.trim().isEmpty()) {
        response.setStatus(400);
        out.print("{\"error\": \"Invalid userId\"}");
        return;
    }

    List<Map<String, Object>> reviews = new ArrayList<>();
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        conn = con;
        sql = "SELECT r.id, r.productId, r.rating, r.content, r.date, r.productName " +
                     "FROM reviews r WHERE r.userId = ? ORDER BY r.date DESC";
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, userId);
        rs = pstmt.executeQuery();

        while (rs.next()) {
            Map<String, Object> review = new HashMap<>();
            review.put("id", rs.getString("id"));
            review.put("productId", rs.getString("productId"));
            review.put("product_name", rs.getString("productName"));
            review.put("rating", rs.getInt("rating"));
            review.put("content", rs.getString("content"));
            review.put("date", rs.getTimestamp("date").toString());
            reviews.add(review);
        }

        Gson gson = new Gson();
        out.print(gson.toJson(reviews));
    } catch (Exception e) {
        response.setStatus(500);
        out.print("{\"error\": \"" + e.getMessage().replace("\"", "\\\"") + "\"}");
    } finally {
        try { if (rs != null) rs.close(); } catch (SQLException e) {}
        try { if (pstmt != null) pstmt.close(); } catch (SQLException e) {}
        // 不關閉共享連線，由 config.jsp 處理
    }
%>
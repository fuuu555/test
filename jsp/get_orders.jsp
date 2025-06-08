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

    List<Map<String, Object>> orders = new ArrayList<>();
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        conn = con;
        sql = "SELECT o.order_id, o.order_date, o.total_amount " +
                     "FROM orders o WHERE o.user_id = ? ORDER BY o.order_date DESC";
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, userId);
        rs = pstmt.executeQuery();

        while (rs.next()) {
            Map<String, Object> order = new HashMap<>();
            order.put("order_id", rs.getInt("order_id"));
            order.put("order_date", rs.getTimestamp("order_date").toString());

            List<Map<String, Object>> items = new ArrayList<>();
            String itemSql = "SELECT od.product_id, od.quantity, od.unit_price, p.name AS item_name, pi.url AS image_url " +
                            "FROM order_details od " +
                            "JOIN products p ON od.product_id = p.id " +
                            "LEFT JOIN (SELECT product_id, MIN(url) AS url FROM product_images GROUP BY product_id) pi ON p.id = pi.product_id " +
                            "WHERE od.order_id = ?";
            PreparedStatement itemPstmt = conn.prepareStatement(itemSql);
            itemPstmt.setInt(1, rs.getInt("order_id"));
            ResultSet itemRs = itemPstmt.executeQuery();

            while (itemRs.next()) {
                Map<String, Object> item = new HashMap<>();
                item.put("product_id", itemRs.getString("product_id"));
                item.put("item_name", itemRs.getString("item_name"));
                item.put("quantity", itemRs.getInt("quantity"));
                item.put("unit_price", itemRs.getDouble("unit_price"));
                item.put("image_url", itemRs.getString("image_url"));
                items.add(item);
            }
            itemRs.close();
            itemPstmt.close();

            order.put("items", items);
            orders.add(order);
        }

        Gson gson = new Gson();
        out.print(gson.toJson(orders));
    } catch (Exception e) {
        response.setStatus(500);
        out.print("{\"error\": \"" + e.getMessage().replace("\"", "\\\"") + "\"}");
    } finally {
        try { if (rs != null) rs.close(); } catch (SQLException e) {}
        try { if (pstmt != null) pstmt.close(); } catch (SQLException e) {}
        // 不關閉共享連線，由 config.jsp 處理
    }
%>
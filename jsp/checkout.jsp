<%@ page import="java.sql.*, org.json.*, java.util.*" %>
<%@ page language="java" contentType="text/plain; charset=UTF-8" %>
<%@ include file="config.jsp" %>
<%
     // (1) 驗證 session (Session check: make sure user is logged in)
    String userId = (String)session.getAttribute("userId");
    if (userId == null) {
        response.setStatus(401);
        out.print("not_logged_in");
        return;
    }

    // (2) 讀取購物車資料 (Read cart JSON from request body)
    StringBuilder sb = new StringBuilder();
    String line;
    try (BufferedReader reader = request.getReader()) {
        while ((line = reader.readLine()) != null) {
            sb.append(line);
        }
    }
    String cartJson = sb.toString();
    if (cartJson.isEmpty()) {
        out.print("Cart is empty");
        return;
    }

    try {
        JSONArray cart = new JSONArray(cartJson);// (3) 寫入訂單 (Insert order record)
        Connection conn = con; 
        conn.setAutoCommit(false);
        PreparedStatement orderStmt = conn.prepareStatement(
            "INSERT INTO orders (user_id, order_date, status, total_amount) VALUES (?, NOW(), ?, ?)", Statement.RETURN_GENERATED_KEYS
        );
        double total = 0;
        for (int i = 0; i < cart.length(); i++) {
            JSONObject item = cart.getJSONObject(i);
            int qty = item.optInt("qty", 1);
            double price = item.getDouble("price");
            total += price * qty;
        }
        orderStmt.setString(1, userId);
        orderStmt.setString(2, "pending");
        orderStmt.setDouble(3, total);
        orderStmt.executeUpdate();

        // 取得新訂單編號 (Get generated order id)
        ResultSet generatedKeys = orderStmt.getGeneratedKeys();
        int orderId = -1;
        if (generatedKeys.next()) orderId = generatedKeys.getInt(1);

        // 寫入訂單明細 (Insert order details)
        PreparedStatement detailStmt = conn.prepareStatement(
            "INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES (?, ?, ?, ?)"
        );
        for (int i = 0; i < cart.length(); i++) {
            JSONObject item = cart.getJSONObject(i);
            String pid = item.getString("id");
            int qty = item.optInt("qty", 1);
            double price = item.getDouble("price");
            detailStmt.setInt(1, orderId);
            detailStmt.setString(2, pid);
            detailStmt.setInt(3, qty);
            detailStmt.setDouble(4, price);
            detailStmt.addBatch();
        }
        detailStmt.executeBatch();
        conn.commit();
        out.print("success");
    } catch (Exception e) {
        out.print("下單失敗: " + e.getMessage());
    } finally {
        try { con.close(); } catch (Exception e) {}
    }
%>

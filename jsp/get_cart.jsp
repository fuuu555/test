<%@ page import="java.sql.*, org.json.*" %>
<%@ page session="true" contentType="application/json; charset=UTF-8" language="java" %>
<%@ include file="config.jsp" %>
<%
response.setCharacterEncoding("UTF-8");
JSONArray cartItems = new JSONArray();// 購物車商品陣列 (Array for cart items)

try {
    String userId = (String) session.getAttribute("userId");// 從 session 取得用戶 id (Get userId from session)
    if (userId == null) {
        out.print("{\"status\":\"error\",\"message\":\"not logged in\"}"); // 未登入，回傳錯誤 (If not logged in, return error)
        return;
    }

     // 查詢用戶的待結帳訂單 (Query user's pending order)
    PreparedStatement psOrder = con.prepareStatement(
        "SELECT order_id, total_amount FROM orders WHERE user_id = ? AND status = 'Pending'"
    );
    psOrder.setString(1, userId);
    ResultSet rsOrder = psOrder.executeQuery();
    if (!rsOrder.next()) {
        out.print("{\"status\":\"success\",\"items\":[],\"total\":0,\"count\":0}");// 沒有購物車資料，回傳空陣列 (No cart, return empty result)
        return;
    }

    // 取得訂單 ID 和總金額 (Get order ID and total amount)
    int orderId = rsOrder.getInt("order_id");
    double totalAmount = rsOrder.getDouble("total_amount");
    rsOrder.close();
    psOrder.close();

    // 查詢訂單細項與商品資料 (Query order details and product info)
    PreparedStatement ps = con.prepareStatement(
        "SELECT od.order_detail_id, od.product_id, od.quantity, od.unit_price, p.name, p.description, " +
        "(SELECT url FROM product_images WHERE product_id = od.product_id LIMIT 1) as image_url " +
        "FROM order_details od JOIN products p ON od.product_id = p.id WHERE od.order_id = ?"
    );
    ps.setInt(1, orderId);
    ResultSet rs = ps.executeQuery();
    int count = 0;
    while (rs.next()) {
        JSONObject item = new JSONObject();
        item.put("order_detail_id", rs.getInt("order_detail_id"));
        item.put("productId", rs.getString("product_id"));
        item.put("quantity", rs.getInt("quantity"));
        item.put("unit_price", rs.getDouble("unit_price"));
        item.put("name", rs.getString("name"));
        item.put("description", rs.getString("description"));
        item.put("image_url", rs.getString("image_url") != null ? rs.getString("image_url") : "/imgs/no-image.png");
        cartItems.put(item);
        count += rs.getInt("quantity");
    }
    rs.close();
    ps.close();

    JSONObject response = new JSONObject();
    response.put("status", "success");
    response.put("items", cartItems);
    response.put("total", totalAmount);
    response.put("count", count);
    out.print(response.toString());
} catch (Exception e) {
    response.setStatus(500);
    out.print(new JSONObject().put("status", "error").put("message", e.getMessage()).toString());
    System.out.println("Error in get_cart.jsp: " + e.getMessage());
}
%>
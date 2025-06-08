<%@ page import="java.sql.*" %>
<%@ page session="true" contentType="application/json; charset=UTF-8" language="java" %>
<%@ include file="config.jsp" %>
<%
request.setCharacterEncoding("UTF-8");
StringBuilder json = new StringBuilder("{");

try {
    // 1. 取得會員 id，驗證登入 (Check user login)
    String userId = (String) session.getAttribute("userId");
    if (userId == null) {
        json.append("\"status\":\"error\",\"message\":\"not logged in\"}");
        out.print(json.toString());
        return;
    }

    // 2. 取得商品 id 與變動數量參數 (Get productId and change parameter)
    String productId = request.getParameter("productId");
    String changeStr = request.getParameter("change");
    if (productId == null || changeStr == null) {
        json.append("\"status\":\"error\",\"message\":\"invalid parameters\"}");
        out.print(json.toString());
        return;
    }
    int change = Integer.parseInt(changeStr); // 增減數量 (Quantity change, can be +1/-1)

    // 3. 啟用交易，確保操作原子性 (Enable transaction for atomic update)
    con.setAutoCommit(false);

    // 4. 取得用戶的 pending 訂單 (Get user's pending order)
    PreparedStatement psOrder = con.prepareStatement(
        "SELECT order_id FROM orders WHERE user_id = ? AND status = 'Pending'"
    );
    psOrder.setString(1, userId);
    ResultSet rsOrder = psOrder.executeQuery();
    if (!rsOrder.next()) {
        rsOrder.close();
        psOrder.close();
        json.append("\"status\":\"error\",\"message\":\"no cart found\"}");
        out.print(json.toString());
        return;
    }
    int orderId = rsOrder.getInt("order_id");
    rsOrder.close();
    psOrder.close();

    // 5. 查詢指定商品的明細 (Check order_details for the product)
    PreparedStatement psCheck = con.prepareStatement(
        "SELECT order_detail_id, quantity, unit_price FROM order_details WHERE order_id = ? AND product_id = ?"
    );
    psCheck.setInt(1, orderId);
    psCheck.setString(2, productId);
    ResultSet rsCheck = psCheck.executeQuery();
    if (rsCheck.next()) {
        int detailId = rsCheck.getInt("order_detail_id");
        int currentQuantity = rsCheck.getInt("quantity"); // 原本數量 (Current quantity)
        double unitPrice = rsCheck.getDouble("unit_price"); // 單價 (Unit price)
        int newQuantity = currentQuantity + change; // 新數量 (New quantity)
        if (newQuantity <= 0) {
            // 數量歸零或負值，直接刪除該商品 (Delete if quantity <= 0)
            PreparedStatement psDelete = con.prepareStatement(
                "DELETE FROM order_details WHERE order_detail_id = ?"
            );
            psDelete.setInt(1, detailId);
            psDelete.executeUpdate();
            psDelete.close();
        } else {
            // 否則更新數量 (Update quantity if > 0)
            PreparedStatement psUpdate = con.prepareStatement(
                "UPDATE order_details SET quantity = ? WHERE order_detail_id = ?"
            );
            psUpdate.setInt(1, newQuantity);
            psUpdate.setInt(2, detailId);
            psUpdate.executeUpdate();
            psUpdate.close();
        }
    }
    rsCheck.close();
    psCheck.close();

    // 6. 重新計算訂單總金額 (Recalculate total amount in orders)
    PreparedStatement psTotal = con.prepareStatement(
        "UPDATE orders SET total_amount = (SELECT SUM(quantity * unit_price) FROM order_details WHERE order_id = ?) WHERE order_id = ?"
    );
    psTotal.setInt(1, orderId);
    psTotal.setInt(2, orderId);
    psTotal.executeUpdate();
    psTotal.close();

    con.commit();
    json.append("\"status\":\"success\"}");
} catch (Exception e) {
    try { con.rollback(); } catch (SQLException ex) {} 
    json.append("\"status\":\"error\",\"message\":\"")
        .append(e.getMessage().replace("\"", "\\\""))
        .append("\"}");
    System.out.println("Error in update_quantity.jsp: " + e.getMessage());
} finally {
    try { con.setAutoCommit(true); } catch (SQLException ex) {} 
}
out.print(json.toString()); 
%>

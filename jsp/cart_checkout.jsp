<%@ page import="java.sql.*, org.json.*, java.math.BigDecimal" %>
<%@ page contentType="application/json; charset=UTF-8" %>
<%@ include file="config.jsp" %>
<%
JSONObject result = new JSONObject();
String userId = (String) session.getAttribute("userId");
if (userId == null) {
    result.put("status", "error").put("message", "請先登入");
    out.print(result.toString()); return;
}

try {
    // 1. 取得購物車所有商品
    PreparedStatement ps = con.prepareStatement(
        "SELECT c.product_id, c.quantity, p.price FROM cart_items c JOIN products p ON c.product_id = p.id WHERE c.user_id = ?"
    );
    ps.setString(1, userId);
    ResultSet rs = ps.executeQuery();

    // 2. 新增訂單主檔
    PreparedStatement psOrder = con.prepareStatement(
        "INSERT INTO orders (user_id, order_date, status, total_amount) VALUES (?, NOW(), 'Pending', 0)", Statement.RETURN_GENERATED_KEYS
    );
    psOrder.setString(1, userId);
    psOrder.executeUpdate();
    ResultSet key = psOrder.getGeneratedKeys();
    key.next();
    int orderId = key.getInt(1);
    psOrder.close();

    // 3. 新增訂單明細，計算總金額
    BigDecimal total = new BigDecimal(0);
    PreparedStatement psDetail = con.prepareStatement(
        "INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES (?, ?, ?, ?)"
    );
    while(rs.next()){
        String pid = rs.getString("product_id");
        int qty = rs.getInt("quantity");
        BigDecimal price = rs.getBigDecimal("price");
        psDetail.setInt(1, orderId);
        psDetail.setString(2, pid);
        psDetail.setInt(3, qty);
        psDetail.setBigDecimal(4, price);
        psDetail.executeUpdate();
        total = total.add(price.multiply(new BigDecimal(qty)));
    }
    psDetail.close();
    rs.close();

    // 4. 更新訂單總金額
    PreparedStatement psUpdate = con.prepareStatement("UPDATE orders SET total_amount = ? WHERE order_id = ?");
    psUpdate.setBigDecimal(1, total);
    psUpdate.setInt(2, orderId);
    psUpdate.executeUpdate();
    psUpdate.close();

    // 5. 清空購物車
    PreparedStatement psDel = con.prepareStatement("DELETE FROM cart_items WHERE user_id = ?");
    psDel.setString(1, userId);
    psDel.executeUpdate();
    psDel.close();

    result.put("status", "success").put("orderId", orderId);
} catch(Exception e) {
    result.put("status", "error").put("message", e.getMessage());
}
out.print(result.toString());
%>
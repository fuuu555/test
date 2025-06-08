<%@ page import="java.sql.*, org.json.*" %>
<%@ page contentType="application/json; charset=UTF-8" %>
<%@ include file="config.jsp" %>
<%
JSONObject result = new JSONObject();

String userId = (String) session.getAttribute("userId");
String productId = request.getParameter("productId");
String qtyStr = request.getParameter("quantity");
int quantity = 1;

if (userId == null) {
    result.put("status", "error").put("message", "請先登入");
    out.print(result.toString()); return;
}
if (productId == null || productId.isEmpty()) {
    result.put("status", "error").put("message", "缺少商品ID");
    out.print(result.toString()); return;
}
try { 
    quantity = Integer.parseInt(qtyStr); 
    if (quantity < 1) quantity = 1;
} catch(Exception e) {
    // Default to 1 if parsing fails
}

try {
    // Check stock
    PreparedStatement psStock = con.prepareStatement("SELECT stock FROM products WHERE id = ?");
    psStock.setString(1, productId);
    ResultSet rs = psStock.executeQuery();
    if (!rs.next()) {
        result.put("status", "error").put("message", "商品不存在");
        rs.close();
        psStock.close();
        out.print(result.toString());
        return;
    }
    int stock = rs.getInt("stock");
    rs.close();
    psStock.close();
    
    if (stock < quantity) {
        result.put("status", "error").put("message", "庫存不足");
        out.print(result.toString());
        return;
    }

    // Add to cart
    PreparedStatement ps = con.prepareStatement(
        "INSERT INTO cart_items (user_id, product_id, quantity) VALUES (?, ?, ?) " +
        "ON DUPLICATE KEY UPDATE quantity = quantity + VALUES(quantity)"
    );
    ps.setString(1, userId);
    ps.setString(2, productId);
    ps.setInt(3, quantity);
    ps.executeUpdate();
    ps.close();
    result.put("status", "success").put("message", "加入購物車成功");
} catch(Exception e) {
    e.printStackTrace();
    result.put("status", "error").put("message", e.getMessage());
}
out.print(result.toString());
%>
<%@ page import="java.sql.*, org.json.*" %>
<%@ page contentType="application/json; charset=UTF-8" %>
<%@ include file="config.jsp" %>
<%
JSONObject result = new JSONObject();
JSONArray items = new JSONArray();

String userId = (String) session.getAttribute("userId");
if (userId == null) {
    result.put("status", "error").put("message", "請先登入");
    out.print(result.toString()); return;
}

try {
    PreparedStatement ps = con.prepareStatement(
        "SELECT c.product_id, c.quantity, p.name, p.price, p.brand, MIN(img.url) AS url " +
        "FROM cart_items c " +
        "JOIN products p ON c.product_id = p.id " +
        "LEFT JOIN product_images img ON c.product_id = img.product_id " +
        "WHERE c.user_id = ? " +
        "GROUP BY c.product_id, c.quantity, p.name, p.price, p.brand"
    );
    ps.setString(1, userId);
    ResultSet rs = ps.executeQuery();
    while(rs.next()){
        JSONObject o = new JSONObject();
        o.put("productId", rs.getString("product_id"));
        o.put("quantity", rs.getInt("quantity"));
        o.put("name", rs.getString("name"));
        o.put("price", rs.getBigDecimal("price"));
        o.put("brand", rs.getString("brand"));
        o.put("image", rs.getString("url"));
        items.put(o);
    }
    rs.close();
    ps.close();
    result.put("status", "success").put("items", items);
} catch(Exception e) {
    e.printStackTrace();
    result.put("status", "error").put("message", e.getMessage());
}
out.print(result.toString());
%>
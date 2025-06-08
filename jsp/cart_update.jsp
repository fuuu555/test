<%@ page import="java.sql.*, org.json.*" %>
<%@ page contentType="application/json; charset=UTF-8" %>
<%@ include file="config.jsp" %>
<%
JSONObject result = new JSONObject();
String userId = (String) session.getAttribute("userId");
String productId = request.getParameter("productId");
int quantity = 1;
try { quantity = Integer.parseInt(request.getParameter("quantity")); } catch(Exception e){}

if (userId == null) {
    result.put("status", "error").put("message", "請先登入");
    out.print(result.toString()); return;
}
if (productId == null) {
    result.put("status", "error").put("message", "缺少商品ID");
    out.print(result.toString()); return;
}

try {
    if (quantity <= 0) {
        PreparedStatement ps = con.prepareStatement(
            "DELETE FROM cart_items WHERE user_id = ? AND product_id = ?"
        );
        ps.setString(1, userId);
        ps.setString(2, productId);
        ps.executeUpdate();
        ps.close();
    } else {
        PreparedStatement ps = con.prepareStatement(
            "UPDATE cart_items SET quantity = ? WHERE user_id = ? AND product_id = ?"
        );
        ps.setInt(1, quantity);
        ps.setString(2, userId);
        ps.setString(3, productId);
        ps.executeUpdate();
        ps.close();
    }
    result.put("status", "success");
} catch(Exception e) {
    result.put("status", "error").put("message", e.getMessage());
}
out.print(result.toString());
%>

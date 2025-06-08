<%@ page import="java.sql.*, java.util.UUID" %>
<%@ page session="true" contentType="application/json; charset=UTF-8" language="java" %>
<%@ include file="config.jsp" %>
<%
request.setCharacterEncoding("UTF-8");
StringBuilder json = new StringBuilder("{");

try {
    // 1. 檢查會員登入狀態（Check user login status）
    String userId = (String) session.getAttribute("userId");
    if (userId == null) {
        json.append("\"status\":\"error\",\"message\":\"not logged in\"}");
        out.print(json.toString());
        return;
    }

    // 2. 取得參數並驗證（Get parameters and validate）
    String productId = request.getParameter("productId");
    String content = request.getParameter("content");
    String ratingStr = request.getParameter("rating");

    // 基本防呆（Basic validation: check parameters）
    if (productId == null || content == null || ratingStr == null) {
        json.append("\"status\":\"error\",\"message\":\"invalid\"}");
        out.print(json.toString());
        return;
    }
    int rating = 0;
    try { 
        rating = Integer.parseInt(ratingStr); 
    } catch (Exception ex) {
        json.append("\"status\":\"error\",\"message\":\"invalid\"}");
        out.print(json.toString());
        return;
    }

    // 評分必須 1~5，內容不少於 10 字（Rating must be 1~5, content ≥ 10 chars）
    if (rating < 1 || rating > 5 || content.trim().length() < 10) {
        json.append("\"status\":\"error\",\"message\":\"invalid\"}");
        out.print(json.toString());
        return;
    }

    // 3. 寫入 reviews（Insert new review record）
    String uuid = UUID.randomUUID().toString();
    PreparedStatement ps = con.prepareStatement(
        "INSERT INTO reviews (id, productId, userId, content, date, rating, productName) " +
        "SELECT ?, ?, ?, ?, NOW(), ?, name FROM products WHERE id = ?"
    );
    ps.setString(1, uuid);
    ps.setString(2, productId);
    ps.setString(3, userId);
    ps.setString(4, content);
    ps.setInt(5, rating);
    ps.setString(6, productId);

    int rowCount = ps.executeUpdate();
    ps.close();

    if (rowCount > 0) {
     // 4. 立刻同步 product_ratings（Update product ratings immediately）
    PreparedStatement ps2 = con.prepareStatement(
        "SELECT COUNT(*) AS cnt, AVG(rating) AS avg FROM reviews WHERE productId = ?"
    );
    ps2.setString(1, productId);
    ResultSet rs2 = ps2.executeQuery();
    int cnt = 0;
    double avg = 0;
    if (rs2.next()) {
        cnt = rs2.getInt("cnt");// 評論數量（Reviews count）
        avg = rs2.getDouble("avg"); // 平均評分（Average rating）
    }
    rs2.close();
    ps2.close();

    
    // 檢查 product_ratings 是否已有資料（Check if product_ratings row exists）
    PreparedStatement checkPs = con.prepareStatement(
        "SELECT COUNT(*) AS cnt FROM product_ratings WHERE product_id = ?"
    );
    checkPs.setString(1, productId);
    ResultSet checkRs = checkPs.executeQuery();
    int rowExists = 0;
    if (checkRs.next()) {
        rowExists = checkRs.getInt("cnt");
    }
    checkRs.close();
    checkPs.close();

    // 若有資料則更新（Update existing row if present）
    if (rowExists > 0) {
        PreparedStatement ps3 = con.prepareStatement(
            "UPDATE product_ratings SET reviewsCount = ?, average = ? WHERE product_id = ?"
        );
        ps3.setInt(1, cnt);
        ps3.setDouble(2, avg);
        ps3.setString(3, productId);
        ps3.executeUpdate();
        ps3.close();
    } else {
        // 若沒有則新增一筆（Insert new row if absent）
        PreparedStatement ps3 = con.prepareStatement(
            "INSERT INTO product_ratings (product_id, reviewsCount, average) VALUES (?, ?, ?)"
        );
        ps3.setString(1, productId);
        ps3.setInt(2, cnt);
        ps3.setDouble(3, avg);
        ps3.executeUpdate();
        ps3.close();
    }

    json.append("\"status\":\"success\"}");
}
} catch (Exception e) {
    json.append("\"status\":\"error\",\"message\":\"").append(e.getMessage().replace("\"", "\\\"")).append("\"}");
    System.out.println("Error in add_review.jsp: " + e.getMessage());
}
out.print(json.toString());
%>

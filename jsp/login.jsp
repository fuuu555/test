<%@ page import="java.sql.*" %>
<%@ page session="true" contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="config.jsp" %>
<%
    String email = request.getParameter("email");
    String userPassword = request.getParameter("password");

    try { 
        PreparedStatement loginStmt = con.prepareStatement(
            "SELECT id, displayName FROM users WHERE email = ? AND password = ?"
        );
        loginStmt.setString(1, email);
        loginStmt.setString(2, userPassword);
        ResultSet rs = loginStmt.executeQuery();
        if (rs.next()) {
            String userId = rs.getString("id");
            String displayName = rs.getString("displayName");

            // 這三個都可以設，推薦這樣（userId 是全站判斷關鍵！）
            session.setAttribute("userEmail", email);
            session.setAttribute("userId", userId);        
            session.setAttribute("displayName", displayName);

            out.print("success");
        } else {
            out.print("Login failed: Incorrect email or password");
        }
        con.close();
    } catch (Exception e) {
        out.print("Login failed: " + e.getMessage());
    }
%>

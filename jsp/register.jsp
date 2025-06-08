<%@ page import="java.sql.*, java.util.UUID" %>
<%@ page session="true" contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="config.jsp" %>
<%
    String email = request.getParameter("email");
    String userPassword = request.getParameter("password");

    try { 
        PreparedStatement check = con.prepareStatement("SELECT * FROM users WHERE email = ?");
        check.setString(1, email);
        ResultSet rs = check.executeQuery();
        if (rs.next()) {
            out.print("Email already registered");
            return;
        }

        // Insert new user
        String id = java.util.UUID.randomUUID().toString();
        PreparedStatement insert = con.prepareStatement(
            "INSERT INTO users (id, email, password) VALUES (?, ?, ?)"
        );
        insert.setString(1, id);
        insert.setString(2, email);
        insert.setString(3, userPassword);
        insert.executeUpdate();

        session.setAttribute("userEmail", email);
        out.print("success");
        con.close();
    } catch (Exception e) {
        out.print("Register failed: " + e.getMessage());
    }

%>
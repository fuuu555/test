<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // 設置訪客的 session
    session.setAttribute("isLoggedIn", true);
    session.setAttribute("userType", "guest");
    String guestUserId = "guest_" + System.currentTimeMillis();
    session.setAttribute("userId", guestUserId);
    out.print("success");
%>
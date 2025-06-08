<%@ page contentType="application/json; charset=UTF-8" %>
<%
    response.setHeader("Cache-Control", "no-cache");
    String userId = (String) session.getAttribute("userId");
    if (userId == null) {
        response.setStatus(401);
        out.print("{\"error\": \"Not logged in\"}");
    } else {
        out.print("{\"userId\": \"" + userId + "\"}");
    }
%>
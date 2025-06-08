<%@ page language="java" contentType="text/plain; charset=UTF-8" %>
<%
    if (session.getAttribute("userId") != null) {
        out.print("logged_in");
    } else {
        out.print("not_logged_in");
    }
%>

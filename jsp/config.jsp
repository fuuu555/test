<%
Class.forName("com.mysql.cj.jdbc.Driver");
String url = "jdbc:mysql://localhost:3306/FINALTEST?serverTimezone=UTC";
String user = "root";
String dbPassword = "0505";//改自己密碼(change your password here)
String sql ;
Connection con = DriverManager.getConnection(url, user, dbPassword);
Statement stmt = con.createStatement();
sql = "USE FINALTEST";
stmt.execute(sql);
%>
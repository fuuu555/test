<%@ page contentType="application/json; charset=UTF-8" %>
<%@ page import="java.sql.*,java.util.*,org.json.*" %>
<%@ include file="config.jsp" %>
<%

    // 用來存所有產品的 JSONArray(Array for all products)
    JSONArray products = new JSONArray();
    PreparedStatement ps = null;
    ResultSet rs = null;

    //Build product object → store in map → output as array

    try {
        // 1. 查主表 (Query main products table)
        sql="SELECT id, name, price, category, brand, description,longdescription FROM products";
        ps = con.prepareStatement(sql);
        rs = ps.executeQuery();

        // 建立一個 Map，key 是產品 id，value 是產品的 JSONObject
         // Create a Map, key is product id, value is product JSONObject
        Map<String, JSONObject> productMap = new LinkedHashMap<>();
        while (rs.next()) {
            String pid = rs.getString("id");
            JSONObject product = new JSONObject();
            product.put("id", pid);
            product.put("name", rs.getString("name"));
            product.put("price", rs.getDouble("price"));
            product.put("category", rs.getString("category"));
            product.put("brand", rs.getString("brand"));
            product.put("description", rs.getString("description"));
            product.put("longdescription", rs.getString("longdescription"));
            product.put("images", new JSONArray());
            product.put("tags", new JSONArray());
            product.put("features", new JSONArray());
            productMap.put(pid, product);//product 裡有全部資料，透過 map 找 id
        }
        rs.close(); ps.close();

        // 2. 查 images(Query product images)
        sql = "SELECT product_id, url FROM product_images";
        ps = con.prepareStatement(sql);
        rs = ps.executeQuery();
        while (rs.next()) {
            String pid = rs.getString("product_id");
            if (productMap.containsKey(pid)) {
                productMap.get(pid).getJSONArray("images").put(rs.getString("url"));
            }
        }
        rs.close(); ps.close();

        // 3. 查 tags(Query product tags)
        sql = "SELECT product_id, tag FROM product_tags";
        ps = con.prepareStatement(sql);
        rs = ps.executeQuery();
        while (rs.next()) {
            String pid = rs.getString("product_id");
            if (productMap.containsKey(pid)) {
                productMap.get(pid).getJSONArray("tags").put(rs.getString("tag"));
            }
        }
        rs.close(); ps.close();

        // 4. 查 features (Query product features)
        sql = "SELECT product_id, feature FROM product_features";
        ps = con.prepareStatement(sql);
        rs = ps.executeQuery();
        while (rs.next()) {
            String pid = rs.getString("product_id");
            if (productMap.containsKey(pid)) {
                productMap.get(pid).getJSONArray("features").put(rs.getString("feature"));
            }
        }
        rs.close(); ps.close();

        // 5. 查 ratings(Query product ratings)
        ps = con.prepareStatement("SELECT product_id, reviewsCount, average FROM product_ratings");
        rs = ps.executeQuery();
        while (rs.next()) {
            String pid = rs.getString("product_id");
            if (productMap.containsKey(pid)) {
                productMap.get(pid).put("reviewsCount", rs.getInt("reviewsCount"));
                productMap.get(pid).put("averageRating", rs.getDouble("average"));
            }
        }
        rs.close(); ps.close();

        // 6. 塞進 JSONArray(Push all products into JSONArray)
        for (JSONObject p : productMap.values()) {
            // 沒有評分資料預設為 0(Set default value if no rating info)
            if (!p.has("reviewsCount")) p.put("reviewsCount", 0);
            if (!p.has("averageRating")) p.put("averageRating", 0.0);
            products.put(p);
        }

        out.print(products.toString());

    } catch(Exception e) {
        response.setStatus(500);
        out.print(new JSONObject().put("error", e.getMessage()).toString());
    } finally {
        try { if(rs != null) rs.close(); } catch(Exception e) {}
        try { if(ps != null) ps.close(); } catch(Exception e) {}
        try { if(con != null) con.close(); } catch(Exception e) {}
    }
%>

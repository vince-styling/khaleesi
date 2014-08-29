```jsp
<%@ page import="java.io.*,java.util.*" %>
<%
    String title = "User Agent Example";
%>
<title><% out.print(title); %></title>
<h1><% out.print(title); %></h1>
<div align="center">
<p>${header["user-agent"]}</p>
</div>
<h1>${pageContext.request.queryString}</h1>
<h1>${fn:length("Get my length")}</h1>
<h1>${ns:func(param1, param2, ...)}</h1>
<h1>${page.member / 12 * 2 + 2}</h1>
<h1>${page.member eq 2}</h1>
<jsp:text>
Box Perimeter is: ${2*box.width + 2*box.height}
</jsp:text>
<%
   Enumeration paramNames = request.getParameterNames();

   while(paramNames.hasMoreElements()) {
      String paramName = (String)paramNames.nextElement();
      out.print("<tr><td>" + paramName + "</td>\n");
      String paramValue = request.getHeader(paramName);
      out.println("<td> " + paramValue + "</td></tr>\n");
   }
%>
```
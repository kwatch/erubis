<%
#include <stdio.h>

int main(int argc, char *argv[])
{
    int i;

%>
<p>Hello <%= "%s", argv[0] %>!</p>
<table>
  <tbody>
    <% for (i = 1; i < argc; i++) { %>
    <tr bgcolor="<%= i % 2 == 0 ? "#FFCCCC" : "#CCCCFF" %>">
      <td><%= "%d", i %></td>
      <td><%= "%s", argv[i] %></td>
    </tr>
    <% } %>
  </tbody>
</table>
<%

    return 0; 
}
%>

package my;

public class Util {

    public static String escapeXml(String s) {
        if (s == null) return "";
        StringBuilder sb = new StringBuilder();
        int len = s.length();
        for (int i = 0; i < len; i++) {
            char ch = s.charAt(i);
            switch (ch) {
            case '<':    sb.append("&lt;");   break;
            case '>':    sb.append("&gt;");   break;
            case '&':    sb.append("&amp;");  break;
            case '"':    sb.append("&quot;"); break;
            default:     sb.append(ch);
            }
        }
        return sb.toString();
    }

    public static String escapeXml(Object obj) {
        return escapeXml(obj.toString());
    }


    public static String checked(boolean cond) {
        return cond ? " checked=\"checked\"" : "";
    }

    public static String selected(boolean cond) {
        return cond ? " selected=\"selected\"" : "";
    }

    public static String disabled(boolean cond) {
        return cond ? " disabled=\"disabled\"" : "";
    }


    public static String nl2br(String str) {
        StringBuilder sb = new StringBuilder();
        int len = str.length();
        for (int i = 0; i < len; i++) {
            char ch = str.charAt(i);
            if (ch == '\n') {
                sb.append("<br />\n");
            } else {
                sb.append(ch);
            }
        }
        return sb.toString();
    }

}

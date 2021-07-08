public class Callout {
    private static final Integer DEFAULT_TIMEOUT = 10000;

    public Callout(String jsonString, String endpoint, String method, Integer millisecondTimeout, Type callbackType) {
        this.BodyString = jsonString;
        //Type.forName throws for nulls, alas
        this.CallbackName = callbackType == null ? '' : callbackType.getName();
        this.Endpoint = endpoint;
        this.RestMethod = method;
        this.Timeout = millisecondTimeout;
    }

    public Callout(String jsonString, String endpoint, String method, Type callbackType) {
        //10 seconds is the default timeout
        this(jsonString, endpoint, method, DEFAULT_TIMEOUT, callbackType);
    }

    public Callout (String jsonString, String endpoint, String method) {
        this(jsonString, endpoint, method, null);
    }

    //sometimes an api key is supplied as part of the URL ...
    //because it's not always necessary, we make it a public member of the class
    public String token { get; set; }

    public String bodyString { get; private set; }
    public String callbackName { get; private set; }
    public String endpoint { get; private set; }
    public String restMethod { get; private set; }
    public Integer timeout { get; private set; }
    public enum RestMethod { GET, PATCH, POST, PUT }
}

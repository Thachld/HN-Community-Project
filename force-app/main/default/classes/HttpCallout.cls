public with sharing class HttpCallout {
    public static HttpResponse makeRequest(HttpRequest req) {
        HttpResponse res;
        try {
            res = new Http().send(req);
        } catch(Exception ex) {
            //or you could just throw ...
            res = new HttpResponse();
            res.setStatusCode(503);
            res.setBody(ex.getMessage());
        }
        return res;
    }

    public static HttpRequest setupHttpRequest(Callout callout) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(callout.Endpoint);
        req.setMethod(callout.RestMethod);
        req.setTimeout(callout.Timeout);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(callout.BodyString);
        if(String.isNotBlank(callout.Token)) {
            req.setHeader('Credential', callout.Token);
        }
        return req;
    }
}

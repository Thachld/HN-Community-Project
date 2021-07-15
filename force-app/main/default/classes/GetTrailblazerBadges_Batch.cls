public with sharing class GetTrailblazerBadges_Batch implements Database.Batchable<SObject>, Database.AllowsCallouts{
    public GetTrailblazerBadges_Batch() {

    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Id, Trailhead_username__c,Points__c, Profile_Photo__c,Rank__c,Rank_Badge_Link__c,Superbadges__c,
                                        Trails__c,Certifications__c,Badges__c, Trailblazer_Since__c
                                        FROM Contact 
                                        WHERE Trailhead_username__c != null]);
    }

    public void execute(Database.BatchableContext bc, List<Contact> scope){
        Map<String,String> mapContact = new Map<String,String>();
        
        Map<String, HttpResponse> mapprofileDataRes = new Map<String, HttpResponse> ();        
        Map<String, HttpResponse> mapsupperBadgeDataRes = new Map<String, HttpResponse> ();
        Map<String, List<HttpResponse>> mapBadgeDataRes = new Map<String, List<HttpResponse>> ();
        
        Map<String,ProfileCountData> mapprofileDatas = new Map<String,ProfileCountData>();        
        Map<String,BadgeData> mapSupBadges = new Map<String,BadgeData>();
        Map<String,List<BadgeData>> mapBadges = new Map<String,List<BadgeData>>();
        Map<String, Integer> mapTotalBadges =new Map<String, Integer>();

        Map<String,Badge__c> mapUpSertBadges = new Map<String,Badge__c>();
        

        for(Contact trail: scope){
            
            if(!String.isBlank(trail.Trailhead_username__c)){
                mapContact.put(trail.Trailhead_username__c, trail.Id);

                String baseEndPoint = CalloutConstant.GO_TRAILHEAD_API + trail.Trailhead_username__c;                
                System.debug('baseEndPoint=>' + baseEndPoint);                
                HttpResponse profileDataRes = HttpCallout.makeRequest(setupCalloutGetProfileData(baseEndPoint));  
                
                // System.debug('profileDataRes.getStatus()=>' + profileDataRes.getStatus());
                if(profileDataRes.getStatus() == 'OK'){
                    mapprofileDataRes.put(trail.Trailhead_username__c, profileDataRes);
                }
            }
        }

        
        //Trailblazer data
        for(String profileId: mapprofileDataRes.keySet()){
            
            HttpResponse res = mapprofileDataRes.get(profileId);
            String resBody = res.getBody();
            
            if (resBody.contains(CalloutConstant.HEROKU_ERROR) || String.isBlank(resBody)) {
                System.debug('Application Error, please try again. API may be down.');
            }else {
                ProfileCountData data = (ProfileCountData)JSON.deserialize(resBody.replaceAll('__c', ''), ProfileCountData.class);
                mapprofileDatas.put(profileId, data);
            }
        }

        for(Contact trail : scope){
            if(!String.isBlank(trail.Trailhead_username__c)){

                //profile Trail Data
                ProfileCountData profiledata = mapprofileDatas.get(trail.Trailhead_username__c);

                if(profiledata != null){                    
                    Integer badges = (Integer)profiledata.value[0].ProfileCounts[0].EarnedBadgeTotal;    
                    mapTotalBadges.put(trail.Trailhead_username__c, badges);
                }               
            } 
        }


        for(Contact trail: scope ){            
            System.debug('trail.Trailhead_username__c=>' + trail.Trailhead_username__c);
            Integer totalBadges = (mapTotalBadges.get(trail.Trailhead_username__c) ==null? 0: mapTotalBadges.get(trail.Trailhead_username__c));

            if(totalBadges > 0 && !String.isBlank(trail.Trailhead_username__c)){
                Integer loopcount =  (Integer)Math.floor(totalBadges/30) + 1;

                String baseEndPoint = CalloutConstant.GO_TRAILHEAD_API + trail.Trailhead_username__c;   

                for(Integer i = 0 ; i < loopcount; i ++){      
                    String offset = '';
                    if(i == 0){
                        offset = '';
                    }else {
                        offset = '/' + String.valueOf( i * 30 );
                    }
                    
                    //Get module badges
                    HttpResponse modulebadgeDataRes = new HttpResponse();
                    modulebadgeDataRes = HttpCallout.makeRequest(setupCalloutGetModuleBadge(baseEndPoint, offset ));

                    //Get project badges
                    HttpResponse projectbadgeDataRes = new HttpResponse();
                    projectbadgeDataRes = HttpCallout.makeRequest(setupCalloutGetProjectBadge(baseEndPoint, offset));

                    //Get Event badges
                    HttpResponse eventbadgeDataRes = new HttpResponse();
                    eventbadgeDataRes = HttpCallout.makeRequest(setupCalloutGetEventBadge(baseEndPoint, offset));

                    System.debug('modulebadgeDataRes.getStatus()=>' + modulebadgeDataRes.getStatus());

                    if(modulebadgeDataRes.getStatus() == 'OK'){
                        if(mapBadgeDataRes.containsKey(trail.Trailhead_username__c)){
                            mapBadgeDataRes.get(trail.Trailhead_username__c).add(modulebadgeDataRes);
                        }else {
                            mapBadgeDataRes.put(trail.Trailhead_username__c, new List<HttpResponse>{modulebadgeDataRes});
                        }
                    }

                    System.debug('projectbadgeDataRes.getStatus()=>' + projectbadgeDataRes.getStatus());

                    if(projectbadgeDataRes.getStatus() == 'OK'){
                        if(mapBadgeDataRes.containsKey(trail.Trailhead_username__c)){
                            mapBadgeDataRes.get(trail.Trailhead_username__c).add(projectbadgeDataRes);
                        }else {
                            mapBadgeDataRes.put(trail.Trailhead_username__c, new List<HttpResponse>{projectbadgeDataRes});
                        }
                    }


                    System.debug('eventbadgeDataRes.getStatus()=>' + eventbadgeDataRes.getStatus());
                    if(eventbadgeDataRes.getStatus() == 'OK'){
                        if(mapBadgeDataRes.containsKey(trail.Trailhead_username__c)){
                            mapBadgeDataRes.get(trail.Trailhead_username__c).add(eventbadgeDataRes);
                        }else {
                            mapBadgeDataRes.put(trail.Trailhead_username__c, new List<HttpResponse>{eventbadgeDataRes});
                        }
                    }


                }
            }
        }


        for(Contact trail: scope ){
            if( !String.isBlank(trail.Trailhead_username__c)){
                List<HttpResponse> responses = mapBadgeDataRes.get(trail.Trailhead_username__c);

                for(HttpResponse res: responses){
                    String resBody = res.getBody();            
                    if (resBody.contains(CalloutConstant.HEROKU_ERROR) || String.isBlank(resBody)) {
                        System.debug('Application Error, please try again. API may be down.');
                    }else {
                        BadgeData data = (BadgeData)JSON.deserialize(resBody.replaceAll('__c', ''), BadgeData.class);  
                        
                        if(mapBadges.containsKey(trail.Trailhead_username__c)){
                            mapBadges.get(trail.Trailhead_username__c).add(data);
                        }else {
                            mapBadges.put(trail.Trailhead_username__c, new List<BadgeData>{data});
                        }                       
                    }
                }
            } 
        }


        for(Contact trail: scope ){
            if( !String.isBlank(trail.Trailhead_username__c)){
                List<BadgeData> datas = mapBadges.get(trail.Trailhead_username__c);

                for(BadgeData badgesdata: datas){
                    if ( badgesdata != null
                        && badgesdata.value != null 
                        && !badgesdata.value.isEmpty() 
                        && badgesdata.value[0].EarnedAwards != null 
                        && !badgesdata.value[0].EarnedAwards.isEmpty()){
                        
                            System.debug('badgesdata.value[0].EarnedAwards' + badgesdata.value[0].EarnedAwards.size());    
                        for (BadgeData.EarnedAwards award : badgesdata.value[0].EarnedAwards) {
                            if (award.AwardType != 'Superbadge'){
                                System.debug('award.Award.Label=>' + award.Award.Label + 'award.Award.Id>' + award.Award.Id);
                                Badge__c badge = new Badge__c();                                
                                badge.Name = award.Award.Label.left(80);
                                badge.Icon_Link__c = award.Award.ImageUrl;  
                                badge.Trailblazer__c = trail.Id;  
                                badge.Date_Sync__c = System.now();                                 
                                badge.Type__c = award.AwardType;    
                                badge.BadgeId__c = award.Award.Id + trail.Id;

                                mapUpSertBadges.put(badge.BadgeId__c,badge);
                            }
                        }

                    }
                }

            }

        }

         

        System.debug('mapUpSertBadges=>' + mapUpSertBadges.size());
        if(mapUpSertBadges.size() > 0){            
            Schema.SObjectField usfield = Badge__c.Fields.BadgeId__c;
            Database.upsert(mapUpSertBadges.values(), usfield, true) ;
        }
        
    }

    public void finish(Database.BatchableContext bc){

    }

    public static HttpRequest setupCalloutGetModuleBadge(String baseEndPoint, String offset){
        String restMethod = 'GET';     
        String endpoint = baseEndPoint + CalloutConstant.BADGES_PATH + '/module' + offset;      
        System.debug(endpoint);            
        Callout callout = new Callout('', endpoint, restMethod, null);    

        HttpRequest req = HttpCallout.setupHttpRequest(callout);

        return req;
    }

    public static HttpRequest setupCalloutGetProjectBadge(String baseEndPoint, String offset){
        String restMethod = 'GET';     
        String endpoint = baseEndPoint + CalloutConstant.BADGES_PATH + '/project' + offset;      
        System.debug(endpoint);            
        Callout callout = new Callout('', endpoint, restMethod, null);    

        HttpRequest req = HttpCallout.setupHttpRequest(callout);

        return req;
    }

    public static HttpRequest setupCalloutGetEventBadge(String baseEndPoint, String offset){
        String restMethod = 'GET';     
        String endpoint = baseEndPoint + CalloutConstant.BADGES_PATH + '/event' + offset;      
        System.debug(endpoint);            
        Callout callout = new Callout('', endpoint, restMethod, null);    

        HttpRequest req = HttpCallout.setupHttpRequest(callout);

        return req;
    }

    public static HttpRequest setupCalloutGetProfileData(String baseEndPoint){
        String restMethod = 'GET';     
        String endpoint = baseEndPoint;                   
        Callout callout = new Callout('', endpoint, restMethod, null);    

        HttpRequest req = HttpCallout.setupHttpRequest(callout);

        return req;
    }

}
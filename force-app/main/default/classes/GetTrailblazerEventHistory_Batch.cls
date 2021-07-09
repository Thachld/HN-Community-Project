public with sharing class GetTrailblazerEventHistory_Batch implements Database.Batchable<SObject>, Database.AllowsCallouts {
    private Date rundate;

    public GetTrailblazerEventHistory_Batch(Date pdate) {
        this.rundate = pdate;
    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Id, Trailhead_username__c, Badges__c, 
                                            Superbadges__c, Points__c, Trails__c, Rank__c
                                        FROM Contact 
                                        WHERE Trailhead_username__c != null
                                        AND Id = '0035g000003VCDNAA4']);       
    }

    public void execute(Database.BatchableContext bc, List<Contact> scope){
        List<Trail_Activity__c> insertActivites = new List<Trail_Activity__c>();

        Map<String, HttpResponse> mapprofileDataRes = new Map<String, HttpResponse> ();
        Map<String, HttpResponse> mapsupperBadgeDataRes = new Map<String, HttpResponse> ();
        Map<String, HttpResponse> mapBadgeDataRes = new Map<String, HttpResponse> ();

        Map<String,ProfileCountData> mapprofileDatas = new Map<String,ProfileCountData>();
        Map<String,BadgeData> mapSupBadges = new Map<String,BadgeData>();
        Map<String,BadgeData> mapBadges = new Map<String,BadgeData>();

        for(Contact trail : scope){
            if(!String.isBlank(trail.Trailhead_username__c)){
                
                String baseEndPoint = CalloutConstant.GO_TRAILHEAD_API + trail.Trailhead_username__c;    
                
                HttpResponse profileDataRes = HttpCallout.makeRequest(setupCalloutGetProfileData(baseEndPoint));
                HttpResponse badgeDataRes = HttpCallout.makeRequest(setupCalloutGetBadges(baseEndPoint));
                HttpResponse supperBadgeDataRes = HttpCallout.makeRequest(setupCalloutGetSupperbadge(baseEndPoint));

                System.debug('profileDataRes.getStatus()=>' + profileDataRes.getStatus());
                if(profileDataRes.getStatus() == 'OK'){
                    mapprofileDataRes.put(trail.Trailhead_username__c, profileDataRes);
                }

                System.debug('supperBadgeDataRes.getStatus()=>' + supperBadgeDataRes.getStatus());
                if(supperBadgeDataRes.getStatus() == 'OK'){
                    mapsupperBadgeDataRes.put(trail.Trailhead_username__c, supperBadgeDataRes);
                }

                System.debug('badgeDataRes.getStatus()=>' + badgeDataRes.getStatus());
                if(badgeDataRes.getStatus() == 'OK'){
                    mapBadgeDataRes.put(trail.Trailhead_username__c, badgeDataRes);
                }
            }

        }

        //Get Profile Data
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

        //Get Supper badges
        for(String profileId: mapsupperBadgeDataRes.keySet()){
            
            HttpResponse res = mapsupperBadgeDataRes.get(profileId);
            String resBody = res.getBody();
            
            if (resBody.contains(CalloutConstant.HEROKU_ERROR) || String.isBlank(resBody)) {
                System.debug('Application Error, please try again. API may be down.');
            }else {
                BadgeData data = (BadgeData)JSON.deserialize(resBody.replaceAll('__c', ''), BadgeData.class);
                mapSupBadges.put(profileId, data);
            }
        }

        //Get badges
        for(String profileId: mapBadgeDataRes.keySet()){
            
            HttpResponse res = mapBadgeDataRes.get(profileId);
            String resBody = res.getBody();
            
            if (resBody.contains(CalloutConstant.HEROKU_ERROR) || String.isBlank(resBody)) {
                System.debug('Application Error, please try again. API may be down.');
            }else {
                BadgeData data = (BadgeData)JSON.deserialize(resBody.replaceAll('__c', ''), BadgeData.class);                
                mapBadges.put(profileId, data);
            }
        }


        for(Contact trail : scope){
            if(!String.isBlank(trail.Trailhead_username__c)){
                //profile Trail Data
                ProfileCountData profiledata = mapprofileDatas.get(trail.Trailhead_username__c);
                Integer totalChange = 0;
                Integer currentbadge = (Integer)(trail.Badges__c ==null?0:trail.Badges__c);
                Integer currentsupperbadge = (Integer)(trail.Superbadges__c ==null?0:trail.Superbadges__c);
                Integer points;
                Integer badges;

                if(profiledata != null){                    
                    points = (Integer)profiledata.value[0].ProfileCounts[0].EarnedPointTotal;
                    badges = (Integer)profiledata.value[0].ProfileCounts[0].EarnedBadgeTotal;                    
                }

                //Supper badges
                BadgeData supperBadgedata = mapSupBadges.get(trail.Trailhead_username__c);               
                Integer supperbadges = 0;

                if ( supperBadgedata != null
                    && supperBadgedata.value != null 
                    && !supperBadgedata.value.isEmpty() 
                    && supperBadgedata.value[0].EarnedAwards != null 
                    && !supperBadgedata.value[0].EarnedAwards.isEmpty()
                ) {   
                    for (BadgeData.EarnedAwards award : supperBadgedata.value[0].EarnedAwards) {
                        if (award.AwardType == 'Superbadge'){ 
                            supperbadges++;
                        }
                    }                                  
                }


                System.debug('currentbadge=>' + currentbadge + ' | badges=>' + badges + ' | currentsupperbadge=>' + currentsupperbadge + ' | supperbadges=>' + supperbadges);
                totalChange = (badges -currentbadge)+ (supperbadges - currentsupperbadge);                

                if(totalChange > 0){
                    BadgeData badgesdata = mapBadges.get(trail.Trailhead_username__c);
                    if ( badgesdata != null
                        && badgesdata.value != null 
                        && !badgesdata.value.isEmpty() 
                        && badgesdata.value[0].EarnedAwards != null 
                        && !badgesdata.value[0].EarnedAwards.isEmpty()){   
                            
                        List<BadgeData.EarnedAwards> awards = badgesdata.value[0].EarnedAwards;  
                        Integer count = 1;
                        for (BadgeData.EarnedAwards award : awards) {                            

                            if (totalChange >= count ){                                 
                                Trail_Activity__c act = new Trail_Activity__c();                                
                                act.Name = award.Award.Label;
                                act.Icon_Link__c = award.Award.ImageUrl;  
                                act.Trailblazer__c = trail.Id;  
                                act.Date__c = rundate - 1;                                 
                                act.Type__c = award.AwardType;     
                                
                                insertActivites.add(act);

                                count++;
                            }
                        } 
                    }
                    
                }
            }
        }

        System.debug('insertActivites.size()=>' + insertActivites.size());
        if(insertActivites.size() > 0){
            insert insertActivites;
        }

    }

    public void finish(Database.BatchableContext bc){

    }


    public static HttpRequest setupCalloutGetProfileData(String baseEndPoint){
        String restMethod = 'GET';     
        String endpoint = baseEndPoint;                   
        Callout callout = new Callout('', endpoint, restMethod, null);    

        HttpRequest req = HttpCallout.setupHttpRequest(callout);

        return req;
    }

    public static HttpRequest setupCalloutGetSupperbadge(String baseEndPoint){
        String restMethod = 'GET';     
        String endpoint = baseEndPoint + CalloutConstant.SUPERBADGES_PATH;                   
        Callout callout = new Callout('', endpoint, restMethod, null);    

        HttpRequest req = HttpCallout.setupHttpRequest(callout);

        return req;
    }

    public static HttpRequest setupCalloutGetBadges(String baseEndPoint){
        String restMethod = 'GET';     
        String endpoint = baseEndPoint + CalloutConstant.BADGES_PATH + '/1';      
        System.debug(endpoint);            
        Callout callout = new Callout('', endpoint, restMethod, null);    

        HttpRequest req = HttpCallout.setupHttpRequest(callout);

        return req;
    }
}

/**
* @author Thachle
* @date 58/07/2021
*
* Getting Trailblazer information.
*/

public with sharing class GetTrailblazerInfoAsync implements Database.Batchable<SObject>, Database.AllowsCallouts{
    
    public GetTrailblazerInfoAsync() {

    }


    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Id, Trailhead_username__c,Points__c, Profile_Photo__c,Rank__c,Rank_Badge_Link__c,Superbadges__c,
                                        Trails__c,Certifications__c,Badges__c, Trailblazer_Since__c
                                        FROM Contact WHERE Trailhead_username__c != null and Id = '0035g000003VCDNAA4']);
    }

    public void execute(Database.BatchableContext bc, List<Contact> scope){
        Map<String,String> mapContact = new Map<String,String>();

        Map<String, HttpResponse> mapprofileRes = new Map<String, HttpResponse> ();
        Map<String, HttpResponse> mapprofileDataRes = new Map<String, HttpResponse> ();
        Map<String, HttpResponse> mapcertDataRes = new Map<String, HttpResponse> ();
        Map<String, HttpResponse> mapsupperBadgeDataRes = new Map<String, HttpResponse> ();

        Map<String,ProfileData> mapProfiles = new Map<String,ProfileData>();
        Map<String,ProfileCountData> mapprofileDatas = new Map<String,ProfileCountData>();
        Map<String,CertificationData> mapCerts = new Map<String,CertificationData>();
        Map<String,BadgeData> mapSupBadges = new Map<String,BadgeData>();

        List<Contact> updateTrailblazer = new List<Contact>();
        List<SupperBadge__c> upSertsupperBadges = new List<SupperBadge__c>();
        List<Certification__c> upSertCerts = new List<Certification__c>();

        for(Contact trail: scope){
            System.debug('trail.Trailhead_username__c=>' + trail.Trailhead_username__c);
            if(!String.isBlank(trail.Trailhead_username__c)){
                mapContact.put(trail.Trailhead_username__c, trail.Id);

                String baseEndPoint = CalloutConstant.GO_TRAILHEAD_API + '/' + trail.Trailhead_username__c;                

                HttpResponse profileRes = HttpCallout.makeRequest(setupCalloutGetProfile(baseEndPoint));
                HttpResponse profileDataRes = HttpCallout.makeRequest(setupCalloutGetProfileData(baseEndPoint));
                HttpResponse certDataRes = HttpCallout.makeRequest(setupCalloutGetCertification(baseEndPoint));
                HttpResponse supperBadgeDataRes = HttpCallout.makeRequest(setupCalloutGetSupperbadge(baseEndPoint));

                // System.debug('profileRes.getStatus()' + profileRes.getStatus());
                // if(profileRes.getStatus() == '200'){
                    mapprofileRes.put(trail.Trailhead_username__c, profileRes);
                // }

                // System.debug('profileDataRes.getStatus()=>' + profileDataRes.getStatus());
                // if(profileDataRes.getStatus() == '200'){
                    mapprofileDataRes.put(trail.Trailhead_username__c, profileDataRes);
                // }

                System.debug('certDataRes.getStatus()=>' + certDataRes.getStatus());
                // if(certDataRes.getStatus() == '200'){
                    mapcertDataRes.put(trail.Trailhead_username__c, certDataRes);
                // }

                // System.debug('supperBadgeDataRes.getStatus()=>' + supperBadgeDataRes.getStatus());
                // if(supperBadgeDataRes.getStatus() == '200'){
                    mapsupperBadgeDataRes.put(trail.Trailhead_username__c, supperBadgeDataRes);
                // }
            }
        }

        //Profile
        for(String profileId: mapprofileRes.keySet()){
            
            HttpResponse res = mapprofileRes.get(profileId);
            String resBody = res.getBody();
            
            if (resBody.contains(CalloutConstant.HEROKU_ERROR) || String.isBlank(resBody)) {
                System.debug('Application Error, please try again. API may be down.');
            }else {
                ProfileData data = (ProfileData)JSON.deserialize(resBody.replaceAll('__c', ''), ProfileData.class);
                mapProfiles.put(profileId, data);
            }
        }

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

        for(String profileId: mapcertDataRes.keySet()){
            
            HttpResponse res = mapcertDataRes.get(profileId);
            String resBody = res.getBody();
            
            if (resBody.contains(CalloutConstant.HEROKU_ERROR) || String.isBlank(resBody)) {
                System.debug('Application Error, please try again. API may be down.');
            }else {
                CertificationData data = (CertificationData)JSON.deserialize(resBody.replaceAll('__c', ''), CertificationData.class);
                mapCerts.put(profileId, data);
            }
        }

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


        for(Contact trail : scope){
            if(!String.isBlank(trail.Trailhead_username__c)){

                //Profile Info
                ProfileData profile = mapProfiles.get(trail.Trailhead_username__c);

                if(profile != null && !String.isBlank(profile.error)){                   
                    trail.Profile_Photo__c = profile.profilePhotoUrl;
                    trail.Profile_Handle__c = profile.profileUser.TrailblazerId;
                    trail.Company__c = profile.profileUser.CompanyName;
                    trail.Title = profile.profileUser.BID_Role;                  

                    if (!String.isBlank(profile.profileUser.TrailblazerId)) {
                        trail.Profile_Link__c = CalloutConstant.TRAILHEAD_ME + profile.profileUser.TrailblazerId;
                    } else {
                        trail.Profile_Link__c = CalloutConstant.TRAILHEAD_ME_USERID + profile.profileUser.Id;
                    }
                }


                //profile Trail Data
                ProfileCountData profiledata = mapprofileDatas.get(trail.Trailhead_username__c);

                if(profiledata != null){
                    trail.Points__c = profiledata.value[0].ProfileCounts[0].EarnedPointTotal;
                    trail.Badges__c = profiledata.value[0].ProfileCounts[0].EarnedBadgeTotal;
                    trail.Trails__c = profiledata.value[0].ProfileCounts[0].CompletedTrailTotal;
                    trail.Rank__c = profiledata.value[0].ProfileCounts[0].RankLabel.capitalize();
                    trail.Rank_Badge_Link__c = profiledata.value[0].ProfileCounts[0].RankImageUrl;
                }

                //Certification
                CertificationData cerdata = mapCerts.get(trail.Trailhead_username__c);
                
                if (cerdata != null 
                    && cerdata.certificationsList != null 
                    && !cerdata.certificationsList.isEmpty()
                ) {
                    trail.Certifications__c = cerdata.certificationsList.size();

                    for(CertificationData.Certification cerdt : cerdata.certificationsList){
                        Certification__c cer = new Certification__c();
                        cer.Name =  cerdt.title;
                        cer.Certification_Status__c =  cerdt.certificationStatus;
                        cer.CertificationImageUrl__c =  cerdt.certificationImageUrl;
                        cer.Description__c =  cerdt.description;
                        cer.Date_Earned__c =  Date.valueOf(cerdt.dateCompleted);
                        cer.Trailblazer__c = trail.Id;     
                        
                        String certId = cerdt.title.replaceAll(' ', '_') + trail.Id;
                        cer.CertificationId__c = certId;
                        
                        upSertCerts.add(cer);
                    }
                }


                //Supper badges
                BadgeData supperBadgedata = mapSupBadges.get(trail.Trailhead_username__c);               

                if ( supperBadgedata != null
                    && supperBadgedata.value != null 
                    && !supperBadgedata.value.isEmpty() 
                    && supperBadgedata.value[0].EarnedAwards != null 
                    && !supperBadgedata.value[0].EarnedAwards.isEmpty()
                ) {
                    Integer count = 0;

                    for (BadgeData.EarnedAwards award : supperBadgedata.value[0].EarnedAwards) {
                        if (award.AwardType == 'Superbadge'){
                            Supperbadge__c supper = new Supperbadge__c();
                            supper.ImageUrl__c = award.Award.ImageUrl;
                            supper.Name = award.Award.Label;
                            supper.SupperbadgeId__c = award.Award.Id;  
                            supper.Trailblazer__c = trail.Id;             
                            upSertsupperBadges.add(supper);

                            count++;
                        }
                    }

                    trail.Superbadges__c = count;                    
                }

                updateTrailblazer.add(trail);
            } 
        }

        System.debug('updateTrailblazer=>' + updateTrailblazer.size());
        if(updateTrailblazer.size() > 0){
            update updateTrailblazer;
        }

        System.debug('upSertsupperBadges=>' + upSertsupperBadges.size());
        if(upSertsupperBadges.size() > 0){            
            Schema.SObjectField usfield = SupperBadge__c.Fields.SupperbadgeId__c;
            Database.upsert(upSertsupperBadges, usfield, false) ;
        }

        System.debug('upSertCerts=>' + upSertCerts.size());
        if(upSertCerts.size() > 0){            
            Schema.SObjectField usfield = Certification__c.Fields.CertificationId__c;
            Database.upsert(upSertCerts, usfield, false) ;
        }

        
    }

    public void finish(Database.BatchableContext bc){

    }

    public static HttpRequest setupCalloutGetProfile(String baseEndPoint){
        String restMethod = 'GET';      
        String endpoint = baseEndPoint + CalloutConstant.PROFILE_PATH;          
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

    public static HttpRequest setupCalloutGetCertification(String baseEndPoint){
        String restMethod = 'GET';     
        String endpoint = baseEndPoint + CalloutConstant.CERTIFICATIONS_PATH;                   
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


    public static ProfileCountData parseProfileCountJSON(String jsBody){
        try { 
            ProfileCountData traildata = (ProfileCountData) JSON.deserialize(jsBody.replaceAll('__c', ''), ProfileCountData.class);

            return traildata;
        } catch (Exception ex) {
            System.debug('Callout Error' + ex.getMessage());
            return null;
        }
    }


    
}

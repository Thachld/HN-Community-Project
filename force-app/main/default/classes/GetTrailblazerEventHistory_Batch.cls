public with sharing class GetTrailblazerEventHistory_Batch implements Database.Batchable<SObject>, Database.AllowsCallouts {
    private Date rundate;

    public GetTrailblazerEventHistory_Batch() {

    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Id, Contact__c, Contact__r.Trailhead_username__c, Event__c
                                        FROM Event_member__c 
                                        WHERE Event__r.Event_type__c = 'Quest'
                                        AND Event__r.Start_Date__c <= :rundate
                                        AND Event__r.End_Date__c >= :rundate
                                        AND Contact__r.Trailhead_username__c != null]);       
    }

    public void execute(Database.BatchableContext bc, List<Event_member__c> scope){
        
    }

    public void finish(Database.BatchableContext bc){

    }
}

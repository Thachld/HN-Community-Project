public with sharing class GetTrailblazerBadges_Schedule implements  Schedulable{
    
    public GetTrailblazerBadges_Schedule() {
        callBatch();
    }

    public void execute(SchedulableContext sc){
        callBatch();
    }

    public void callBatch(){
        GetTrailblazerBadges_Batch batch = new GetTrailblazerBadges_Batch();
        Database.executeBatch(batch, 2);
    }
}
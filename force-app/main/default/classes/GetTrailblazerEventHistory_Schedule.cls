public with sharing class GetTrailblazerEventHistory_Schedule implements Schedulable{
    public GetTrailblazerEventHistory_Schedule() {
        callBatch();
    }

    public void execute(SchedulableContext sc){
        callBatch();
    }

    public void callBatch(){
        Date rundate = System.today();
        Boolean allowRunRelatedBatchs = true;
        GetTrailblazerEventHistory_Batch batch = new GetTrailblazerEventHistory_Batch(rundate, allowRunRelatedBatchs);
        Database.executeBatch(batch, 5);
    }
}
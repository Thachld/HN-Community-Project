/**
* @author Thachle
* @date 58/07/2021
*
* Schedule get trailblazer  
*/
public with sharing class GetTrailblazerInfoAsync_Schedule implements Schedulable{
    public GetTrailblazerInfoAsync_Schedule() {
        callBatch();
    }

    public void execute(SchedulableContext sc){
        callBatch();
    }

    public void callBatch(){
        Boolean allowRunRelatedBatchs = true;
        GetTrailblazerInfoAsync batch = new GetTrailblazerInfoAsync(allowRunRelatedBatchs);
        Database.executeBatch(batch, 10);
    }
}
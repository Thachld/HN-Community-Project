/**
* @author ThachLe
* @date 8/07/2021
*
* A class to deserialize Trailhead Certification data from the API into.
*/
public class CertificationData {
    public String error { get; set; }
    
    @AuraEnabled
    public List<certification> certificationsList { get; set; }

    public class Certification {
        @AuraEnabled
        public String dateExpired { get; set; }

        @AuraEnabled
        public String dateCompleted { get; set; }

        @AuraEnabled
        public String certificationUrl { get; set; }

        @AuraEnabled
        public String description { get; set; }

        @AuraEnabled
        public String certificationStatus { get; set; }

        @AuraEnabled
        public String title { get; set; }

        @AuraEnabled
        public String certificationImageUrl { get; set; }        
    }
}
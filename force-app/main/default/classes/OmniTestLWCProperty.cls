Global with sharing class OmniTestLWCProperty {

    @InvocableMethod (label='Test - Add Skill Requirement' configurationEditor='c:omniSkillInputs')
    public static List<List<SkillRequirement>> routeUsingSkills(List<SkillRequirementRequest> requests) {     
        
        List<List<SkillRequirement>> returnList = new List<List<SkillRequirement>>();
        for (SkillRequirementRequest request : requests) {
            
            if (request.skillRequirements == null){
                request.skillRequirements = new List<SkillRequirement>();
            }
            
            // Now add SkillRequirement(s)
            SkillRequirement srObj = new SkillRequirement(
                SkillId = getSkillId(request.SkillName),
                SkillLevel = request.SkillLevel
            );
            if (request.additionalSkill != null && request.additionalSkill == true){
                srObj.IsAdditionalSkill = true;
                if (request.additionalSkillPriority!=null){
                    srObj.SkillPriority = request.additionalSkillPriority;
                }
            }
            request.skillRequirements.add(srObj);
            returnList.add(request.skillRequirements);
        }
        return returnList;
    }
        
    public static String getSkillId(String skillName) {      
        Skill skill = [Select Id From Skill Where DeveloperName = :skillName];
        return skill.Id;
    }
    
    global class SkillRequirementRequest
    {
        @InvocableVariable(label = 'Skill Requirement list')
        global List<SkillRequirement> skillRequirements;
        @InvocableVariable(required=true label = 'Skill Developer Name')
        @AuraEnabled
        global String skillName;
        @InvocableVariable(required=true label = 'Skill Level')
        global Integer skillLevel;
        @InvocableVariable(label = 'Additional Skill')
        global Boolean additionalSkill;      
        @InvocableVariable (label = 'Additional Skill Priority')
        global Integer additionalSkillPriority;
    }    
}
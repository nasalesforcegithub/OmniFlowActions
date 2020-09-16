global class OmniRoutingHelper {
    
    @InvocableMethod (label='Omni - Route Work')
    public static List<String> routeOmniWorkItem(List<WorkItemRoutingRequest> requests) {
        
        List<String> agentList = new List<String>();
        for (WorkItemRoutingRequest request : requests){        
            if (request.routingType == 'Skills'){
                routeWorkToSkills(request);
                //agentList.add(getAgentListForSkills(request));
            } else if (request.routingType == 'Queue'){
                routeWorkToQueue(request);
                //agentList.add(getAgentListForQueue(request));
            } else if (request.routingType == 'Agent'){
                routeWorkToAgent(request);
                //agentList.add(getAgentForUserId(request));
            } else if (request.routingType == 'Bot'){
                routeWorkToBot(request);
            }
        }
        
        return agentList;        
    }
    
    public static void routeWorkToSkills(WorkItemRoutingRequest request){
        // Add SkillsBased PendingServiceRouting
        // Make sure that IsReadyForRouting = False until Skills are added
        PendingServiceRouting psrObj = new PendingServiceRouting(
            CapacityWeight = request.routingWeight,
            IsReadyForRouting = FALSE,
            RoutingModel  = request.routingModel,
            RoutingPriority = request.routingPriority,
            RoutingType = 'SkillsBased',
            DropAdditionalSkillsTimeout = request.additionalSkillsTimeout,
            ServiceChannelId = getChannelId('Cases'),
            WorkItemId = request.record.Id
            
        );
        insert psrObj;
        //Get the ID of the newly created PendingServiceRouting to use for attaching Skills
        psrObj = [select id, IsReadyForRouting from PendingServiceRouting where id = : psrObj.id];
        
        //Add Skill Requirements
        for (SkillRequirement sr : request.skillList){
            sr.RelatedRecordId = psrObj.Id;
        }
        insert request.skillList;
        psrObj.IsReadyForRouting = true;
        update psrObj;
    }
    
    public static void routeWorkToQueue(WorkItemRoutingRequest request){
        Case r = request.record;
        r.OwnerId = request.QueueName;
        update r;
        System.debug('Routed work to Queue');
    }
    
    public static void routeWorkToAgent(WorkItemRoutingRequest request){
        PendingServiceRouting psrObj = new PendingServiceRouting(
            CapacityWeight = request.routingWeight,
            IsReadyForRouting = TRUE,
            RoutingModel  = request.routingModel,
            RoutingPriority = request.routingPriority,
            RoutingType = 'SkillsBased',
            ServiceChannelId = getChannelId('Cases'),
            WorkItemId = request.record.Id,
            PreferredUserId = request.agentName
        );
        insert psrObj;
    }
    
    public static void routeWorkToBot(WorkItemRoutingRequest request){
        //N/A not possible yet        
    }
    
    public static String getChannelId(String channelName) {
        ServiceChannel channel = [Select Id From ServiceChannel Where DeveloperName = :channelName];
        return channel.Id;
    }
    
    public static String getAgentListForSkills(WorkItemRoutingRequest request){
        System.debug('Getting Agent List for Skills');
        Integer skillNum = request.skillList.size();
        List<Id> skillIds = new List<Id>();
        for (SkillRequirement sr : request.skillList){
            skillIds.add(sr.SkillId);
            System.debug('Skill ID is ' + sr.SkillId);
        }
        System.debug('SkillIds size is ' + skillIds.size());
        List<AggregateResult> srsList = [SELECT ServiceResourceId from ServiceResourceSkill WHERE SkillId IN :skillIds AND IsDeleted = False Group By ServiceResourceId HAVING COUNT(Id) = :skillNum];
        System.debug('Service Resource Number is ' + srsList.size());
        
        String agentList = '';
        for (AggregateResult ar : srsList){
            String srId = ar.get('ServiceResourceId').toString();
            User u = [SELECT ID, Name, Username from User WHERE ID IN (SELECT RelatedRecordID From ServiceResource WHERE ID = :srId)];
            System.debug('SKILL USERS = User ID and Name ' + u.Id + ' ' + u.Name);
            agentList += u.Username;
            agentList += ',';
        }
        System.debug('AGENT LIST IS ' + agentList);
        return agentList;
    }
    
    public static String getAgentListForQueue(WorkItemRoutingRequest request){
        String agentList = '';
        System.debug('Getting agent list for Queue ' + request.QueueName);
        List<Group> queueList = [SELECT ID from Group where Id = :request.QueueName];
        System.debug('Queue List size is ' + queueList.size());
        if (queueList.size()>0){
            String queueId = queueList[0].Id;
            List<User> uList = [SELECT ID, Name, Username from User WHERE ID IN (Select UserOrGroupId from GroupMember WHERE GroupID =:queueId)];
            for (User u : uList){
                System.debug('Queue USERS = User ID and Name ' + u.Id + ' ' + u.Name);
                agentList += u.Username;
                agentList += ',';                
            }
        }
        System.debug('AGENT LIST IS ' + agentList);
        return agentList;
    }
    
    public static String getAgentForUserId(WorkItemRoutingRequest request){
        String agentList = '';
        User u = [SELECT ID, Username FROM User where Id = : request.agentName];
        agentList += u.Username;
        System.debug('AGENT LIST IS ' + agentList);        
        return agentList;
    }
    
    
    global class WorkItemRoutingRequest
    {
        @InvocableVariable(required=true label = 'Record')
        global Case record;
        @InvocableVariable(required=true label = 'Routing Type')
        global String routingType;
        @InvocableVariable(label = 'Queue Name')
        global String queueName;
        @InvocableVariable(label = 'Skill Requirement List')
        global List<SkillRequirement> skillList;
        @InvocableVariable(label = 'Agent Name')
        global String agentName;
        @InvocableVariable(label = 'Bot Name')
        global String botName;          
        @InvocableVariable(label = 'Routing Priority')
        global Integer routingPriority;
        @InvocableVariable(label = 'Routing Weight')
        global Integer routingWeight;
        @InvocableVariable(label = 'Routing Model')
        global String routingModel;
        @InvocableVariable(label = 'Additional Skills Timeout')
        global Integer additionalSkillsTimeout;
    }    
}
import {api, track, LightningElement} from 'lwc';

export default class OmniSkillInputs extends LightningElement {

    @api builderContext;
     
    selectedRecordId; //store the record id of the selected 
    handleValueSelcted(event) {
        this.selectedRecordId = event.detail;
    }
    selectedSkillLevel; //store the selected skill level
    handleValueSelctedSkillLevel(event){
        this.selectedSkillLevel = event.target.name;
    }
    handleValueSelctedAdditional(event){
        this.selectedSkillAdditional = event.target.name;
    }

    handleValueSelctedSkillPriority(event){
        this.selectedSkillPriority = event.target.name;
    }

}
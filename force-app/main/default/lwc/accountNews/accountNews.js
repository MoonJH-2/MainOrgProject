import { LightningElement, api, track } from 'lwc';
import fetchAccountNews from '@salesforce/apex/AccountNewsController.fetchAccountNews';
export default class AccountNews extends LightningElement {
    @api recordId;
    @track cardObjects = [];

    connectedCallback(){
        fetchAccountNews({
            recordId : this.recordId
        }).then(result =>{
            console.log('result :', result);
            this.cardObjects = result;
        })
        .catch(error =>{
            console.log('error msg : ', error);
            
        })
    }

    goToLink(event){
        try {
            let cardId = event.currentTarget.dataset.id;
            let card = this.cardObjects.find(card => card.index == cardId);
            if(card && card.url){
                window.open(card.url, '_blank');
            }
        } catch (error) {
            console.log('goToLink error : ', error);
            
        }
    }
    
}
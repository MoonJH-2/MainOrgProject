import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getAccountSalesInsight from '@salesforce/apex/AccountSalesInsightService.getAccountSalesInsight';
import executeAction from '@salesforce/apex/AccountSalesInsightService.executeAction';

export default class AccountSalesInsight extends NavigationMixin(LightningElement) {
    @api recordId; // Account Id
    @track salesData;
    @track isLoading = true;
    @track error;

    @wire(getAccountSalesInsight, { accountId: '$recordId' })
    wiredAccountData({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.salesData = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.salesData = undefined;
            console.error('Account Sales Insight 오류:', error);
        }
    }

    // Getter for priority badge variant
    get priorityVariant() {
        if (!this.salesData) return 'base';
        
        switch(this.salesData.priorityLevel) {
            case '최우선': return 'error';
            case '높음': return 'warning';
            case '중간': return 'success';
            default: return 'base';
        }
    }

    // Getter for formatted revenue
    get formattedRevenue() {
        if (!this.salesData || !this.salesData.recentRevenue) return '₩0';
        return '₩' + this.salesData.recentRevenue.toLocaleString();
    }

    // Getter for formatted opportunity amount
    get formattedOpportunityAmount() {
        if (!this.salesData || !this.salesData.opportunityForecast) return '₩0';
        return '₩' + this.salesData.opportunityForecast.expectedAmount.toLocaleString();
    }

    // Getter for opportunity count
    get opportunityCount() {
        return this.salesData?.opportunityCount || 0;
    }

    // Getter for case count  
    get caseCount() {
        return this.salesData?.caseCount || 0;
    }

    // Getter for contact count
    get contactCount() {
        return this.salesData?.contactCount || 0;
    }

    // Handle quick action execution
    async handleQuickAction(event) {
        const actionType = event.target.dataset.action;
        this.isLoading = true;

        try {
            const result = await executeAction({
                accountId: this.recordId,
                actionType: actionType,
                actionData: event.target.label
            });

            // Handle specific actions
            if (actionType === 'visitWebsite' && result) {
                window.open(result, '_blank');
            } else if (actionType === 'addContact' && result) {
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: result
                    }
                });
            } else if (result.includes('ID:')) {
                // Navigate to created record
                const recordId = result.match(/ID: ([a-zA-Z0-9]{15,18})/)[1];
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: recordId,
                        actionName: 'view'
                    }
                });
            }

            // Show success toast
            this.showToast('성공', result, 'success');

        } catch (error) {
            console.error('Quick Action 실행 오류:', error);
            this.showToast('오류', error.body?.message || '액션 실행 중 오류가 발생했습니다.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Handle recommended action execution
    async handleRecommendedAction(event) {
        const actionType = event.target.dataset.actionType;
        const actionTitle = event.target.dataset.title;
        
        this.isLoading = true;

        try {
            const result = await executeAction({
                accountId: this.recordId,
                actionType: actionType,
                actionData: actionTitle
            });

            this.showToast('완료', `${actionTitle}이(가) 처리되었습니다.`, 'success');
            
            // Refresh data
            this.refreshData();

        } catch (error) {
            console.error('추천 액션 실행 오류:', error);
            this.showToast('오류', error.body?.message || '액션 실행 중 오류가 발생했습니다.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Navigate to new opportunity creation
    handleCreateOpportunity() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Opportunity',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: `AccountId=${this.recordId}`
            }
        });
    }

    // Navigate to new contact creation
    handleCreateContact() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Contact',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: `AccountId=${this.recordId}`
            }
        });
    }

    // Navigate to new task creation
    handleCreateTask() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Task',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: `WhatId=${this.recordId}`
            }
        });
    }

    // Navigate to email composer
    handleSendEmail() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/lightning/o/EmailMessage/home?ws=%2Flightning%2Fr%2FAccount%2F${this.recordId}%2Fview`
            }
        });
    }

    // Show toast notification
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    // Refresh component data
    refreshData() {
        // Force refresh by updating recordId
        const currentRecordId = this.recordId;
        this.recordId = null;
        setTimeout(() => {
            this.recordId = currentRecordId;
        }, 100);
    }

    // Navigate to related list
    handleViewRelated(event) {
        const relatedObject = event.target.dataset.object;
        
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.recordId,
                relationshipApiName: relatedObject,
                actionName: 'view'
            }
        });
    }

    // Handle alert setup
    handleSetupAlerts() {
        // This would typically open a modal or navigate to alert configuration
        this.showToast('알림 설정', 'Key Account 주간 체크인 알림이 설정되었습니다.', 'success');
    }

    // Getter for component visibility
    get hasData() {
        return this.salesData && this.salesData.account;
    }

    get hasRecommendedActions() {
        return this.salesData && this.salesData.recommendedActions && this.salesData.recommendedActions.length > 0;
    }

    get hasSalesInsights() {
        return this.salesData && this.salesData.salesInsights && this.salesData.salesInsights.length > 0;
    }

    get hasOpportunityForecast() {
        return this.salesData && this.salesData.opportunityForecast;
    }
}

import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createOrder from '@salesforce/apex/OrderCreatorController.createOrder';

// Datatable 컬럼 정의
const columns = [
    { label: '회차', fieldName: 'installmentNumber', type: 'number', cellAttributes: { alignment: 'center' } },
    { label: '납부 예정일', fieldName: 'dueDate', type: 'date-local' },
    { label: '납부 금액', fieldName: 'amount', type: 'currency', cellAttributes: { alignment: 'right' } }
];

export default class OrderCreator extends NavigationMixin(LightningElement) {
    // 입력 필드 값을 저장할 속성
    @track accountId;
    @track orderStartDate;
    @track totalAmount;
    @track paymentMethod;
    isSaving = false;

    // 미리보기 테이블 관련 속성
    @track scheduleData = [];
    scheduleColumns = columns;
    
    // 납부 방식 선택 옵션
    get paymentMethodOptions() {
        return [
            { label: '월별', value: '월별' },
            { label: '분기별', value: '분기별' },
            { label: '반기별', value: '반기별' },
            { label: '년별', value: '년별' },
        ];
    }

    // 미리보기 테이블 표시 여부를 결정하는 getter
    get showPreview() {
        return this.scheduleData.length > 0;
    }

    // 입력 필드 값 변경 시 호출될 핸들러
    handleInputChange(event) {
        const field = event.target.name;
        const value = event.target.value;
        if (field === 'EffectiveDate') this.orderStartDate = value;
        if (field === 'TotalAmount') this.totalAmount = value;
        if (field === 'Payment_Method__c') this.paymentMethod = value;
        
        this.updateSchedulePreview();
    }
    
    // Account 선택 시 호출될 핸들러
    handleAccountSelection(event){
        this.accountId = event.detail.recordId;
        this.updateSchedulePreview();
    }

    // 미리보기 업데이트 로직
    updateSchedulePreview() {
        if (!this.orderStartDate || !this.totalAmount || !this.paymentMethod) {
            this.scheduleData = []; // 필수값이 없으면 미리보기 초기화
            return;
        }

        const frequencyMap = { '월별': 12, '분기별': 4, '반기별': 2, '년별': 1 };
        const numberOfInstallments = frequencyMap[this.paymentMethod];
        const installmentAmount = this.totalAmount / numberOfInstallments;
        const monthIncrement = 12 / numberOfInstallments;
        
        let newSchedule = [];
        for (let i = 1; i <= numberOfInstallments; i++) {
            let dueDate = new Date(this.orderStartDate);
            dueDate.setMonth(dueDate.getMonth() + (i - 1) * monthIncrement);
            
            newSchedule.push({
                id: i,
                installmentNumber: i,
                dueDate: dueDate.toISOString().slice(0, 10),
                amount: installmentAmount
            });
        }
        this.scheduleData = newSchedule;
    }

    // 저장 버튼 클릭 핸들러
    handleSave() {
        if (!this.accountId) {
            this.showToast('Error', 'Please select an Account.', 'error');
            return;
        }

        this.isSaving = true;

        const orderData = {
            sobjectType: 'Order',
            AccountId: this.accountId,
            EffectiveDate: this.orderStartDate,
            TotalAmount: this.totalAmount,
            Payment_Method__c: this.paymentMethod,
            Status: 'Draft' // 기본 상태 지정
        };

        createOrder({ orderToCreate: orderData })
            .then(orderId => {
                this.showToast('Success', 'Order was created successfully.', 'success');
                // 생성된 Order 레코드 페이지로 이동
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: orderId,
                        objectApiName: 'Order',
                        actionName: 'view'
                    }
                });
            })
            .catch(error => {
                this.showToast('Error creating record', error.body.message, 'error');
                this.isSaving = false;
            });
    }
    
    // Toast 메시지 표시 유틸리티
    showToast(title, message, variant) {
        const event = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(event);
    }
}
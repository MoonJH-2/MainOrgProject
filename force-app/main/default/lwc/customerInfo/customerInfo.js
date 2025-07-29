import { LightningElement } from 'lwc';

export default class CustomerInfo extends LightningElement {
      formData={
        purpose:'',
        country:'',
        budget:'',
        service:''
    }

    countryOptions = [
        { label: '미국', value: 'united states' },
        { label: '영국', value: 'united kingdom' },
        { label: '캐나다', value: 'canada' },
        { label: '호주', value: 'australia' },
        { label: '독일', value: 'germany' },
        { label: '일본', value: 'japan' },
        { label: '프랑스', value: 'france' },
        { label: '뉴질랜드', value: 'new zealand' },
        { label: '네덜란드', value: 'netherlands' },
        { label: '싱가포르', value: 'singapore' }
    ]

    serviceOptions= [
        { label: '입학 전략 컨설팅', value: 'admission_strategy' },
        { label: '에세이/자소서 첨삭', value: 'essay_review' },
        { label: '인터뷰 준비', value: 'interview_preparation' },
        { label: '학비 장학금 정보', value: 'scholarship_info' },
        { label: '비자 신청 지원', value: 'visa_support' }
]

    handleChange(event){
        const {name, value} = event.target
        this.formData[name] = value
    }
    generateResults() {
        const event = new CustomEvent('generate', {
            detail: {
             formData: this.formData
            }
        });
        this.dispatchEvent(event);
}

}


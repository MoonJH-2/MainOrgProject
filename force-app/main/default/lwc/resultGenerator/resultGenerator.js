import { LightningElement } from 'lwc';
import generateAIResults from '@salesforce/apex/AIResultController.generateAIResults'
export default class ResultGenerator extends LightningElement {
    formData={}
    results = []
    isGenerating = false
    error=''

    async generateResults(event){
        this.error= ''
         
        this.formData = event.detail.formData
        console.log("this.formData", JSON.stringify(this.formData));
        if(!this.formData?.purpose){
            this.error = '유학 목적을 상세하게 작성하여주세요'
            return
        }
        if(!this.formData?.country){
            this.error = '진학을 희망하는 국가를 선택해주세요!'
            return
        }
        this.isGenerating = true
        try{
            const result = await generateAIResults({
                purpose:this.formData.purpose,
                country:this.formData.country,
                service:this.formData.service,
                budget:this.formData.budget
            })
            console.log("result", result)
            this.formatResponse(result)
        }catch(error){
            console.error("에러가 발생했습니다:", error)
            this.error = error.body?.message || error.message ||'An unexpected error occurred';
        } finally{
            this.isGenerating = false
        }
        
    }

    formatResponse(result){
        const correctJson = result.replaceAll(/[\n\u00A0]/g, '').trim()
        const parsedResponse = JSON.parse(correctJson)

        if(parsedResponse?.results?.length>0){
            this.results = parsedResponse.results.map(result=>{
                if(!result.tags){
                    result.tags = []
                }
                // if(!result.total_time){
                //     const prepTime = parseInt(result.prep_time) || 0;
                //     const cookTime = parseInt(result.cook) || 0;
                //     result.total_time = `${prepTime + cookTime} min`
                // }
                return result
            })
        } else {
            this.error = '에러 발생 : 입력 데이터를 상세하게 작성해주세요'
            this.results = []
        }

    }
}
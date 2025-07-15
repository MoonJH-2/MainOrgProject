({
    doInit: function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var vfPageUrl = '/apex/Quotation_PDF?Id=' + recordId; // Visualforce 페이지 이름(QuotePreview)과 ID 전달
        component.set("v.vfPageUrl", vfPageUrl);
        console.log('url', component.get('v.vfPageUrl'));
    }
})
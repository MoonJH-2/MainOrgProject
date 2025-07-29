public with sharing class AIResultController {
    @AuraEnabled
    public static String generateAIResults(String purpose, String country, String service, String budget) {
        try{
            //1. First will create a Map to hold the input Values

           Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();

           ConnectApi.WrappedValue purposeValue = new ConnectApi.WrappedValue();
           purposeValue.value = purpose;
           ConnectApi.WrappedValue countryValue = new ConnectApi.WrappedValue();
           countryValue.value = country;
           ConnectApi.WrappedValue serviceValue = new ConnectApi.WrappedValue();
            serviceValue.value = service;
           ConnectApi.WrappedValue budgetValue = new ConnectApi.WrappedValue();
            budgetValue.value = budget;

          inputParams.put('Input:Purpose', purposeValue);
          inputParams.put('Input:Country', countryValue);
          inputParams.put('Input:Service', serviceValue);
          inputParams.put('Input:Budget', budgetValue);

          //2. Will create the configuration which is required for invoking the prompt template
          ConnectApi.EinsteinPromptTemplateGenerationsInput executeTemplateInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
          executeTemplateInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
          executeTemplateInput.additionalConfig.applicationName = 'PromptBuilderPreview';
          executeTemplateInput.isPreview = false;
          executeTemplateInput.inputParams = inputParams;

          //3. Invoke the EinsteinLLM APi and execute the prompt template
           ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generationsOutput = ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
            'Quick_Consulting',
            executeTemplateInput
          );


          //4. return the response
         ConnectApi.EinsteinLLMGenerationItemOutput response= generationsOutput.generations[0];
         return response.text;

        }catch(Exception e){
             throw new AuraHandledException('Error generating results: ' + e.getMessage());
        }

    }
}
import { IExecuteFunctions } from 'n8n-workflow';

// Simple n8n code - Build Analyzer Input (merge all items)
function execute(this: IExecuteFunctions) {
  const inputItems = this.getInputData();
  
  const mergedResult = {
    userPrompt: "",
    systemPrompt: "",
    previousSteps: new Array(),
    newEvidence: ""
  };

  for (const item of inputItems) {
    const data = item.json;
    
    if (!mergedResult.userPrompt && data.userPrompt) {
      mergedResult.userPrompt = String(data.userPrompt);
    }
    
    if (!mergedResult.systemPrompt && data.systemPrompt) {
      mergedResult.systemPrompt = String(data.systemPrompt);
    }
    
    if (data.previousSteps && Array.isArray(data.previousSteps)) {
      mergedResult.previousSteps.push(...data.previousSteps);
    }
    
    if (data.newEvidence) {
      mergedResult.newEvidence = String(data.newEvidence);
    }
  }

  return [{ json: mergedResult }];
}

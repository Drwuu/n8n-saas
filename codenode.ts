import {
  IExecuteFunctions,
  INodeExecutionData,
  IDataObject,
} from 'n8n-workflow';

// Define proper interfaces for our data structure
interface AnalyzerInput extends IDataObject {
  userPrompt: string;
  systemPrompt: string;
  previousSteps: any[];
  newEvidence: string;
}

interface InputData extends IDataObject {
  userPrompt?: string;
  systemPrompt?: string;
  previousSteps?: any[];
  newEvidence?: string;
}

// Properly typed n8n Code node function - Build Analyzer Input (Run Once for All Items - Merged)
async function execute(this: IExecuteFunctions): Promise<INodeExecutionData[]> {
  // Get all input items with proper typing
  const inputItems: INodeExecutionData[] = this.getInputData();
  
  const mergedResult: AnalyzerInput = {
    userPrompt: "",
    systemPrompt: "",
    previousSteps: [],
    newEvidence: ""
  };

  // Process and merge all input items
  for (const item of inputItems) {
    const data = item.json as InputData;
    
    // Take first non-empty userPrompt
    if (!mergedResult.userPrompt && data.userPrompt) {
      mergedResult.userPrompt = data.userPrompt;
    }
    
    // Take first non-empty systemPrompt
    if (!mergedResult.systemPrompt && data.systemPrompt) {
      mergedResult.systemPrompt = data.systemPrompt;
    }
    
    // Merge all previousSteps arrays
    if (data.previousSteps && Array.isArray(data.previousSteps)) {
      mergedResult.previousSteps = mergedResult.previousSteps.concat(data.previousSteps);
    }
    
    // Take last non-empty newEvidence (or could be first by moving this condition)
    if (data.newEvidence) {
      mergedResult.newEvidence = data.newEvidence;
    }
  }

  return [{ json: mergedResult }];
}

// Export for n8n usage (copy the function body to n8n Code node)
export { execute };

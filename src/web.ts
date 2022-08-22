import { WebPlugin } from '@capacitor/core';
import { CallbackID, DeleteModelCallback, DeleteModelOptions, Model, Models, MultipleModelCallback, RecognitionOptions, SingularModelCallback } from '.';

import type { XYTOptions, DigitalInkPlugin } from './definitions';

export class DigitalInkWeb extends WebPlugin implements DigitalInkPlugin {
  async initializePlugin(): Promise<{ ok: boolean, msg: string }> {
    return {
      ok: false,
      msg: "INITIALIZENOTIFICATIONS() We are in web debug"
    }
  }
  
  async erase(): Promise<{ ok: boolean, msg: string }> {
    return {
      ok: false,
      msg: 'ERASE() We are in web debug'
    }
  }

  async logStrokes(options: XYTOptions): Promise<{ ok: boolean, msg: string, options: XYTOptions }> {
    return {
      ok: false,
      options: options,
      msg: "LOGSTROKES() We are in web debug"
    }
  }
  
  async doRecognition(options: RecognitionOptions) :Promise<{ ok: boolean, msg: string, results: { candidates: string[], scores: number[] }, options: RecognitionOptions }> { return {
      ok: false,
      msg: 'DORECOGNITION() We are in web debug',
      results: {
        candidates: ['a', 'b', 'c'],
        scores: [0, 1, 2]
      },
      options: options
    }
  }

  async downloadSingularModel(model: Model, callback: SingularModelCallback): Promise<CallbackID> {
    console.log({"Options": model, "Callback": callback})
    
    return "WEB DEBUG CALLBACK ID SINGULAR"
  }

  async downloadMultipleModels(models: Models, callback: MultipleModelCallback): Promise<CallbackID> {
    console.log({"Options": models, "Callback": callback})
    
    return "WEB DEBUG CALLBACK ID MULTIPLE"
  }

  async deleteModel(options: DeleteModelOptions, callback: DeleteModelCallback): Promise<CallbackID> {
    console.log({"Options": options, "Callback": callback})

    return "WEB DEBUG CALLBACK ID DELETE"
  }

  async getDownloadedModels(): Promise<{ok: true, msg: string, models: string[]}> {
    return {
      ok: true,
      msg: "GETDOWNLOADEDMODELS() We are in web debug",
      models: ["en-US", "debug"]
    }
  }
}

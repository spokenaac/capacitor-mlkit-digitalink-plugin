import { WebPlugin } from '@capacitor/core';
import { CallbackID, DeleteModelCallback, DeleteModelOptions, Model, Models, MultipleModelCallback, RecognitionOptions, SingularModelCallback } from '.';

import type { XYTOptions, DigitalInkPlugin } from './definitions';

export class DigitalInkWeb extends WebPlugin implements DigitalInkPlugin {

  traces: number[][][] = [];
  
  url: string = "https://www.google.com.tw/inputtools/request?ime=handwriting&app=mobilesearch&cs=1&oe=UTF-8";
  
  modelLookupTable: { [key: string]: string} = {
    'zxx-Zsym-x-autodraw': 'autodraw',
    'en-US': 'en'
  }

  async initializePlugin(): Promise<{ ok: boolean, msg: string }> {
    return {
      ok: false,
      msg: "***INK WEB: This method not implemented."
    }
  }
  
  async erase(): Promise<{ ok: boolean, msg: string }> {
    try {
      this.traces = [];

      return {
        ok: true,
        msg: '***INK WEB: Reset stored stroke data.'
      }
    }
    catch {
      return {
        ok: false,
        msg: '***INK WEB: Something went wrong clearing stroke data!'
      }
    }
  }

  async logStrokes(options: XYTOptions): Promise<{ ok: boolean, msg: string, options: XYTOptions }> {
    try {
      // push another stroke to our traces
      this.traces.push([options.x, options.y, options.t || []]);

      return {
        ok: true,
        options: options,
        msg: "***INK WEB: Stroke logged successfully."
      }
    }
    catch {
      return {
        ok: false,
        options: options,
        msg: "***INK WEB: Something went wrong parsing stroke request body!"
      }
    }
  }
  
  async doRecognition(options: RecognitionOptions): Promise<{
    ok: boolean,
    msg: string,
    options: RecognitionOptions,
    results: {
      candidates: string[],
      scores: number[]
    }
  }> {
    try {
      const reqModel = options.model || 'en-US';

      const requestParams = {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          'options': 'enable_pre_space',
          'requests': [
            {
              'writing_guide': {
                'writing_area_width': options.writingArea.w || undefined,
                'writing_area_height': options.writingArea.h || undefined
              },
              'ink': this.traces,
              'language': this.modelLookupTable[reqModel] || 'en'
            }
          ]
        })
      }

      let candidates: string[] = [];
      let scores: number[] = [];

      const response = await fetch(this.url, requestParams);
      const data = await response.json();

      if (data[0] !== "FAILED_TO_PARSE_REQUEST_BODY") {
        candidates = data[1][0][1];
      }
      else {
        return {
          ok: false,
          msg: '***INK WEB: Something went wrong performing recognition (via web API) at url: ' + this.url,
          options: options,
          results: {
            candidates: candidates,
            scores: scores
          }
        }
      }

      return {
        ok: true,
        msg: '***INK WEB: Recognition call returned successfully!',
        options: options,
        results: {
          candidates: candidates,
          scores: scores
        }
      }
    }
    catch {
      return {
        ok: false,
        msg: '***INK WEB: Something went wrong performing recognition (via web API) at url: ' + this.url,
        options: options,
        results: {
          candidates: [],
          scores: []
        }
      }
    }
  }

  async downloadSingularModel(model: Model, callback: SingularModelCallback): Promise<CallbackID> {
    console.log('***INK WEB: downloadSingularModel(): ', {"Options": model, "Callback": callback})
    
    return "WEB DEBUG CALLBACK ID SINGULAR"
  }

  async downloadMultipleModels(models: Models, callback: MultipleModelCallback): Promise<CallbackID> {
    console.log('***INK WEB: downloadMultipleModels(): ', {"Options": models, "Callback": callback})
    
    return "WEB DEBUG CALLBACK ID MULTIPLE"
  }

  async deleteModel(options: DeleteModelOptions, callback: DeleteModelCallback): Promise<CallbackID> {
    console.log('***INK WEB: deleteModel(): ', {"Options": options, "Callback": callback})

    return "WEB DEBUG CALLBACK ID DELETE"
  }

  async getDownloadedModels(): Promise<{ok: true, msg: string, models: string[]}> {
    return {
      ok: true,
      msg: "***INK WEB: No models are downloaded in web implementation.",
      models: []
    }
  }
}

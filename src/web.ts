import { WebPlugin } from '@capacitor/core';

import type { XYTOptions, ModelOptions, DigitalInkPlugin } from './definitions';

export class DigitalInkWeb extends WebPlugin implements DigitalInkPlugin {
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

  async deleteModel(all?: boolean, options?: ModelOptions): Promise<{ ok: boolean, all: boolean, msg: string, options?: ModelOptions }> {
    return {
      ok: false,
      options: options,
      all: all || false,
      msg: "DELETEMODEL() We are in web debug"
    }
  }

  async downloadModel(options: ModelOptions): Promise<{ ok: boolean, msg: string, options?: ModelOptions }> {
    return {
      ok: false,
      options: options,
      msg: 'DOWNLOADMODEL() We are in web debug'
    }
  }
  
  async doRecognition(model?: string, context?: string, writingArea?: { w: number, h: number })
  :Promise<{
    ok: boolean,
    msg: string,
    model?: string,
    context?: string,
    writingArea?: { w: number, h: number }
    results: { candidates: string[], scores: number[] },
  }> {
    return {
      ok: false,
      model: model,
      context: context,
      writingArea: writingArea,
      msg: 'DORECOGNITION() We are in web debug',
      results: { candidates: ['a', 'b', 'c'], scores: [0, 1, 2] }
    }
  }
}

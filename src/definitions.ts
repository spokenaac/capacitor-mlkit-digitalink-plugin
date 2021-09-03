export interface DigitalInkPlugin {
  /**
   * Erases natively stored stroke/point/ink data
   */
   erase(): Promise<{ ok: boolean, msg: string }>

   /**
    * Sends XY coordinate data to native code to be prepared for model inference
    * Can include/exclude time values
    * 
    * Ensure all units for coordinates/time are consistent between logs. Unit types don't matter,
    * they just need to be the same -- all values are normalized
    * 
    * @param options - [ X coordinate, Y coordinate, T time in milliseconds ]
    */
   logStrokes(options: XYTOptions): Promise<{ ok: boolean, msg: string, options: XYTOptions }>
 
   /**
    * Deletes a singular/collection of models downloaded to the device, or all models.
    * 
    * @param all deletes all models on device
    * @param model singular model to delete from device storage
    * @param models array of models to delete from device storage
    */
   deleteModel(all?: boolean, options?: ModelOptions): Promise<{ ok: boolean, all: boolean, msg: string, options?: ModelOptions }>
   
   /**
    * Downloads a singular/collection of models downloaded to the device, or all models.
    * 
    * @param model singular model to download from device storage
    * @param models array of models to download from device storage
    */
   downloadModel(options?: ModelOptions): Promise<{ ok: boolean, msg: string, options?: ModelOptions }>
   
   /**
    * Runs inference either on the provided model via the model param, or on the default English model.
    * All params are optional.
    * 
    * @param model singular model to use for inference
    * @param context precontext to provide. Some letters/words may be mistaken for others, use this to disambiguate expected responses.
    * @param writingArea width and height of the drawing area. Only provide for further context--i.e. if writing two lines of text.
    */
    doRecognition(model?: string, context?: string, writingArea?: { w: number, h: number })
    :Promise<{
      ok: boolean,
      msg: string,
      model?: string,
      context?: string,
      writingArea?: { w: number, h: number }
      results: { candidates: string[], scores: number[] },
    }>
 }
 
 export interface XYTOptions {
   x: number[],
   y: number[],
   t?: number[]
 }
 
 export interface ModelOptions {
   model?: string,
   models?: string[]
 }
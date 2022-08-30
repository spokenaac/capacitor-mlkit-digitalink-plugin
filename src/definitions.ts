export interface DigitalInkPlugin {
  /**
   * Initializes notifications on iOS -- NOT supported in Android
   * due to the use of other event listeners
   */
  initializePlugin(): Promise<{ ok: boolean, msg: string }>

  /**
   * Erases natively stored stroke/point/ink data
   */
  erase(): Promise<{ ok: boolean, msg: string }>

  /**
  * Sends XY coordinate data to native code to be prepared for model inference
  * Can include/exclude time values
  * Ensure all units for coordinates/time are consistent between logs. Unit types don't matter,
  * they just need to be the same -- all values are normalized
  * @param options - [ X coordinate, Y coordinate, T time in milliseconds ]
  */
  logStrokes(options: XYTOptions): Promise<{ ok: boolean, msg: string, options: XYTOptions }>
   
  /**
  * Runs inference either on the provided model via the model param, or on the default English model.
  * All params are optional.
  * @param model singular model to use for inference
  * @param context precontext to provide. Some letters/words may be mistaken for others, use this to disambiguate expected responses.
  * @param writingArea width and height of the drawing area. Only provide for further context--i.e. if writing two lines of text.
  */
  doRecognition(options: RecognitionOptions)
  :Promise<{
    ok: boolean,
    msg: string,
    results: { candidates: string[], scores: number[] },
    options: RecognitionOptions,
  }>

  /**
  * Downloads singular model.
  * Last callback has the 'done' property set to true, and signals the last callback.
  * @param model model to download. Native code checks if model is valid and if it's already downloaded.
  * @param callback callback function that runs each time data is sent from the native code.
  */
  downloadSingularModel(model: Model, callback: SingularModelCallback): Promise<CallbackID>;
  
  /**
   * Downloads multiple models from a given array.
   * Callback function will return a response or an error dependent on whether a given model has
   * already been downloaded, is a valid/invalid model, or is finished being downloaded.
   * The last model will be have the 'done' property set to true and signals the last callback.
   * @param models array of models to download.
   * @param callback callback that runs each time data is sent from the native code.
   */
  downloadMultipleModels(models: Models, callback: MultipleModelCallback): Promise<CallbackID>;

  /**
   * Deletes a singular/collection of models downloaded to the device, or all models.
   * @param options delete all models, a singular model, or an array of models.
   */
  deleteModel(options: DeleteModelOptions, callback: DeleteModelCallback): Promise<CallbackID>

  getDownloadedModels(): Promise<{ok: true, msg: string, models: string[]}>
}
 
 export interface XYTOptions {
   x: number[],
   y: number[],
   t?: number[]
 }
 
export interface DeleteModelOptions {
  all?: boolean;
  model?: string;
  models?: string[];
}

export interface RecognitionOptions {
  model?: string,
  context?: string,
  writingArea: {
    w: number,
    h: number
  }
}

 export interface Model {
   model?: string
 }

 export interface Models {
   models?: string[]
 }

 export interface Response {
   ok: boolean,
   done: boolean,
   msg: string
 }

 export type SingularModelCallback = (response: Response, error?: any) => void;

 export type MultipleModelCallback = (response: Response, error?: any) => void;

 export type DeleteModelCallback = (response: Response, error?: any) => void;

 export type CallbackID = string;

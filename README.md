# capacitor-digitalink

Allows use of Google's MLKit DigitalInk models

## Install

```bash
npm install capacitor-digitalink
npx cap sync
```

## QA Check
### :white_check_mark:  = passed
### :x: = fix needed

### Android
* downloadModel()
  * download a model
    * verify error thrown if incorrect model :white_check_mark:
    * verify non-error response notifying that model is already downloaded :white_check_mark:
    * verify non-error if model is not already downloaded :white_check_mark:
  * download an array of models
    * verify non-error if models are already downloaded :white_check_mark:  = passed
    * verify non-error if some models are downloaded, and some need to be downloaded :white_check_mark:  = passed
    * verify non-error if no models are downloaded yet :white_check_mark:  = passed
    * verify non-error if all models are already downloaded :white_check_mark:  = passed
    * verify error if one or more models are incorrect models :x: = fix needed
* logStrokes() :x: = fix needed
  * verify error if we send non-numerical coordinate data for x, y, or t
  * verify error if we send any kind of number for t
  * verify non-error if we send any kind of number for x or y
  * verify non-error if we send time along with x and y
  * verify success response sent to client
  * draw a bunch of things and see if it breaks?
* erase()
  * mess around with drawing/erasing/drawing/erasing, see if it can break with any certain combination :white_check_mark:  = passed
  * verify non-error response :white_check_mark:  = passed
* deleteModel()
  * (will finish this code 9/7)
  * Delete singular model
  * Delete array of models
  * Delete all models
 * doRecognition()
   * specify custom model to use for recognition
     * verify errors are thrown if we input an incorrect model
     * verify errors are thrown if model isn't already downloaded

### IOS
* downloadModel()
  * download a model
    * verify error thrown if incorrect model
    * verify non-error response notifying that model is already downloaded 
    * verify non-error if model is not already downloaded
  * download an array of models
    * verify non-error if models are already downloaded
    * verify non-error if some models are downloaded, and some need to be downloaded
    * verify non-error if no models are downloaded yet
    * verify non-error if all models are already downloaded
    * verify error if one or more models are incorrect models
* logStrokes()
  * verify error if we send non-numerical coordinate data for x, y, or t
  * verify error if we send any kind of number for t
  * verify non-error if we send any kind of number for x or y
  * verify non-error if we send time along with x and y
  * verify success response sent to client
  * draw a bunch of things and see if it breaks?
* erase()
  * mess around with drawing/erasing/drawing/erasing, see if it can break with any certain combination
  * verify non-error response
* deleteModel()
  * (will finish this code 9/7)
  * Delete singular model
  * Delete array of models
  * Delete all models
 * doRecognition()
   * specify custom model to use for recognition
     * verify errors are thrown if we input an incorrect model
     * verify errors are thrown if model isn't already downloaded

## API

<docgen-index>

* [`initializeNotifications()`](#initializenotifications)
* [`erase()`](#erase)
* [`logStrokes(...)`](#logstrokes)
* [`doRecognition(...)`](#dorecognition)
* [`downloadSingularModel(...)`](#downloadsingularmodel)
* [`downloadMultipleModels(...)`](#downloadmultiplemodels)
* [`deleteModel(...)`](#deletemodel)
* [Interfaces](#interfaces)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### initializeNotifications()

```typescript
initializeNotifications() => any
```

Initializes notifications on iOS -- NOT supported in Android
due to the use of other event listeners

**Returns:** <code>any</code>

--------------------


### erase()

```typescript
erase() => any
```

Erases natively stored stroke/point/ink data

**Returns:** <code>any</code>

--------------------


### logStrokes(...)

```typescript
logStrokes(options: XYTOptions) => any
```

Sends XY coordinate data to native code to be prepared for model inference
Can include/exclude time values

Ensure all units for coordinates/time are consistent between logs. Unit types don't matter,
they just need to be the same -- all values are normalized

| Param         | Type                                              | Description                                              |
| ------------- | ------------------------------------------------- | -------------------------------------------------------- |
| **`options`** | <code><a href="#xytoptions">XYTOptions</a></code> | - [ X coordinate, Y coordinate, T time in milliseconds ] |

**Returns:** <code>any</code>

--------------------


### doRecognition(...)

```typescript
doRecognition(options: RecognitionOptions) => any
```

Runs inference either on the provided model via the model param, or on the default English model.
All params are optional.

| Param         | Type                                                              |
| ------------- | ----------------------------------------------------------------- |
| **`options`** | <code><a href="#recognitionoptions">RecognitionOptions</a></code> |

**Returns:** <code>any</code>

--------------------


### downloadSingularModel(...)

```typescript
downloadSingularModel(model: Model, callback: SingularModelCallback) => any
```

Downloads singular model.

Last callback has the 'done' property set to true, and signals the last callback.

| Param          | Type                                                      | Description                                                                             |
| -------------- | --------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| **`model`**    | <code><a href="#model">Model</a></code>                   | model to download. Native code checks if model is valid and if it's already downloaded. |
| **`callback`** | <code>(response: Response, error?: any) =&gt; void</code> | callback function that runs each time data is sent from the native code.                |

**Returns:** <code>any</code>

--------------------


### downloadMultipleModels(...)

```typescript
downloadMultipleModels(models: Models, callback: MultipleModelCallback) => any
```

Downloads multiple models from a given array.
Callback function will return a response or an error dependent on whether a given model has
already been downloaded, is a valid/invalid model, or is finished being downloaded.

The last model will be have the 'done' property set to true and signals the last callback.

| Param          | Type                                                      | Description                                                     |
| -------------- | --------------------------------------------------------- | --------------------------------------------------------------- |
| **`models`**   | <code><a href="#models">Models</a></code>                 | array of models to download.                                    |
| **`callback`** | <code>(response: Response, error?: any) =&gt; void</code> | callback that runs each time data is sent from the native code. |

**Returns:** <code>any</code>

--------------------


### deleteModel(...)

```typescript
deleteModel(options: DeleteModelOptions, callback: DeleteModelCallback) => any
```

Deletes a singular/collection of models downloaded to the device, or all models.

Delete ALL not supported in iOS due to Swift ModelManager limitations.

| Param          | Type                                                              | Description                                                 |
| -------------- | ----------------------------------------------------------------- | ----------------------------------------------------------- |
| **`options`**  | <code><a href="#deletemodeloptions">DeleteModelOptions</a></code> | delete all models, a singular model, or an array of models. |
| **`callback`** | <code>(response: Response, error?: any) =&gt; void</code>         |                                                             |

**Returns:** <code>any</code>

--------------------


### Interfaces


#### XYTOptions

| Prop    | Type            |
| ------- | --------------- |
| **`x`** | <code>{}</code> |
| **`y`** | <code>{}</code> |
| **`t`** | <code>{}</code> |


#### RecognitionOptions

| Prop              | Type                                   |
| ----------------- | -------------------------------------- |
| **`model`**       | <code>string</code>                    |
| **`context`**     | <code>string</code>                    |
| **`writingArea`** | <code>{ w: number; h: number; }</code> |


#### Model

| Prop        | Type                |
| ----------- | ------------------- |
| **`model`** | <code>string</code> |


#### Models

| Prop         | Type            |
| ------------ | --------------- |
| **`models`** | <code>{}</code> |


#### DeleteModelOptions

| Prop         | Type                 |
| ------------ | -------------------- |
| **`all`**    | <code>boolean</code> |
| **`model`**  | <code>string</code>  |
| **`models`** | <code>{}</code>      |

</docgen-api>

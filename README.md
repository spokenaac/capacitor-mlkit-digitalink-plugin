# capacitor-digitalink

Allows use of Google's MLKit DigitalInk models

## Install

```bash
npm install capacitor-digitalink
npx cap sync
```

## QA Check
### Android
* downloadModel()
  * download a random model
    * verify error thrown if incorrect model
    * verify non-error response notifying that model is already downloaded 
    * verify non-error if model is already downloaded
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

### IOS
* downloadModel()
  * download a random model
    * verify error thrown if incorrect model
    * verify non-error response notifying that model is already downloaded 
    * verify non-error if model is already downloaded
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

* [`erase()`](#erase)
* [`logStrokes(...)`](#logstrokes)
* [`deleteModel(...)`](#deletemodel)
* [`downloadModel(...)`](#downloadmodel)
* [`doRecognition(...)`](#dorecognition)
* [Interfaces](#interfaces)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

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


### deleteModel(...)

```typescript
deleteModel(all?: boolean | undefined, options?: ModelOptions | undefined) => any
```

Deletes a singular/collection of models downloaded to the device, or all models.

| Param         | Type                                                  | Description                  |
| ------------- | ----------------------------------------------------- | ---------------------------- |
| **`all`**     | <code>boolean</code>                                  | deletes all models on device |
| **`options`** | <code><a href="#modeloptions">ModelOptions</a></code> |                              |

**Returns:** <code>any</code>

--------------------


### downloadModel(...)

```typescript
downloadModel(options?: ModelOptions | undefined) => any
```

Downloads a singular/collection of models downloaded to the device, or all models.

| Param         | Type                                                  |
| ------------- | ----------------------------------------------------- |
| **`options`** | <code><a href="#modeloptions">ModelOptions</a></code> |

**Returns:** <code>any</code>

--------------------


### doRecognition(...)

```typescript
doRecognition(model?: string | undefined, context?: string | undefined, writingArea?: { w: number; h: number; } | undefined) => any
```

Runs inference either on the provided model via the model param, or on the default English model.
All params are optional.

| Param             | Type                                   | Description                                                                                                        |
| ----------------- | -------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| **`model`**       | <code>string</code>                    | singular model to use for inference                                                                                |
| **`context`**     | <code>string</code>                    | precontext to provide. Some letters/words may be mistaken for others, use this to disambiguate expected responses. |
| **`writingArea`** | <code>{ w: number; h: number; }</code> | width and height of the drawing area. Only provide for further context--i.e. if writing two lines of text.         |

**Returns:** <code>any</code>

--------------------


### Interfaces


#### XYTOptions

| Prop    | Type            |
| ------- | --------------- |
| **`x`** | <code>{}</code> |
| **`y`** | <code>{}</code> |
| **`t`** | <code>{}</code> |


#### ModelOptions

| Prop         | Type                |
| ------------ | ------------------- |
| **`model`**  | <code>string</code> |
| **`models`** | <code>{}</code>     |

</docgen-api>

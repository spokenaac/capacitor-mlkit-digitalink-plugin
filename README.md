# capacitor-digitalink

Allows use of Google's MLKit DigitalInk models

You must provide a set of coordinates with or without time values to properly use this plugin. There are various implementations out there, but the most common way to accomplish this is by using a Canvas, moving the Canvas Context to draw with pixels, then sending the data over to the plugin.

For example, the picture at predrawn-inks/hi/hi.png:

![](/predrawn-inks/hi/hi.png)

Would have this data:
```javascript
// predrawn-inks/hi/hi.json
[]
[]
[]
```

Again, the time values are optional.

Once the data has been sent to the plugin, call the doRecognition method to perform recognition. See the API docs below for details on params, returns, etc.

## Install

```bash
npm install capacitor-digitalink
npx cap sync
```

## Todos / Notes
* Provide functionality for finding LocalModel (en-US) as a default model, and don't allow en-US as a param in deleting models?

## QA Check - check Asana

## API

<docgen-index>

* [`initializePlugin()`](#initializeplugin)
* [`erase()`](#erase)
* [`logStrokes(...)`](#logstrokes)
* [`doRecognition(...)`](#dorecognition)
* [`downloadSingularModel(...)`](#downloadsingularmodel)
* [`downloadMultipleModels(...)`](#downloadmultiplemodels)
* [`deleteModel(...)`](#deletemodel)
* [`getDownloadedModels()`](#getdownloadedmodels)
* [Interfaces](#interfaces)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### initializePlugin()

```typescript
initializePlugin() => any
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

| Param          | Type                                                              | Description                                                 |
| -------------- | ----------------------------------------------------------------- | ----------------------------------------------------------- |
| **`options`**  | <code><a href="#deletemodeloptions">DeleteModelOptions</a></code> | delete all models, a singular model, or an array of models. |
| **`callback`** | <code>(response: Response, error?: any) =&gt; void</code>         |                                                             |

**Returns:** <code>any</code>

--------------------


### getDownloadedModels()

```typescript
getDownloadedModels() => any
```

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

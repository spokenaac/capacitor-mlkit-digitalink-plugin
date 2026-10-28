# capacitor-mlkit-digitalink-plugin

Capacitor plugin for use of the Google MLKit Digital Ink Recognition models.

## Install

```bash
npm install capacitor-mlkit-digitalink-plugin
npx cap sync
```

## Requirements

- Android now bundles `com.google.mlkit:digital-ink-recognition:19.0.0`, which adds Android 15 (16 KB page size) support.
- iOS requires Xcode 16+, an iOS deployment target of 15.5 or newer, and CocoaPods.

### iOS simulator support (0.5.0+)

The npm package includes static XCFrameworks for physical iOS devices (`arm64`)
and simulators (`arm64` and `x86_64`). The JavaScript API and the upstream ML Kit
versions are unchanged: GoogleMLKit 9.0.0 / MLKitDigitalInkRecognition 8.0.0,
MLKitCommon 14.0.0, and MLKitMDD 10.0.0.

Google does not provide an official arm64 simulator build of these frameworks.
The simulator variant is generated from Google's arm64 device code by changing
its Mach-O platform metadata, using the compatibility approach described by
[google-mlkit-swiftpm](https://github.com/d-date/google-mlkit-swiftpm/issues/112).
This is an unofficial compatibility build and should be tested with the model
and simulator you use. Device code is preserved. Google notices, Digital Ink
resources, and privacy manifests are included.

After upgrading:

1. Remove `arm64` from **Excluded Architectures → Any iOS Simulator SDK** in your
   app's Debug and Release configurations.
2. Remove any Podfile hook that excludes `arm64` from simulator Pod builds.
3. Run `npx cap sync ios`, clean the Xcode build folder, and select an iOS
   simulator compatible with your app's deployment target.

The plugin vendors the three ML Kit frameworks instead of depending on their
original binary pods. Do not also add `GoogleMLKit/DigitalInkRecognition`,
`MLKitDigitalInkRecognition`, `MLKitCommon`, or `MLKitMDD` to the same target:
that would link duplicate copies. Other ML Kit plugins that pull in those pods
need a shared packaging solution before they can be combined with this version.

### Building the iOS package from source

On a Mac with Xcode command-line tools, Node.js, Ruby, and CocoaPods:

```bash
npm install
npm run prepare:ios
npm run test:ios:packaging
npm run verify:ios
npm run verify:ios:simulator -- -destination 'platform=iOS Simulator,id=YOUR_SIMULATOR_UDID'
npm pack
```

`prepare:ios` downloads only the pinned Google archives in
`scripts/mlkit-binaries.json`, verifies their SHA-256 checksums, and generates
`ios/Frameworks`, `ios/Resources`, and `ios/Notices`. Downloads are cached in
`.cache/mlkit`. Generated assets are ignored by Git and included in the npm
package; `prepack` regenerates them for both `npm pack` and `npm publish`.
Run `prepare:ios` before using a Git checkout as a local Capacitor dependency.

The simulator integration test downloads the English model if necessary and
runs recognition on sample strokes. Its first run requires internet access.

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
* [Type Aliases](#type-aliases)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### initializePlugin()

```typescript
initializePlugin() => Promise<{ ok: boolean; msg: string; }>
```

Initializes notifications on iOS -- NOT supported in Android
due to the use of other event listeners

**Returns:** <code>Promise&lt;{ ok: boolean; msg: string; }&gt;</code>

--------------------


### erase()

```typescript
erase() => Promise<{ ok: boolean; msg: string; }>
```

Erases natively stored stroke/point/ink data

**Returns:** <code>Promise&lt;{ ok: boolean; msg: string; }&gt;</code>

--------------------


### logStrokes(...)

```typescript
logStrokes(options: XYTOptions) => Promise<{ ok: boolean; msg: string; options: XYTOptions; }>
```

Sends XY coordinate data to native code to be prepared for model inference
Can include/exclude time values
Ensure all units for coordinates/time are consistent between logs. Unit types don't matter,
they just need to be the same -- all values are normalized

| Param         | Type                                              | Description                                              |
| ------------- | ------------------------------------------------- | -------------------------------------------------------- |
| **`options`** | <code><a href="#xytoptions">XYTOptions</a></code> | - [ X coordinate, Y coordinate, T time in milliseconds ] |

**Returns:** <code>Promise&lt;{ ok: boolean; msg: string; options: <a href="#xytoptions">XYTOptions</a>; }&gt;</code>

--------------------


### doRecognition(...)

```typescript
doRecognition(options: RecognitionOptions) => Promise<{ ok: boolean; msg: string; results: { candidates: string[]; scores: number[]; }; options: RecognitionOptions; }>
```

Runs inference either on the provided model via the model param, or on the default English model.
All params are optional.

| Param         | Type                                                              |
| ------------- | ----------------------------------------------------------------- |
| **`options`** | <code><a href="#recognitionoptions">RecognitionOptions</a></code> |

**Returns:** <code>Promise&lt;{ ok: boolean; msg: string; results: { candidates: string[]; scores: number[]; }; options: <a href="#recognitionoptions">RecognitionOptions</a>; }&gt;</code>

--------------------


### downloadSingularModel(...)

```typescript
downloadSingularModel(model: Model, callback: SingularModelCallback) => Promise<CallbackID>
```

Downloads singular model.
Last callback has the 'done' property set to true, and signals the last callback.

| Param          | Type                                                                    | Description                                                                             |
| -------------- | ----------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| **`model`**    | <code><a href="#model">Model</a></code>                                 | model to download. Native code checks if model is valid and if it's already downloaded. |
| **`callback`** | <code><a href="#singularmodelcallback">SingularModelCallback</a></code> | callback function that runs each time data is sent from the native code.                |

**Returns:** <code>Promise&lt;string&gt;</code>

--------------------


### downloadMultipleModels(...)

```typescript
downloadMultipleModels(models: Models, callback: MultipleModelCallback) => Promise<CallbackID>
```

Downloads multiple models from a given array.
Callback function will return a response or an error dependent on whether a given model has
already been downloaded, is a valid/invalid model, or is finished being downloaded.
The last model will be have the 'done' property set to true and signals the last callback.

| Param          | Type                                                                    | Description                                                     |
| -------------- | ----------------------------------------------------------------------- | --------------------------------------------------------------- |
| **`models`**   | <code><a href="#models">Models</a></code>                               | array of models to download.                                    |
| **`callback`** | <code><a href="#multiplemodelcallback">MultipleModelCallback</a></code> | callback that runs each time data is sent from the native code. |

**Returns:** <code>Promise&lt;string&gt;</code>

--------------------


### deleteModel(...)

```typescript
deleteModel(options: DeleteModelOptions, callback: DeleteModelCallback) => Promise<CallbackID>
```

Deletes a singular/collection of models downloaded to the device, or all models.

| Param          | Type                                                                | Description                                                 |
| -------------- | ------------------------------------------------------------------- | ----------------------------------------------------------- |
| **`options`**  | <code><a href="#deletemodeloptions">DeleteModelOptions</a></code>   | delete all models, a singular model, or an array of models. |
| **`callback`** | <code><a href="#deletemodelcallback">DeleteModelCallback</a></code> |                                                             |

**Returns:** <code>Promise&lt;string&gt;</code>

--------------------


### getDownloadedModels()

```typescript
getDownloadedModels() => Promise<{ ok: true; msg: string; models: string[]; }>
```

**Returns:** <code>Promise&lt;{ ok: true; msg: string; models: string[]; }&gt;</code>

--------------------


### Interfaces


#### XYTOptions

| Prop    | Type                  |
| ------- | --------------------- |
| **`x`** | <code>number[]</code> |
| **`y`** | <code>number[]</code> |
| **`t`** | <code>number[]</code> |


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


#### Response

| Prop       | Type                 |
| ---------- | -------------------- |
| **`ok`**   | <code>boolean</code> |
| **`done`** | <code>boolean</code> |
| **`msg`**  | <code>string</code>  |


#### Models

| Prop         | Type                  |
| ------------ | --------------------- |
| **`models`** | <code>string[]</code> |


#### DeleteModelOptions

| Prop         | Type                  |
| ------------ | --------------------- |
| **`all`**    | <code>boolean</code>  |
| **`model`**  | <code>string</code>   |
| **`models`** | <code>string[]</code> |


### Type Aliases


#### SingularModelCallback

<code>(response: <a href="#response">Response</a>, error?: any): void</code>


#### CallbackID

<code>string</code>


#### MultipleModelCallback

<code>(response: <a href="#response">Response</a>, error?: any): void</code>


#### DeleteModelCallback

<code>(response: <a href="#response">Response</a>, error?: any): void</code>

</docgen-api>

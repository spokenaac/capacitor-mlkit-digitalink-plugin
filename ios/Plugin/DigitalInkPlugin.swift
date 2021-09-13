import Foundation
import MLKitDigitalInkRecognition
import Capacitor

@objc(DigitalInkPlugin)
public class DigitalInkPlugin: CAPPlugin {
    // global strokes + points variables will store point/stroke data for future recognition
    var strokes: [Stroke] = []
    var points: [StrokePoint] = []
    var listOfDownloadedModels: [DigitalInkRecognitionModel] = []
    
    // we instantiate our model default to 'en-US'
    var defaultIdentifier: DigitalInkRecognitionModelIdentifier = DigitalInkRecognitionModelIdentifier(forLanguageTag: "en-US")!
    lazy var model: DigitalInkRecognitionModel = DigitalInkRecognitionModel(modelIdentifier: defaultIdentifier)
    lazy var options: DigitalInkRecognizerOptions = DigitalInkRecognizerOptions(model: model)
    lazy var recognizer: DigitalInkRecognizer = DigitalInkRecognizer.digitalInkRecognizer(options: options)
    
    // instantiate the model manager
    var remoteModelManager: ModelManager = ModelManager.modelManager()

    // TODO: possibly seeing bug where download only works on wifi even though cellaccess is set?
    var conditions: ModelDownloadConditions = ModelDownloadConditions.init(allowsCellularAccess: true, allowsBackgroundDownloading: true)
    
    // callback ID used to access a saved call later
    var callID: String = ""

    @objc func initializePlugin(_ call: CAPPluginCall) {
        // Android/Java has onComplete/onFailure listeners you call immediately after the Task
        // in Swift, we must init some notification listeners that are emitted by the ModelManager given certain conditions
        // NOTE: these are not device push notifications, etc., just events

        // add observer for successful model download
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.mlkitModelDownloadDidSucceed,
            object: nil,
            queue: OperationQueue.main,
            using: {
            [unowned self]
            (notification) in
                // access saved call from earlier when downloads were called
                let savedCall: CAPPluginCall = (bridge?.savedCall(withID: callID))!

                let downloadedModel: DigitalInkRecognitionModel = notification.userInfo![ModelDownloadUserInfoKey.remoteModel.rawValue] as! DigitalInkRecognitionModel
                let langTag: String = downloadedModel.modelIdentifier.languageTag
                savedCall.resolve(["ok": true, "msg": langTag + " model successfully downloaded."])
          })
        
        // add observer for failure to download model
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.mlkitModelDownloadDidFail,
            object: nil,
            queue: OperationQueue.main,
            using: {
            [unowned self]
            (notification) in
                // access saved call from earlier when downloads were called
                let savedCall: CAPPluginCall = (bridge?.savedCall(withID: callID))!

                let downloadedModel: DigitalInkRecognitionModel = notification.userInfo![ModelDownloadUserInfoKey.remoteModel.rawValue] as! DigitalInkRecognitionModel
                let langTag: String = downloadedModel.modelIdentifier.languageTag
                savedCall.resolve(["ok": true, "msg": langTag + " model successfully downloaded."])
        })
        
        call.resolve(["ok": true, "msg": "Plugin initialized."])
    }
    
    @objc func setDownloadedModels() {
        // Set listOfDownloadedModels to accurately reflect all models downloaded
        let listOfIds = DigitalInkRecognitionModelIdentifier.allModelIdentifiers()
        
        // reset list of downloaded models
        listOfDownloadedModels = []
        
        for id in listOfIds {
            // run each id through the model instantiator
            let iteratedModel: DigitalInkRecognitionModel = DigitalInkRecognitionModel.init(modelIdentifier: id)
            
            if (remoteModelManager.isModelDownloaded(iteratedModel)) {
                // the given id/model is downloaded
                listOfDownloadedModels.append(iteratedModel)
            }
        }
    }
    
    @objc func downloadSingularModel(_ call: CAPPluginCall) {
        // keep call alive so we can resolve() multiple times
        call.keepAlive = true
        
        // save callbackID for future use in the notification center
        callID = call.callbackId
        
        // get singular model specified from client
        if let langTag = call.getString("model") {
            // create new model from identifier if language tag is legit
            if let newIdentifier = DigitalInkRecognitionModelIdentifier(forLanguageTag: langTag) {
                let newModel: DigitalInkRecognitionModel = DigitalInkRecognitionModel.init(modelIdentifier: newIdentifier)
                
                // notifies client that model is being checked/downloaded
                call.resolve(["ok": true, "msg": "Processing singular model " + langTag + "..."])
                
                if remoteModelManager.isModelDownloaded(model) {
                    // if it is already downloaded, return final call notifying client
                    call.resolve(["ok": true, "msg": langTag + " model is already downloaded."])
                }
                else {
                    // model is not already downloaded, so download it
                    remoteModelManager.download(newModel, conditions: conditions)
                }
            }
            else {
                // incorrect model tag was given
                call.reject(call.getString("model")! + " model is not a valid model identifier")
            }
        }
        else {
            // no model was provided
            call.reject("No params given, no models downloaded.")
        }
    }
    
    @objc func downloadMultipleModels(_ call: CAPPluginCall) {
        // keep call alive so we can resolve() multiple times
        call.keepAlive = true
        
        // save callbackID for future use in the notification center
        callID = call.callbackId
        
        // get singular model specified from client
        if let langTags = call.getArray("models") {
            // notifies client that model is being checked/downloaded
            call.resolve(["ok": true, "msg": "Processing models..."])
            
            for langTagJSValue in langTags {
                let langTag: String = langTagJSValue as! String
                
                // create new model from identifier if language tag is legit
                if let newIdentifier = DigitalInkRecognitionModelIdentifier(forLanguageTag: langTag) {
                    model = DigitalInkRecognitionModel.init(modelIdentifier: newIdentifier)
                    
                    if remoteModelManager.isModelDownloaded(model) {
                        // model is already downloaded
                        call.resolve(["ok": true, "msg": langTag + " model is already downloaded."])
                    }
                    else {
                        // model is not already downloaded, so download it
                        // model download confirmation is handled in notification center
                        remoteModelManager.download(model, conditions: conditions)
                    }
                }
                else {
                    // incorrect model tag was given
                    call.reject(langTag + " model is not a valid model identifier")
                }
            }
            
            call.resolve(["ok": true, "msg": "Models provided are downloading."])
        }
        else {
            // no models were provided
            call.reject("No params given, no models downloaded.")
        }
    }
    
    @objc func deleteModel(_ call: CAPPluginCall) {
        // we need to return multiple messages to client
        call.keepAlive = true
        
        // set the array of all currently downloaded models
        setDownloadedModels()
        
        // we were sent a singular model to delete
        if let langTag = call.getString("model") {
            if let checkingID: DigitalInkRecognitionModelIdentifier = DigitalInkRecognitionModelIdentifier(forLanguageTag: langTag) {
                // given identifier is legit
                let checkingModel: DigitalInkRecognitionModel = DigitalInkRecognitionModel.init(modelIdentifier: checkingID)
                
                if listOfDownloadedModels.contains(checkingModel) {
                    // delete the model
                    remoteModelManager.deleteDownloadedModel(checkingModel, completion: {
                        (error: Error?) in
                        if error == nil {
                            call.resolve(["ok": true, "msg": langTag + " model successfully deleted."])
                            call.keepAlive = false // kill the call
                        } else {
                            call.reject("Could not delete " + langTag + " model: " + error.debugDescription)
                            call.keepAlive = false // kill the call
                        }
                    })
                } else {
                    call.reject(langTag + " model is not downloaded.")
                    call.keepAlive = false // kill the call
                }
            } else {
                call.reject(langTag + " is not a valid model identifier.")
                call.keepAlive = false // kill the call
            }
        }
        // we were sent an array of models to delete
        else if let langTags = call.getArray("models") {
            for langTagJSValue in langTags {
                let langTag: String = langTagJSValue as! String
                
                if let checkingID: DigitalInkRecognitionModelIdentifier = DigitalInkRecognitionModelIdentifier(forLanguageTag: langTag) {
                    // given identifier is legit
                    let checkingModel: DigitalInkRecognitionModel = DigitalInkRecognitionModel.init(modelIdentifier: checkingID)
                    
                    if listOfDownloadedModels.contains(checkingModel) {
                        // delete the model
                        remoteModelManager.deleteDownloadedModel(checkingModel, completion: {
                            (error: Error?) in
                            if error == nil {
                                call.resolve(["ok": true, "msg": langTag + " model successfully deleted."])
                            }
                            else { call.reject("Could not delete " + langTag + " model: " + error.debugDescription) }
                        })
                    } else { call.reject(langTag + " model is not downloaded.") }
                } else { call.reject(langTag + " is not a valid model identifier.") }
            }
            
            call.resolve(["ok": true, "msg": "All models provided have been deleted."])
            usleep(100000) // wait for 100ms to kill the call, ensure everything is deleted
            call.keepAlive = false
        }
        else if call.getBool("all") ?? false {
            if listOfDownloadedModels.count > 0 {
                // if we have any models downloaded
                for model in listOfDownloadedModels {
                    // delete every model in the list
                    remoteModelManager.deleteDownloadedModel(model) {
                        (error: Error?) in
                        if error == nil {
                            call.resolve(["ok": true, "msg": model.modelIdentifier.languageTag + " model successfully deleted"])
                        }
                        else {
                            call.reject("Could not delete " + model.modelIdentifier.languageTag + " model: " + error.debugDescription)
                        }
                    }
                }
                
                call.resolve(["ok": true, "msg": "All models deleted."])
                usleep(100000) // wait for 100ms to kill the call, ensure everything is deleted
                call.keepAlive = false
            }
            else {
                call.reject("No models are currently downloaded.")
            }
        }
        else {
            call.reject("No params were given, no models deleted.")
        }
    }

    @objc func logStrokes(_ call: CAPPluginCall) {
        let xArr: [NSNumber] = call.options["x"] as! [NSNumber]
        let yArr: [NSNumber] = call.options["y"] as! [NSNumber]

        if let tArr: [NSNumber] = call.options["t"] as? [NSNumber] {
            for (index, _) in xArr.enumerated() {
                let x = Float(truncating: xArr[index])
                let y = Float(truncating: yArr[index])
                let t = Int(truncating: tArr[index])
                
                let point: StrokePoint = StrokePoint.init(x: x, y: y, t: t)
                points.append(point)
            }
            strokes.append(Stroke.init(points: self.points))
            points = []
            
            call.resolve(["ok": true, "msg": "(with time values) stroke added"])
        }
        else {
            for (index, _) in xArr.enumerated() {
                let x = Float(truncating: xArr[index])
                let y = Float(truncating: yArr[index])
                
                let point: StrokePoint = StrokePoint.init(x: x, y: y)
                points.append(point)
            }
            strokes.append(Stroke.init(points: self.points))
            points = []
            
            call.resolve(["ok": true, "msg": "(without time values) stroke added"])
        }
    }
    
    @objc func erase(_ call: CAPPluginCall) {
        // erase stroke/point data
        points = []
        strokes = []
        
        call.resolve(["ok": true, "msg": "Erased stored stroke and point data."])
    }

    @objc func doRecognition(_ call: CAPPluginCall) {
        let ink = Ink.init(strokes: strokes)
        var candidateText: [String] = []
        var candidateScore: [NSNumber] = []
        
        let context: JSArray? = call.getArray("context")
        var recognizerContext: DigitalInkRecognitionContext = DigitalInkRecognitionContext.init(preContext: "", writingArea: WritingArea.init(width: 0, height: 0))
        
        if context != nil {
            let contextText: String = context![0] as! String
            let contextArr: [NSNumber] = context![1] as! [NSNumber]
            let contextDimensions: WritingArea = WritingArea.init(width: Float(truncating: contextArr[0]), height: Float(truncating: contextArr[1]))
            
            recognizerContext = DigitalInkRecognitionContext.init(preContext: contextText, writingArea: contextDimensions)
        }

        if let langTag = call.getString("model") {
            if let newIdentifier = DigitalInkRecognitionModelIdentifier.init(forLanguageTag: langTag) {
                // the identifier tag specified is legit, redefine the model to use this tag
                model = DigitalInkRecognitionModel.init(modelIdentifier: newIdentifier)
                
                if remoteModelManager.isModelDownloaded(model) {
                    // the specified model is downloaded, redefine the recognizer to use this model
                    options = DigitalInkRecognizerOptions.init(model: model)
                    recognizer = DigitalInkRecognizer.digitalInkRecognizer(options: options)

                    recognizer.recognize(
                        ink: ink,
                        context: recognizerContext,
                        completion: {
                            (result: DigitalInkRecognitionResult?, error: Error?) in
                            if let result = result {
                                for candidate in result.candidates {
                                    candidateText.append(candidate.text)
                                    candidateScore.append(candidate.score ?? 0)
                                }
                                
                                call.resolve([
                                    "ok": true,
                                    //"context": preContext,
                                    //"writingArea": writingArea,
                                    "msg": "Recognized successfully",
                                    "results": [
                                        "candidates": candidateText,
                                        "scores": candidateScore
                                    ]
                                ])
                            } else {
                                call.reject(error.debugDescription)
                            }
                        }
                    )
                } else {
                    // the specified model is not downloaded
                    call.reject(langTag + " model is not downloaded.")
                }
            } else {
                call.reject(call.getString("model")! + " model is not a usable model.")
            }
        }
        else {
            // we didn't receive a model, use the default -- ensure it's downloaded first
            model = DigitalInkRecognitionModel.init(modelIdentifier: defaultIdentifier)
            
            if remoteModelManager.isModelDownloaded(model) {
                // it is downloaded -- set recognizer and recognize
                options = DigitalInkRecognizerOptions.init(model: model)
                recognizer = DigitalInkRecognizer.digitalInkRecognizer(options: options)
                
                recognizer.recognize(
                    ink: ink,
                    context: recognizerContext,
                    completion: {
                        (result: DigitalInkRecognitionResult?, error: Error?) in
                        if let result = result {
                            for candidate in result.candidates {
                                candidateText.append(candidate.text)
                                candidateScore.append(candidate.score ?? 0)
                            }
                            
                            call.resolve([
                                "ok": true,
                                //"context": preContext,
                                //"writingArea": writingArea,
                                "msg": "Recognized successfully",
                                "results": [
                                    "candidates": candidateText,
                                    "scores": candidateScore
                                ]
                            ])
                        } else {
                            call.reject(error.debugDescription)
                        }
                    }
                )
            } else {
                call.reject("default " + defaultIdentifier.languageTag + " model is not downloaded.")
            }
        }
    }
}

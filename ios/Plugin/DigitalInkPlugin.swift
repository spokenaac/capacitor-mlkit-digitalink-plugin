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
    lazy var defaultModel: DigitalInkRecognitionModel = DigitalInkRecognitionModel(modelIdentifier: defaultIdentifier)
    lazy var options: DigitalInkRecognizerOptions = DigitalInkRecognizerOptions(model: defaultModel)
    lazy var recognizer: DigitalInkRecognizer = DigitalInkRecognizer.digitalInkRecognizer(options: options)
    
    // instantiate the model manager
    var remoteModelManager: ModelManager = ModelManager.modelManager()

    // TODO: possibly seeing bug where download only works on wifi even though cellaccess is set?
    var conditions: ModelDownloadConditions = ModelDownloadConditions.init(allowsCellularAccess: true, allowsBackgroundDownloading: true)
    
    // callback ID used to access a saved call later
    var callID: String = ""
    
    // counter to keep track of how many models are downloading so we can understand when the call is finished
    var downloadCount: Int = 0
    
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

    @objc func initializePlugin(_ call: CAPPluginCall) {
        // check/download our default en-US model
        if !remoteModelManager.isModelDownloaded(defaultModel) {
            // it's not downloaded, so download it
            remoteModelManager.download(defaultModel, conditions: conditions)
        }
        
        // Android/Java has onComplete/onFailure listeners you call immediately after the Task
        // in Swift, we must init some notification listeners that are emitted by the ModelManager given certain conditions
        // NOTE: these are not device push notifications, etc., just events
        //
        // add observer for successful model download
       _ = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.mlkitModelDownloadDidSucceed,
            object: nil,
            queue: OperationQueue.main,
            using: {
            [unowned self]
            (notification) in
                // access saved call from earlier when downloads were called
                if let savedCall: CAPPluginCall = (bridge?.savedCall(withID: callID)) {
                    let downloadedModel: DigitalInkRecognitionModel = notification.userInfo![ModelDownloadUserInfoKey.remoteModel.rawValue] as! DigitalInkRecognitionModel
                    let langTag: String = downloadedModel.modelIdentifier.languageTag
                    
                    downloadCount -= 1
                    
                    savedCall.resolve(["ok": true, "done": downloadCount == 0, "msg": langTag + " model successfully downloaded."])
                }
          })

        // add observer for failure to download model
        _ = NotificationCenter.default.addObserver(
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
                
                downloadCount -= 1
                
                savedCall.resolve(["ok": true, "done": downloadCount == 0, "msg": langTag + " model failed to download."])
        })
        
        call.resolve(["ok": true, "msg": "Plugin initialized."])
    }
    
    @objc func erase(_ call: CAPPluginCall) {
        // if we have a saved call, clear it out to avoid overlaps
        if let savedCall: CAPPluginCall = (bridge?.savedCall(withID: callID)) {
            savedCall.keepAlive = false
            savedCall.resolve(["ok": true, "msg": "Cleaned up previously saved call"])
        }
        
        // erase stroke/point data
        points = []
        strokes = []
        
        call.resolve(["ok": true, "msg": "Erased stored stroke and point data."])
    }
    
    @objc func logStrokes(_ call: CAPPluginCall) {
        // if we have a saved call, clear it out to avoid overlaps
        if let savedCall: CAPPluginCall = (bridge?.savedCall(withID: callID)) {
            savedCall.keepAlive = false
            savedCall.resolve(["ok": true, "msg": "Cleaned up previously saved call"])
        }
        
        let xArr: [NSNumber] = call.options["x"] as! [NSNumber]
        let yArr: [NSNumber] = call.options["y"] as! [NSNumber]

        if let tArr: [NSNumber] = call.options["t"] as? [NSNumber] {
            for index in xArr.indices {
                let x = Float(truncating: xArr[index])
                let y = Float(truncating: yArr[index])
                let t = Int(truncating: tArr[index])
                
                let point: StrokePoint = StrokePoint.init(x: x, y: y, t: t)

                points.append(point)
            }

            let newStroke: Stroke = Stroke.init(points: self.points)
            
            strokes.append(newStroke)

            points = []

            call.resolve(["ok": true, "msg": "(with time values) stroke added"])
        } else {
            for index in xArr.indices {
                let x = Float(truncating: xArr[index])
                let y = Float(truncating: yArr[index])

                let point: StrokePoint = StrokePoint.init(x: x, y: y)

                points.append(point)
            }

            let newStroke: Stroke = Stroke.init(points: self.points)

            strokes.append(newStroke)

            points = []

            call.resolve(["ok": true, "msg": "(without time values) stroke added"])
        }
    }
    @objc func recognize(call: CAPPluginCall, newModel: DigitalInkRecognitionModel, ink: Ink, recognizerContext: DigitalInkRecognitionContext) {
        var candidateText: [String] = []
        var candidateScore: [NSNumber] = []

        // the specified model is downloaded, redefine the recognizer to use this model
        options = DigitalInkRecognizerOptions.init(model: newModel)
        recognizer = DigitalInkRecognizer.digitalInkRecognizer(options: options)
        
        for stroke in ink.strokes {
            print("\nStroke: ", stroke)
            
            for p in stroke.points {
                print("\nPoint: ", p.x, p.y, p.t)
            }
        }

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
                    call.reject(error.debugDescription, nil)
                }
            }
        )
    }

    @objc func doRecognition(_ call: CAPPluginCall) {
        // if we have a saved call, clear it out to avoid overlaps
        if let savedCall: CAPPluginCall = (bridge?.savedCall(withID: callID)) {
            savedCall.keepAlive = false
            savedCall.resolve(["ok": true, "msg": "Cleaned up previously saved call"])
        }
        
        // initialize ink class, response variables
        let ink = Ink.init(strokes: strokes)
        
        _ = call.getArray("context")
        
        let writingArea: JSObject? = call.getObject("writingArea")
        
        let writingWidth = (writingArea?["w"] ?? 0) as! Float
        let writingHeight = (writingArea?["h"] ?? 0) as! Float
        
        let recognizerContext: DigitalInkRecognitionContext = DigitalInkRecognitionContext.init(preContext: "", writingArea: WritingArea.init(width: writingWidth, height: writingHeight))
        
        var sentModel: Bool = false
        
        if let check = call.getString("model") {
            sentModel = !check.isEmpty
        }

        if sentModel {
            let langTag = call.getString("model")!
            
            if let newIdentifier = DigitalInkRecognitionModelIdentifier.init(forLanguageTag: langTag) {
                // the identifier tag specified is legit, redefine the model to use this tag
                let newModel = DigitalInkRecognitionModel.init(modelIdentifier: newIdentifier)
                
                if remoteModelManager.isModelDownloaded(newModel) {
                    // the specified model is downloaded, redefine the recognizer to use this model
                    recognize(call: call, newModel: newModel, ink: ink, recognizerContext: recognizerContext)
                } else {
                    // the specified model is not downloaded
                    call.reject(langTag + " model is not downloaded.", nil)
                }
            } else {
                // we were sent an incorrect model
                call.reject(call.getString("model")! + " model is not a usable model.", nil)
            }
        } else {
            // we didn't receive a model, use the default -- ensure it's downloaded first
            if remoteModelManager.isModelDownloaded(defaultModel) {
                // it is downloaded -- set recognizer and recognize
                // options = DigitalInkRecognizerOptions.init(model: defaultModel)
                recognize(call: call, newModel: defaultModel, ink: ink, recognizerContext: recognizerContext)
            } else {
                // the default model isn't downloaded
                call.reject("default " + defaultIdentifier.languageTag + " model is not downloaded.", nil)
            }
        }
    }
    
    @objc func downloadSingularModel(_ call: CAPPluginCall) {
        // if we have a saved call, clear it out to avoid overlaps
        if let savedCall: CAPPluginCall = (bridge?.savedCall(withID: callID)) {
            savedCall.keepAlive = false
            savedCall.resolve(["ok": true, "msg": "Cleaned up previously saved call"])
        }
        
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
                call.resolve(["ok": true, "done": false, "msg": "Processing singular model " + langTag + "..."])
                
                if remoteModelManager.isModelDownloaded(newModel) {
                    // if it is already downloaded, return final call notifying client
                    call.resolve(["ok": true, "done": true, "msg": langTag + " model is already downloaded."])
                    call.keepAlive = false
                } else {
                    // model is not already downloaded, so download it
                    remoteModelManager.download(newModel, conditions: conditions)
                    
                    // +1 download count
                    downloadCount += 1
                    
                    call.resolve(["ok": true, "done": false, "msg": newModel.modelIdentifier.languageTag + " model is downloading."])
                }
            } else {
                // incorrect model tag was given
                call.reject(call.getString("model")! + " model is not a valid model identifier", nil)
                call.keepAlive = false
            }
        } else {
            // no model was provided
            call.reject("No params given, no models downloaded.", nil)
            call.keepAlive = false
        }
    }
    
    @objc func downloadMultipleModels(_ call: CAPPluginCall) {
        // if we have a saved call, clear it out to avoid overlaps
        if let savedCall: CAPPluginCall = (bridge?.savedCall(withID: callID)) {
            savedCall.keepAlive = false
            savedCall.resolve(["ok": true, "msg": "Cleaned up previously saved call"])
        }
        
        // keep call alive so we can resolve() multiple times
        call.keepAlive = true
        
        // save callbackID for future use in the notification center
        callID = call.callbackId
        
        if let langTags = call.getArray("models") {
            // notifies client that model is being checked/downloaded
            call.resolve(["ok": true, "done": false, "msg": "Processing models..."])
            
            for langTagJSValue in langTags {
                let langTag: String = langTagJSValue as! String
                
                // create new model from identifier if language tag is legit
                if let newIdentifier = DigitalInkRecognitionModelIdentifier(forLanguageTag: langTag) {
                    let newModel: DigitalInkRecognitionModel = DigitalInkRecognitionModel.init(modelIdentifier: newIdentifier)
                    
                    if remoteModelManager.isModelDownloaded(newModel) {
                        // model is already downloaded
                        call.resolve(["ok": true, "done": false, "msg": langTag + " model is already downloaded."])
                    } else {
                        // model is not already downloaded, so download it
                        // model download confirmation is handled in notification center
                        remoteModelManager.download(newModel, conditions: conditions)
                        
                        downloadCount += 1
                        
                        call.resolve(["ok": true, "done": false, "msg": newModel.modelIdentifier.languageTag + " model is downloading."])
                    }
                } else {
                    // incorrect model tag was given
                    call.reject(langTag + " model is not a valid model identifier", nil)
                }
            }
            call.resolve(["ok": true, "done": downloadCount == 0, "msg": "Models processed."])
        } else {
            // no models were provided
            call.reject("No params given, no models downloaded.", nil)
            call.keepAlive = false
        }
    }
    
    @objc func deleteModel(_ call: CAPPluginCall) {
        // if we have a saved call, clear it out to avoid overlaps
        if let savedCall: CAPPluginCall = (bridge?.savedCall(withID: callID)) {
            savedCall.keepAlive = false
            savedCall.resolve(["ok": true, "msg": "Cleaned up previously saved call"])
        }
        
        // we need to return multiple messages to client
        call.keepAlive = true
        
        call.resolve(["ok": true, "done": false, "msg": "Deleting models..."])
        
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
                            call.resolve(["ok": true, "done": true, "msg": langTag + " model successfully deleted."])
                            call.keepAlive = false // kill the call
                        } else {
                            call.reject("Could not delete " + langTag + " model: " + error.debugDescription, nil)
                            call.keepAlive = false // kill the call
                        }
                    })
                } else {
                    call.reject(langTag + " model is not downloaded.", nil)
                    call.keepAlive = false // kill the call
                }
            } else {
                call.reject(langTag + " is not a valid model identifier.", nil)
                call.keepAlive = false // kill the call
            }
        } else if let langTags = call.getArray("models") {
            var deleteCounter = langTags.count
            
            // we were sent an array of models to delete
            for langTagJSValue in langTags {
                let langTag: String = langTagJSValue as! String
                
                deleteCounter -= 1
                
                call.keepAlive = !(deleteCounter == 0)

                if let checkingID: DigitalInkRecognitionModelIdentifier = DigitalInkRecognitionModelIdentifier(forLanguageTag: langTag) {
                    // given identifier is legit
                    let checkingModel: DigitalInkRecognitionModel = DigitalInkRecognitionModel.init(modelIdentifier: checkingID)
                    
                    if listOfDownloadedModels.contains(checkingModel) {
                        // delete the model
                        remoteModelManager.deleteDownloadedModel(checkingModel, completion: {
                            (error: Error?) in
                            if error == nil {
                                call.resolve(["ok": true, "done": deleteCounter == 0, "msg": langTag + " model successfully deleted."])
                            } else {
                                call.reject("Could not delete " + langTag + " model: " + error.debugDescription, nil)
                            }
                        })
                    } else {
                        call.reject(langTag + " model is not downloaded.", nil)
                    }
                } else {
                    call.reject(langTag + " is not a valid model identifier.", nil)
                }
            }
            // send response
            call.resolve(["ok": true, "done": false, "msg": "All models provided have been processed."])
        }
        else if call.getBool("all") ?? false {
            call.resolve(["ok": true, "done": false, "msg": "Checking locally downloaded models..."])
            
            if !listOfDownloadedModels.isEmpty {
                var deleteCount = listOfDownloadedModels.count
                
                // if we have any models downloaded
                for modelIter in listOfDownloadedModels {
                    // delete every model in the list
                    remoteModelManager.deleteDownloadedModel(modelIter) {
                        (error: Error?) in
                        if error == nil {
                            deleteCount -= 1
                            call.resolve(["ok": true, "done": deleteCount == 0, "msg": modelIter.modelIdentifier.languageTag + " model successfully deleted"])
                            call.keepAlive = !(deleteCount == 0)
                        } else {
                            call.reject("Could not delete " + modelIter.modelIdentifier.languageTag + " model: " + error.debugDescription, nil)
                        }
                    }
                }
            } else {
                call.reject("No models are currently downloaded.", nil)
                call.keepAlive = false
            }
        } else {
            call.reject("No params were given, no models deleted.", nil)
            call.keepAlive = false
        }
    }
    
    @objc func getDownloadedModels(_ call: CAPPluginCall) {
        // set the downloaded models
        setDownloadedModels()
        
        var modelsArr: [String] = []
        
        if !listOfDownloadedModels.isEmpty {
            for model: DigitalInkRecognitionModel in listOfDownloadedModels {
                modelsArr.append(model.modelIdentifier.languageTag)
            }
            
            call.resolve(["ok": true, "msg":"Successfully retrieved models.", "models": modelsArr])
        } else {
            call.reject("No models currently downloaded.", nil)
        }
    }
}

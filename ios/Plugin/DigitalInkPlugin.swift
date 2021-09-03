import Foundation
import MLKitDigitalInkRecognition
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(DigitalInkPlugin)
public class DigitalInkPlugin: CAPPlugin {
    var strokes: [Stroke] = []
    var points: [StrokePoint] = []
    
    var identifier: DigitalInkRecognitionModelIdentifier = DigitalInkRecognitionModelIdentifier(forLanguageTag: "en")!
    lazy var model: DigitalInkRecognitionModel = DigitalInkRecognitionModel(modelIdentifier: self.identifier)
    
    var modelManager: ModelManager = ModelManager.modelManager()
    var conditions: ModelDownloadConditions = ModelDownloadConditions.init(allowsCellularAccess: true, allowsBackgroundDownloading: true)
    
    lazy var options: DigitalInkRecognizerOptions = DigitalInkRecognizerOptions(model: self.model)
    lazy var recognizer: DigitalInkRecognizer = DigitalInkRecognizer.digitalInkRecognizer(options: self.options)
    
    @objc func checkSingularModel(_ langTag: String) -> Dictionary<String, Any> {
        // if provided identifier is a legit identifier
        if let identifier = DigitalInkRecognitionModelIdentifier(forLanguageTag: langTag) {
            model = DigitalInkRecognitionModel.init(modelIdentifier: identifier)
            // check if it's already downloaded
            if modelManager.isModelDownloaded(model) {
                // it's already downloaded, return data
                return ["ok": true, "msg": langTag + " model is already downloaded."]
            }
            // else, download the approved model
            else {
                modelManager.download(model, conditions: conditions)
                // return data
                return ["ok": true, "msg": "Downloading model!"]
            }
        }
        // we were provided an incorrect tag
        else {
            // return data
            return ["ok": false, "msg": langTag + " is not a valid model identifier"]
        }
    }
    
    @objc func downloadModel(_ call: CAPPluginCall) {
        // if we got a singular identifier from the client
        if let identifierFromClient = call.getString("model") {
            // check for possibilities and return data to client
            call.resolve(checkSingularModel(identifierFromClient))
        }
        // if we got an array of identifiers from the client
        else if let identifiersFromClient = call.getArray("models") as? [String] {
            var result: Bool? = nil
            // check possibilities for each and return true/false if models are legit + downloaded
            for id in identifiersFromClient {
                if checkSingularModel(id)["ok"] != nil { result = true }
                else { result = false; break }
            }
            if result! {
                call.resolve([
                    "ok": true,
                    "msg": "All models received and downloaded."
                ])
            }
            else {
                call.resolve([
                    "ok": false,
                    "msg": "One or more of the provided models was not acceptable. Review to make sure the correct language tag is being used."
                ])
            }
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
        }
    }
    
    @objc func erase(_ call: CAPPluginCall) {
        // erase stroke/point data
        points = []
        strokes = []
        
        call.resolve([
            "ok": true,
            "msg": "Erased stored stroke and point data."
        ])
    }

    @objc func doRecognition(_ call: CAPPluginCall) {
        
        /*
        let writingArea: WritingArea = WritingArea.init(width: 1375, height: 1200);
        let preContext: String = "";
        

        let context: DigitalInkRecognitionContext = DigitalInkRecognitionContext.init(
            preContext: preContext,
            writingArea: writingArea
        );
        */
        
        var candidateText: [String] = []
        var candidateScore: [NSNumber] = []
        
        let ink = Ink.init(strokes: strokes)
        
        recognizer.recognize(
            ink: ink,
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
                }
                else {
                    call.resolve([
                        "ok": false,
                        //"context": preContext,
                        //"writingArea": writingArea,
                        "msg": "Error: " + error.debugDescription,
                        "results": [
                            "candidates": candidateText,
                            "scores": candidateScore
                        ]
                    ])
                }
            }
        )
    }
}

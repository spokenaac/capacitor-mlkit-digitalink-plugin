import XCTest
import MLKitDigitalInkRecognition
@testable import Plugin

class DigitalInkTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testEcho() {
        // This is an example of a functional test case for a plugin.
        // Use XCTAssert and related functions to verify your tests produce the correct results.

        let implementation = DigitalInk()
        let value = "Hello, World!"
        let result = implementation.echo(value)

        XCTAssertEqual(value, result)
    }

    // Integration test: linking alone cannot prove that a patched ML Kit
    // simulator binary can download a model and execute recognition.
    func testEnglishHandwritingRecognition() throws {
        let identifier = try XCTUnwrap(DigitalInkRecognitionModelIdentifier(forLanguageTag: "en-US"))
        let model = DigitalInkRecognitionModel(modelIdentifier: identifier)
        let manager = ModelManager.modelManager()
        if !manager.isModelDownloaded(model) {
            let downloaded = expectation(for: NSPredicate { _, _ in
                manager.isModelDownloaded(model)
            }, evaluatedWith: nil)
            manager.download(model, conditions: ModelDownloadConditions(
                allowsCellularAccess: true, allowsBackgroundDownloading: false))
            wait(for: [downloaded], timeout: 120)
        }
        guard manager.isModelDownloaded(model) else { return }

        // Draw an X using two diagonal strokes in a 200 x 200 writing area.
        var descending: [StrokePoint] = []
        var ascending: [StrokePoint] = []
        for index in 0...10 {
            let distance = Float(index) * 12
            descending.append(StrokePoint(x: 30 + distance, y: 30 + distance))
            ascending.append(StrokePoint(x: 150 - distance, y: 30 + distance))
        }
        let strokes = [Stroke(points: descending), Stroke(points: ascending)]
        let recognizer = DigitalInkRecognizer.digitalInkRecognizer(options: DigitalInkRecognizerOptions(model: model))
        let recognized = expectation(description: "ML Kit executes handwriting recognition")
        recognizer.recognize(ink: Ink(strokes: strokes), context: DigitalInkRecognitionContext(
            preContext: "", writingArea: WritingArea(width: 200, height: 200))) { result, error in
            XCTAssertNil(error)
            XCTAssertFalse(result?.candidates.isEmpty ?? true)
            XCTAssertTrue(result?.candidates.contains { $0.text.lowercased() == "x" } ?? false)
            print("Digital Ink recognition candidates: \(result?.candidates.map { $0.text } ?? [])")
            recognized.fulfill()
        }
        wait(for: [recognized], timeout: 30)
    }
}

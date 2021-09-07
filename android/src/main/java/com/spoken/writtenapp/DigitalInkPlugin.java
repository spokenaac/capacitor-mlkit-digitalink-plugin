package com.spoken.writtenapp;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

import com.google.mlkit.common.MlKitException;
import com.google.mlkit.common.model.DownloadConditions;
import com.google.mlkit.common.model.RemoteModelManager;

import com.google.mlkit.vision.digitalink.DigitalInkRecognition;
import com.google.mlkit.vision.digitalink.DigitalInkRecognitionModel;
import com.google.mlkit.vision.digitalink.DigitalInkRecognitionModelIdentifier;
import com.google.mlkit.vision.digitalink.DigitalInkRecognizer;
import com.google.mlkit.vision.digitalink.DigitalInkRecognizerOptions;
import com.google.mlkit.vision.digitalink.Ink;

import org.json.JSONException;

import java.lang.reflect.Array;

@CapacitorPlugin(name = "DigitalInk")
public class DigitalInkPlugin extends Plugin {

    public Ink.Builder inkBuilder = Ink.builder();
    public Ink.Stroke.Builder strokeBuilder;
    public DigitalInkRecognizer recognizer;
    public RemoteModelManager remoteModelManager = RemoteModelManager.getInstance();

    @PluginMethod
    public void downloadModel(PluginCall call) {
        JSObject res = new JSObject();
        String langTag = call.getString("model");

        DigitalInkRecognitionModelIdentifier identifier;
        try {
            identifier = DigitalInkRecognitionModelIdentifier.fromLanguageTag(langTag);

            DigitalInkRecognitionModel model = DigitalInkRecognitionModel.builder(identifier).build();

            recognizer = DigitalInkRecognition.getClient(
                    DigitalInkRecognizerOptions.builder(model).build()
            );

            remoteModelManager
                .download(model, new DownloadConditions.Builder().build())
                .addOnSuccessListener(response -> {
                    res.put("ok", true);
                    res.put("msg", response);
                    call.resolve(res);
                })
                .addOnFailureListener(
                    error -> call.reject(error.toString())
                );
        }
        catch (MlKitException error) {
            call.reject(error.toString());
        }
    }

    @PluginMethod
    public void logStrokes(PluginCall call) throws JSONException {
        com.getcapacitor.JSArray xArr = call.getArray("x");
        com.getcapacitor.JSArray yArr = call.getArray("y");
        com.getcapacitor.JSArray tArr = call.getArray("t");

        // if we received time, implement it in the points
        // if not, only do (x,y) coordinates
        // then loop through and create points for each provided coordinate set
        if (tArr.length() != 0) {
            for (int i = 0; i < xArr.length(); i++) {
                float x = (float) xArr.get(i);
                float y = (float) yArr.get(i);
                long t = tArr.getInt(i);

                // create (x, y) point, add to stroke builder
                strokeBuilder.addPoint(Ink.Point.create(x, y, t));
            }
            // build the stroke, and add the resulting stroke to the ink builder
            inkBuilder.addStroke(strokeBuilder.build());
            strokeBuilder = null;
        }
        else {
            for (int i = 0; i < xArr.length(); i++) {
                float x = (float) xArr.get(i);
                float y = (float) yArr.get(i);

                // create (x, y) point, add to stroke builder
                strokeBuilder.addPoint(Ink.Point.create(x, y));
            }
            // build the stroke, and add the resulting stroke to the ink builder
            inkBuilder.addStroke(strokeBuilder.build());
            strokeBuilder = null;
        }
    }

    @PluginMethod
    public void erase(PluginCall call) {
        strokeBuilder = null;
        inkBuilder = null;
        inkBuilder = Ink.builder();

        JSObject res = new JSObject();
        res.put("ok", true);
        res.put("msg", "Erased stored stroke and point data.");

        call.resolve(res);
    }

    @PluginMethod
    public void doRecognition(PluginCall call) {
        String[] candidateText = null;
        Float[] candidateScore = null;
        JSObject res = new JSObject();
        JSObject candidateInfo = new JSObject();

        // build the ink to send to recognizer
        // the ink builder should have all strokes from .addStroke() in logStrokes()
        Ink ink = inkBuilder.build();

        recognizer.recognize(ink)
            .addOnSuccessListener(
                result -> {
                    for (int i = 0; i < result.getCandidates().size(); i++) {
                        candidateText[i] = result.getCandidates().get(i).getText();
                        candidateScore[i] = result.getCandidates().get(i).getScore();
                    }
                    candidateInfo.put("candidates", candidateText);
                    candidateInfo.put("scores", candidateScore);

                    res.put("ok", true);
                    res.put("msg", "Recognized successfully");
                    res.put("results", candidateInfo);
                }
            )
            .addOnFailureListener(
                error -> {
                    call.reject(error.toString());
                }
            );
    }
}

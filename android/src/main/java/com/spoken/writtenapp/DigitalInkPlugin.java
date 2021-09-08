package com.spoken.writtenapp;

import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

import com.google.android.gms.tasks.Task;
import com.google.mlkit.common.MlKitException;
import com.google.mlkit.common.model.DownloadConditions;
import com.google.mlkit.common.model.RemoteModelManager;
import com.google.mlkit.common.model.RemoteModel;

import com.google.mlkit.vision.digitalink.DigitalInkRecognition;
import com.google.mlkit.vision.digitalink.DigitalInkRecognitionModel;
import com.google.mlkit.vision.digitalink.DigitalInkRecognitionModelIdentifier;
import com.google.mlkit.vision.digitalink.DigitalInkRecognizer;
import com.google.mlkit.vision.digitalink.DigitalInkRecognizerOptions;
import com.google.mlkit.vision.digitalink.Ink;

import org.json.JSONException;

import java.lang.reflect.Array;
import java.util.Dictionary;
import java.util.Iterator;
import java.util.Set;

@CapacitorPlugin(name = "DigitalInk")
public class DigitalInkPlugin extends Plugin {
    // Ink builder holds stroke data from various logStrokes() calls
    Ink.Builder inkBuilder = Ink.builder();

    // Model defines what language model the recognizer uses to recognize
    DigitalInkRecognitionModel model;

    // Recognizer uses stroke data to infer from the selected DigitalInk model
    DigitalInkRecognizer recognizer;

    // instantiate recognizer to default en-US model
    public DigitalInkPlugin() {
        try {
            DigitalInkRecognitionModelIdentifier defaultIdentifier =
                    DigitalInkRecognitionModelIdentifier.fromLanguageTag("en-US");

            model = DigitalInkRecognitionModel.builder(defaultIdentifier).build();

            recognizer = DigitalInkRecognition.getClient(
                DigitalInkRecognizerOptions.builder(model).build()
            );
        }
        // TODO better catch here
        catch (MlKitException error) {
            System.out.println(" ");
            System.out.println("Initialization error...");
            System.out.println(error);
            System.out.println(" ");
        }
    }

    public float[] convertToFloatArray(JSArray arr) throws JSONException {
        float[] floatArr = new float[arr.length()];

        for (int i = 0; i < arr.length(); i++) {
            if (arr.get(i) instanceof Double) {
                Double dub = (Double) arr.get(i);
                floatArr[i] = dub.floatValue();
            }
            else if (arr.get(i) instanceof Integer) {
                int integer = (int) arr.get(i);
                floatArr[i] = integer;
            }
        }
        return floatArr;
    }

    @PluginMethod(returnType = PluginMethod.RETURN_CALLBACK)
    public void downloadSingularModel(PluginCall call) {
        // Keep call alive so we can resolve() multiple times
        call.setKeepAlive(true);

        // Model manager that manages already downloaded models, downloading models, and deleting models
        RemoteModelManager remoteModelManager = RemoteModelManager.getInstance();

        // get singular model specified from client
        String langTag = call.getString("model");

        // instantiate response object
        /*
         * Response structure:
         *
         * {
         *   ok: boolean,
         *   msg: string,
         * }
         *
         * */
        JSObject res = new JSObject();

        // checks for whether or not provided language tag is a legit tag
        try {
            // instantiate identifier
            DigitalInkRecognitionModelIdentifier identifier =
                    DigitalInkRecognitionModelIdentifier.fromLanguageTag(langTag);

            // build the model from the valid language tag
            DigitalInkRecognitionModel model =
                    DigitalInkRecognitionModel.builder(identifier).build();

            // notifies client that model is being checked/downloaded
            res.put("ok", true);
            res.put("msg", "Processing singular model " + langTag + "...");
            call.resolve(res);

            // check if model is already downloaded
            remoteModelManager.isModelDownloaded(model)
            .addOnCompleteListener(result -> {
                if (result.getResult()) {
                    // if the model is already downloaded
                    res.put("ok", true);
                    res.put("msg", langTag + " model is already downloaded.");
                    call.setKeepAlive(false);
                    call.resolve(res);
                }
                else {
                    // if the model is not already downloaded, download the new model
                    remoteModelManager
                    .download(model, new DownloadConditions.Builder().build())
                    .addOnCompleteListener(response -> {
                        if (response.isSuccessful()) {
                            // all is well, resolve the call
                            res.put("ok", true);
                            res.put("msg", langTag + " model was downloaded successfully.");
                            call.setKeepAlive(false);
                            call.resolve(res);
                        }
                    })
                    .addOnFailureListener(error -> {
                        // we failed, reject the call
                        call.setKeepAlive(false);
                        call.reject(error.toString());
                    });
                }
            });
        }
        catch (MlKitException error) {
            call.setKeepAlive(false);
            call.reject(error.toString());
        }
    }

    @PluginMethod(returnType = PluginMethod.RETURN_CALLBACK)
    public void downloadMultipleModels(PluginCall call) {
        // Keep call alive so we can resolve() multiple times
        call.setKeepAlive(true);

        // Model manager that manages already downloaded models, downloading models, and deleting models
        RemoteModelManager remoteModelManager = RemoteModelManager.getInstance();

        // get singular model specified from client
        JSArray langTags = call.getArray("models");

        // instantiate response object
        /*
         * Response structure:
         *
         * {
         *   ok: boolean,
         *   msg: string,
         * }
         *
         * */
        JSObject res = new JSObject();

        res.put("ok", true);
        res.put("done", false);
        res.put("msg", "Processing array of models...");
        call.resolve(res);

        for (int i = 0; i < langTags.length(); i++) {
            Boolean lastModel = (i == langTags.length() - 1);

            try {
                // get current langTag
                String langTag = (String) langTags.get(i);

                // instantiate identifier
                DigitalInkRecognitionModelIdentifier identifier =
                        DigitalInkRecognitionModelIdentifier.fromLanguageTag(langTag);

                // build the model from the valid language tag
                DigitalInkRecognitionModel model =
                        DigitalInkRecognitionModel.builder(identifier).build();

                // check if model is already downloaded
                remoteModelManager.isModelDownloaded(model)
                .addOnCompleteListener(result -> {
                    if (result.getResult()) {
                        // if the model is already downloaded
                        res.put("ok", true);
                        res.put("done", lastModel);
                        res.put("msg", langTag + " model is already downloaded.");
                        call.resolve(res);

                        if (lastModel) {
                            // it's the last model, this should be last call resolve
                            call.setKeepAlive(false);
                        }
                    }
                    else {
                        // if the model is not already downloaded, download the new model
                        remoteModelManager
                        .download(model, new DownloadConditions.Builder().build())
                        .addOnCompleteListener(response -> {
                            if (response.isSuccessful()) {
                                // all is well, resolve the call
                                res.put("ok", true);
                                res.put("done", lastModel);
                                res.put("msg", langTag + " model was downloaded successfully.");

                                call.resolve(res);

                                if (lastModel) {
                                    // it's the last model, this should be last call resolve
                                    call.setKeepAlive(false);
                                }
                            }
                        })
                        .addOnFailureListener(error -> {
                            // we failed, reject the call
                            call.reject(error.toString());

                            if (lastModel) {
                                // it's the last model, this should be last call resolve
                                call.setKeepAlive(false);
                            }
                        });
                    }
                });
            }
            catch (MlKitException error) {
                call.reject(error.toString());

                if (lastModel) {
                    // it's the last model, this should be last call resolve
                    call.setKeepAlive(false);
                }

            }
            catch (JSONException error) {
                call.reject(error.toString());

                if (lastModel) {
                    // it's the last model, this should be last call resolve
                    call.setKeepAlive(false);
                }
            }
        }
    }

    @PluginMethod(returnType = PluginMethod.RETURN_CALLBACK)
    public void deleteModel(PluginCall call) {
        // Keep call alive so we can resolve() multiple times
        call.setKeepAlive(true);

        // instantiate response object
        /*
         * Response structure:
         *
         * {
         *   ok: boolean,
         *   msg: string,
         * }
         *
         * */
        JSObject res = new JSObject();

        // Model manager that manages already downloaded models, downloading models, and deleting models
        RemoteModelManager remoteModelManager = RemoteModelManager.getInstance();

        if (call.getData().has("all")) {
            // we want to delete all models
            remoteModelManager.getDownloadedModels(RemoteModel.class)
            .addOnCompleteListener(result -> {
                Set downloadedModels = result.getResult();

                Iterator modelsIter = downloadedModels.iterator();

                RemoteModel modelToDelete = (RemoteModel) modelsIter.next();

                while (modelsIter.hasNext()) {
                    remoteModelManager.deleteDownloadedModel(modelToDelete)
                    .addOnCompleteListener(deleteResult -> {
                        if (deleteResult.isSuccessful()) {
                            // deletion was successful
                            res.put("ok", true);
                            res.put("msg", modelToDelete.getModelName() + " has been deleted")
                            call.resolve(res);
                        }
                    });
                }
                res.put("ok", true);
                res.put("msg", "All models have been deleted");
                call.resolve(res);
                call.setKeepAlive(false);
            });
        }
        else if (call.getData().has("model")) {
            // we want to delete a singular model
            String modelNameToDelete = call.getString("model");

            RemoteModel modelToDelete = (RemoteModel) modelNameToDelete;

            remoteModelManager.getDownloadedModels(RemoteModel.class)
        }
    }

    @PluginMethod
    public void logStrokes(PluginCall call) throws JSONException {
        JSObject res = new JSObject();

        float[] xArr = convertToFloatArray(call.getArray("x"));
        float[] yArr = convertToFloatArray(call.getArray("y"));

        // instantiate stroke builder--we will build this to generate a Stroke,
        // which will then pass into the Ink builder
        Ink.Stroke.Builder strokeBuilder = Ink.Stroke.builder();

        // if we received time, implement it in the points (x, y, t)
        // if not, only do (x,y) coordinates
        if (call.getData().has("t")) {
            // set the tArr since we have it
            JSArray tArr = call.getArray("t");

            for (int i = 0; i < xArr.length; i++) {
                float x = xArr[i];
                float y = yArr[i];
                long t = (long) tArr.get(i);

                // create (x, y) point, add to stroke builder
                Ink.Point point = Ink.Point.create(x, y, t);

                // add the point
                strokeBuilder.addPoint(point);
            }
            // build the stroke, and add the resulting stroke to the ink builder
            inkBuilder.addStroke(strokeBuilder.build());

            res.put("ok", true);
            res.put("msg", "(with time values) stroke added");
            call.resolve(res);
        }
        // we didn't receive time values
        else {
            for (int i = 0; i < xArr.length; i++) {
                float x = xArr[i];
                float y = yArr[i];

                // create (x, y) point, add to stroke builder
                Ink.Point point = Ink.Point.create(x, y);

                // add the point
                strokeBuilder.addPoint(point);
            }
            // build the stroke, and add the resulting stroke to the ink builder
            inkBuilder.addStroke(strokeBuilder.build());

            res.put("ok", true);
            res.put("msg", "(without time values) stroke added");
            call.resolve(res);
        }
    }

    @PluginMethod
    public void erase(PluginCall call) {
        // reset the ink builder
        inkBuilder = Ink.builder();

        // instantiate response object
        JSObject res = new JSObject();
        res.put("ok", true);
        res.put("msg", "Erased stored stroke and point data.");

        // return response object to client
        call.resolve(res);
    }

    @PluginMethod
    public void doRecognition(PluginCall call) {
        // build the ink to send to recognizer
        // the ink builder should have all strokes from .addStroke() in logStrokes()
        Ink ink = inkBuilder.build();

        // if we were sent a model to use specifically
        if (call.getData().has("model")) {
            // instantiate langTag as the client's model
            String langTag = call.getString("model");

            // if the model sent from the client is equal to the
            // already equipped model, don't change anything
            if (model.getModelIdentifier().getLanguageTag() == langTag) {
                recognize(ink, call);
            }
            // we were sent a model from the client that was not equal
            // to the already equipped model
            else {
                // try block checks for whether or not provided language tag is a legit tag
                try {
                    DigitalInkRecognitionModelIdentifier identifier =
                            DigitalInkRecognitionModelIdentifier.fromLanguageTag(langTag);

                    // set the new model
                    model = DigitalInkRecognitionModel.builder(identifier).build();

                    // set recognizer to use the new model
                    recognizer = DigitalInkRecognition.getClient(
                            DigitalInkRecognizerOptions.builder(model).build()
                    );

                    // recognize the ink with the new model
                    recognize(ink, call);
                }
                catch (MlKitException error) {
                    call.reject(error.toString());
                }
            }
        }
        // we were not provided a specific model to use,
        // we should use the default
        else {
            recognize(ink, call);
        }
    }

    public void recognize(Ink ink, PluginCall call) {
        JSArray candidateText = new JSArray();
        JSArray candidateScore = new JSArray();
        JSObject candidateInfo = new JSObject();
        JSObject res = new JSObject();

        /*
         * Response structure:
         *
         * {
         *   ok: boolean,
         *   msg: string,
         *   results: { candidates: string[], scores: number[] },
         *   model: string | undefined (Optional),
         *   context: string | undefined (Optional),
         *   writingArea: { w: number, h: number } | undefined (Optional)
         * }
         *
         * */

        // recognize ink data
        recognizer.recognize(ink)
        .addOnSuccessListener(
            result -> {
                // iterate through candidates and format into JSArray for response
                for (int i = 0; i < result.getCandidates().size(); i++) {
                    candidateText.put(result.getCandidates().get(i).getText());
                    candidateScore.put(result.getCandidates().get(i).getScore());
                }

                // add JSArrays into JSObject for response
                candidateInfo.put("candidates", candidateText);
                candidateInfo.put("scores", candidateScore);

                res.put("ok", true);
                res.put("msg", "Recognized successfully");
                res.put("results", candidateInfo);

                // send responses back to the client
                call.resolve(res);
            }
        )
        .addOnFailureListener(
            error -> {
                call.reject(error.toString());
            }
        );
    }
}

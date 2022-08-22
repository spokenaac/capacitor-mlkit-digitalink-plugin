package com.spoken.writtenapp;

import android.speech.RecognizerIntent;

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
import com.google.mlkit.vision.digitalink.RecognitionContext;
import com.google.mlkit.vision.digitalink.WritingArea;
import com.google.mlkit.vision.digitalink.Ink;

import org.json.JSONArray;
import org.json.JSONException;

import java.lang.reflect.Array;
import java.util.Dictionary;
import java.util.Iterator;
import java.util.Set;

@CapacitorPlugin(name = "DigitalInk")
public class DigitalInkPlugin extends Plugin {
    // Ink builder holds stroke data from various logStrokes() calls
    Ink.Builder inkBuilder = Ink.builder();

    // Model manager that manages already downloaded models, downloading models, and deleting models
    RemoteModelManager remoteModelManager = RemoteModelManager.getInstance();

    // Model defines what language model the recognizer uses to recognize
    DigitalInkRecognitionModel model;

    // Recognizer uses stroke data to infer from the selected DigitalInk model
    DigitalInkRecognizer recognizer;

    // instantiate recognizer to default en-US model
    public DigitalInkPlugin() {
        try {
            DigitalInkRecognitionModelIdentifier defaultIdentifier =
                    DigitalInkRecognitionModelIdentifier.fromLanguageTag("en-US");

            // instantiate default model as en-US
            model = DigitalInkRecognitionModel.builder(defaultIdentifier).build();

            // download the default model
            remoteModelManager.download(model, new DownloadConditions.Builder().build());

            // set recognizer to use default en-US
            recognizer = DigitalInkRecognition.getClient(
                DigitalInkRecognizerOptions.builder(model).build()
            );
        }
        catch (MlKitException error) {
            System.out.println(" ");
            System.out.println("Initialization error...");
            System.out.println(error);
            System.out.println(" ");
        }
    }

    public void initializePlugin(PluginCall call) {
        call.unimplemented("Not implemented on Android.");
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

    public DigitalInkRecognitionModel createRemoteModel(String langTag, PluginCall call) {
        try {
            // instantiate identifier
            DigitalInkRecognitionModelIdentifier newIdentifier =
                    DigitalInkRecognitionModelIdentifier.fromLanguageTag(langTag);

            // build the model from the valid language tag
            DigitalInkRecognitionModel newModel =
                    DigitalInkRecognitionModel.builder(newIdentifier).build();

            return newModel;
        }
        catch (MlKitException error) {
            call.reject(error.toString());

            return null;
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
    public void logStrokes(PluginCall call) throws JSONException {
        JSObject res = new JSObject();

        System.out.println(call.getArray("y"));

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
                long t = ((Number) tArr.get(i)).longValue();

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
    public void doRecognition(PluginCall call) {
        // build the ink to send to recognizer
        // the ink builder should have all strokes from .addStroke() in logStrokes()
        Ink ink = inkBuilder.build();

        RecognitionContext.Builder recognizerContextBuilder = RecognitionContext.builder();
        recognizerContextBuilder.setPreContext("");
        recognizerContextBuilder.setWritingArea(new WritingArea(0, 0));

        RecognitionContext recognizerContext = recognizerContextBuilder.build();

        if (call.getData().has("context")) {
            try {

                JSArray context = call.getArray("context");
                String text = (String) context.get(0);
                Float[] dimensions = (Float[]) context.get(1);

                recognizerContextBuilder.setPreContext(text);
                recognizerContextBuilder.setWritingArea(new WritingArea(dimensions[0], dimensions[1]));
                recognizerContext = recognizerContextBuilder.build();
            }
            catch (JSONException error) {
                call.reject("Error with context: " + error.toString());
            }
        }

        RecognitionContext finalRecognizerContext = recognizerContext;

        String langTag = "";
        Boolean sentModel = false;

        if (call.getString("model").length() > 0) {
            langTag = call.getString("model");
            sentModel = true;
        }

        // if we were sent a model to use specifically
        if (sentModel) {
            // make language tag into the correct model type
            // also catches if langTag is not a legit model/misspelled, etc.
            DigitalInkRecognitionModel newModel = createRemoteModel(langTag, call);

            if (newModel != null) {
                String finalLangTag = langTag;
                remoteModelManager.isModelDownloaded(newModel)
                .addOnSuccessListener(result -> {
                    if (result) {
                        // the model is downloaded
                        // set the recognizer to use the client-specified model
                        recognizer = DigitalInkRecognition.getClient(
                                DigitalInkRecognizerOptions.builder(newModel).build()
                        );

                        // perform the recognition with client-specified model
                        recognize(ink, finalRecognizerContext, call);
                    } else {
                        // the model isn't downloaded yet
                        call.reject(finalLangTag + " model is not downloaded.");
                    }
                })
                .addOnFailureListener(result -> {
                    call.reject(result.getMessage());
                });
            }
        } else {
            // we were not provided a specific model to use, we should use the default
            remoteModelManager.isModelDownloaded(model)
                    .addOnSuccessListener(result -> {
                        if (result) {
                            // the default model is downloaded
                            // set the recognizer to use the default model
                            recognizer = DigitalInkRecognition.getClient(
                                    DigitalInkRecognizerOptions.builder(model).build()
                            );

                            // perform the recognition with default model
                            recognize(ink, finalRecognizerContext, call);
                        }
                        else {
                            // the default model isn't downloaded yet
                            call.reject("default model '" + model.getModelIdentifier().getLanguageTag() + "' is not downloaded."
                            );
                        }
                    })
                    .addOnFailureListener(result -> {
                        call.reject(result.getMessage());
                    });
        }
    }

    public void recognize(Ink ink, RecognitionContext context, PluginCall call) {
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
        recognizer.recognize(ink, context)
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

    @PluginMethod(returnType = PluginMethod.RETURN_CALLBACK)
    public void downloadSingularModel(PluginCall call) {
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

        if (call.getData().has("model")) {
            String langTag = call.getString("model");

            // checks for whether or not provided language tag is a legit tag
            try {
                // instantiate identifier
                DigitalInkRecognitionModelIdentifier newIdentifier =
                        DigitalInkRecognitionModelIdentifier.fromLanguageTag(langTag);

                // build the model from the valid language tag
                DigitalInkRecognitionModel newModel =
                        DigitalInkRecognitionModel.builder(newIdentifier).build();

                // notifies client that model is being checked/downloaded
                res.put("ok", true);
                res.put("done", false);
                res.put("msg", "Processing singular model " + langTag + "...");
                call.resolve(res);

                // check if model is already downloaded
                String finalLangTag = langTag;
                remoteModelManager.isModelDownloaded(newModel)
                        .addOnCompleteListener(result -> {
                            if (result.getResult()) {
                                // if the model is already downloaded
                                res.put("ok", true);
                                res.put("done", true);
                                res.put("msg", finalLangTag + " model is already downloaded.");
                                call.resolve(res);
                                call.setKeepAlive(false);
                            }
                            else {
                                // if the model is not already downloaded, download the new model
                                remoteModelManager
                                        .download(newModel, new DownloadConditions.Builder().build())
                                        .addOnCompleteListener(response -> {
                                            if (response.isSuccessful()) {
                                                // all is well, resolve the call
                                                res.put("ok", true);
                                                res.put("done", true);
                                                res.put("msg", finalLangTag + " model was downloaded successfully.");
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
        } else {
            call.reject("No params sent, no model downloaded");
            call.setKeepAlive(false);
        }
    }

    @PluginMethod(returnType = PluginMethod.RETURN_CALLBACK)
    public void downloadMultipleModels(PluginCall call) {
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

        if (call.getData().has("models")) {
            // get singular model specified from client
            JSArray langTags = call.getArray("models");

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
                    DigitalInkRecognitionModelIdentifier newIdentifier =
                            DigitalInkRecognitionModelIdentifier.fromLanguageTag(langTag);

                    // build the model from the valid language tag
                    DigitalInkRecognitionModel newModel =
                            DigitalInkRecognitionModel.builder(newIdentifier).build();

                    // check if model is already downloaded
                    remoteModelManager.isModelDownloaded(newModel)
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
                                } else {
                                    // if the model is not already downloaded, download the new model
                                    remoteModelManager
                                            .download(newModel, new DownloadConditions.Builder().build())
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
                } catch (MlKitException error) {
                    call.reject(error.toString());

                    if (lastModel) {
                        // it's the last model, this should be last call resolve
                        call.setKeepAlive(false);
                    }
                } catch (JSONException error) {
                    call.reject(error.toString());

                    if (lastModel) {
                        // it's the last model, this should be last call resolve
                        call.setKeepAlive(false);
                    }
                }
            }
        } else {
            call.reject("No params sent, no models downloaded.");
        }
    }

    @PluginMethod(returnType = PluginMethod.RETURN_CALLBACK)
    public void deleteModel(PluginCall call) {
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

        if (call.getData().has("model")) {

            // we were sent a singular model
            String langTag = call.getString("model");

            // create the model from the language tag provided
            DigitalInkRecognitionModel toDelete = createRemoteModel(langTag, call);

            if (toDelete == null) {
                call.reject("Cannot delete invalid model identifier");
            }
            else {
                // check if the model is downloaded. Also checks if language tag provided
                // is a legit model, or is misspelled, etc.
                remoteModelManager.isModelDownloaded(toDelete)
                .addOnSuccessListener(result -> {
                    if (result) {
                        // model is in fact downloaded, we should delete it
                        remoteModelManager.deleteDownloadedModel(toDelete)
                                .addOnCompleteListener(deleted -> {
                                    // send response
                                    res.put("ok", true);
                                    res.put("done", true);
                                    res.put("msg", toDelete.getModelIdentifier().getLanguageTag() + " model deleted successfully.");
                                    call.resolve(res);
                                });
                    }
                    else {
                        System.out.println("error?????");
                        System.out.println(toDelete.getModelIdentifier().getLanguageTag());
                        // model is not downloaded, we can't delete
                        call.reject("Cannot delete " + toDelete.getModelIdentifier().getLanguageTag() + " model, it is not downloaded.");
                    }
                })
                .addOnFailureListener(result -> {
                    // various failures caught. misspelled tag, for one
                    call.reject(result.getMessage());
                });
            }
        }
        else if (call.getData().has("models")) {
            // Keep call alive so we can resolve() multiple times
            call.setKeepAlive(true);

            JSArray langTags = call.getArray("models");

            res.put("ok", true);
            res.put("done", false);
            res.put("msg", "Processing array of models...");

            // iterate through language tag arrays, deleting each model
            for (int i = 0; i < langTags.length(); i++) {
                String langTag = "";
                Boolean isLast = (i == langTags.length() - 1);

                try {langTag = (String) langTags.get(i);}
                catch (JSONException error) {call.reject(error.toString());}

                // create the model class
                DigitalInkRecognitionModel toDelete = createRemoteModel(langTag, call);

                if (toDelete != null) {
                    // check if the model is downloaded. Also checks if language tag provided
                    // is a legit model, or is misspelled, etc.
                    remoteModelManager.isModelDownloaded(toDelete)
                    .addOnSuccessListener(result -> {
                        if (result) {
                            // model is in fact downloaded, we should delete it
                            remoteModelManager.deleteDownloadedModel(toDelete)
                            .addOnCompleteListener(deleted -> {
                                System.out.println(deleted.getResult());
                                res.put("ok", true);
                                res.put("done", isLast);
                                res.put("msg", toDelete.getModelName() + " model deleted successfully.");
                                call.resolve(res);

                                call.setKeepAlive(!isLast);
                            });
                        }
                        else {
                            // model is not downloaded, we can't delete
                            call.reject("Cannot delete " + toDelete.getModelName() + " model, it is not downloaded");
                            call.setKeepAlive(!isLast);
                        }
                    })
                    .addOnFailureListener(result -> {
                        // various failures caught. misspelled tag, for one
                        call.reject(result.getMessage());
                        call.setKeepAlive(!isLast);
                    });
                }
                else {
                    call.reject(langTag + " is not a valid model.");

                    call.setKeepAlive(!isLast);
                }
            }
        }
        else if (call.getData().has("all")) {
            // Keep call alive so we can resolve() multiple times
            call.setKeepAlive(true);

            remoteModelManager.getDownloadedModels(DigitalInkRecognitionModel.class)
            .addOnSuccessListener(result -> {
               // downloaded models return as a Set
               Set allModels = result;

                if (allModels.size() > 0) {
                    // create iterator to feed models in to be deleted
                    Iterator allModelsIter = allModels.iterator();

                    Integer counter = 0;

                    while (allModelsIter.hasNext()) {
                        counter++;
                        Integer finalCounter = counter;

                        // defined model to delete
                        DigitalInkRecognitionModel toDelete = (DigitalInkRecognitionModel) allModelsIter.next();

                        remoteModelManager.deleteDownloadedModel(toDelete)
                        .addOnCompleteListener(delResult -> {
                            // send the response
                            res.put("ok", true);
                            res.put("done", finalCounter == allModels.size());
                            res.put("msg", toDelete.getModelIdentifier().getLanguageTag() + " model deleted successfully.");
                            call.resolve(res);

                            if (finalCounter == allModels.size()) {
                                // last iteration, kill the call
                                call.setKeepAlive(false);
                            }
                        })
                        .addOnFailureListener(error -> {
                            // send error to client
                            call.reject(error.getMessage());

                            if (finalCounter == allModels.size()) {
                                call.setKeepAlive(false);
                            }
                        });
                    }

                    res.put("ok", true);
                    res.put("done", false);
                    res.put("msg", "Deleting models...");
                    call.resolve(res);
                }
                else {
                    call.reject("No models to delete.");

                    // kill the call
                    call.setKeepAlive(false);
                }

           })
            .addOnFailureListener(error -> {
               // send error
               call.reject(error.toString());

               // kill the call
               call.setKeepAlive(false);
           });
        }
        else {
            call.reject("No params given, no models deleted.");
        }
    }

    @PluginMethod
    public void getDownloadedModels(PluginCall call) {
        // instantiate response object
        /*
         * Response structure:
         *
         * {
         *   ok: boolean,
         *   msg: string,
         *   models: string[]
         * }
         *
         * */
        JSObject res = new JSObject();

        remoteModelManager.getDownloadedModels(DigitalInkRecognitionModel.class)
        .addOnSuccessListener(result -> {
            // downloaded models return as a Set
            Set allModels = result;

            if (allModels.size() > 0) {
                res.put("ok", true);
                res.put("msg", "All models successfully deleted.");
                res.put("models", allModels);
                call.resolve(res);
            }
            else {
                res.put("ok", true);
                res.put("msg", "No models are downloaded.");
                call.resolve(res);
            }

        })
        .addOnFailureListener(error -> {
            // send error
            call.reject(error.toString());
        });
    }
}

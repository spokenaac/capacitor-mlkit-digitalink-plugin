package com.spoken.writtenapp;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

import com.google.mlkit.vision.digitalink.DigitalInkRecognitionModel;
import com.google.mlkit.vision.digitalink.DigitalInkRecognitionModelIdentifier;
import com.google.mlkit.vision.digitalink.DigitalInkRecognizer;
import com.google.mlkit.vision.digitalink.DigitalInkRecognizerOptions;
import com.google.mlkit.vision.digitalink.Ink;

import org.json.JSONException;

import java.lang.reflect.Array;

@CapacitorPlugin(name = "DigitalInk")
public class DigitalInkPlugin extends Plugin {

    public int[] points = null;
    public int[] strokes = null;

    @PluginMethod
    public void erase(PluginCall call) {
        points = strokes = null;

        JSObject ret = new JSObject();
        ret.put("ok", true);
        ret.put("msg", "Erased stored stroke and point data.");

        call.resolve(ret);
    }

    @PluginMethod
    public void logStrokes(PluginCall call) throws JSONException {
        com.getcapacitor.JSArray xArr = call.getArray("x");
        com.getcapacitor.JSArray yArr = call.getArray("y");
        com.getcapacitor.JSArray tArr = call.getArray("t");

        if (tArr.length() != 0) {
            for (int i  = 0; i < xArr.length(); i++) {
                float x = (float) xArr.getInt(i);
                float y = (float) yArr.get(i);
                long t = tArr.getInt(i);

            }
        }
        else {

        }

    }
}

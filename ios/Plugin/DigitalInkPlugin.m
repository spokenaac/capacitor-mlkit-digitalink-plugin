#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

// Define the plugin using the CAP_PLUGIN Macro, and
// each method the plugin supports using the CAP_PLUGIN_METHOD macro.
CAP_PLUGIN(DigitalInkPlugin, "DigitalInk",
    CAP_PLUGIN_METHOD(erase, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(logStrokes, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(deleteModel, CAPPluginReturnCallback);
    CAP_PLUGIN_METHOD(doRecognition, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(initializePlugin, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(getDownloadedModels, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(downloadSingularModel, CAPPluginReturnCallback);
    CAP_PLUGIN_METHOD(downloadMultipleModels, CAPPluginReturnCallback);
)

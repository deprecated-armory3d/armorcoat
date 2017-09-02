// Auto-generated
package ;
class Main {
    public static inline var projectName = 'mated';
    public static inline var projectPackage = 'arm';
    public static inline var projectAssets = 25;
    public static var projectWindowMode = kha.WindowMode.Window;
    public static inline var projectWindowResize = true;
    public static inline var projectWindowMaximize = true;
    public static inline var projectWindowMinimize = true;
    public static var projectWidth = 1280;
    public static var projectHeight = 690;
    static inline var projectSamplesPerPixel = 1;
    static inline var projectVSync = true;
    static inline var projectScene = 'Scene';
    static var state:Int;
    #if js
    static function loadLib(name:String) {
        kha.LoaderImpl.loadBlobFromDescription({ files: [name] }, function(b:kha.Blob) {
            untyped __js__("(1, eval)({0})", b.toString());
            state--;
            start();
        });
    }
    #end
    public static function main() {
        state = 1;
        #if (js && arm_physics) state++; loadLib("ammo.js"); #end
        #if (js && arm_navigation) state++; loadLib("recast.js"); #end
        state--; start();
    }
    static function start() {
        if (state > 0) return;
        armory.object.Uniforms.register();
        if (projectWindowMode == kha.WindowMode.Fullscreen) { projectWindowMode = kha.WindowMode.BorderlessWindow; projectWidth = kha.Display.width(0); projectHeight = kha.Display.height(0); }
        kha.System.init({title: projectName, width: projectWidth, height: projectHeight, samplesPerPixel: projectSamplesPerPixel, vSync: projectVSync, windowMode: projectWindowMode, resizable: projectWindowResize, maximizable: projectWindowMaximize, minimizable: projectWindowMinimize}, function() {
            iron.App.init(function() {

                iron.Scene.setActive(projectScene, function(object:iron.object.Object) {
                });
            });
        });
    }
}

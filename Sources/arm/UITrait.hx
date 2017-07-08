package arm;

import zui.*;
import zui.Canvas;
import iron.data.SceneFormat;
import iron.data.MeshData;
import iron.object.MeshObject;

class UITrait extends armory.Trait {

	public static var uienabled = true;

	public static var showFiles = false;
	public static var filesDone:String->Void;
	public static var show = true;
	public static var dirty = true;

	var bundled:Map<String, kha.Image> = new Map();
	var ui:Zui;
	var uimodal:Zui;

	public static var ww = 200; // Panel width

	function loadBundled(names:Array<String>, done:Void->Void) {
		var loaded = 0;
		for (s in names) {
			kha.Assets.loadImage(s, function(image:kha.Image) {
				bundled.set(s, image);
				loaded++;
				if (loaded == names.length) done();
			});
		}
	}

	var font:kha.Font;
	public function new() {
		super();

		iron.data.Data.getFont('droid_sans.ttf', function(f:kha.Font) {
			font = f;
			zui.Themes.dark.FILL_WINDOW_BG = true;
			zui.Nodes.getEnumTexts = getEnumTexts;
			zui.Nodes.mapEnum = mapEnum;
			ui = new Zui( { font: f } );
			uimodal = new Zui( { font: f } );
			// ui = new Zui( { font: f, scaleFactor: 8, theme: zui.Themes.light } ); ////
			loadBundled(['files'], done);
		});
	}

	function getEnumTexts():Array<String> {
		return assetNames.length > 0 ? assetNames : [""];
	}

	function mapEnum(s:String):String {
		for (a in assets) if (a.name == s) return a.file;
		return "";
	}

    var currentObject:MeshObject;

	function done() {

		notifyOnInit(function() {
        	currentObject = cast(iron.Scene.active.getChild("Cube"), MeshObject);

			iron.App.notifyOnUpdate(update);
			iron.App.notifyOnRender2D(render);
		});
	}

	function update() {
		updateUI();
		updateFiles();
	}

	function updateUI() {
		var mouse = iron.system.Input.getMouse();
		// if (mouse.started() && mouse.x < 50 && mouse.y < 50) show = !show;

		if (!show) return;
		if (!UITrait.uienabled) return;
	}

	var modalW = 700;
	var modalH = 622;
	var modalHeaderH = 66;
	var modalRectW = 625; // No shadow
	var modalRectH = 545;
	function updateFiles() {
		if (!showFiles) return;

		var mouse = iron.system.Input.getMouse();

		if (mouse.released()) {
			var left = iron.App.w() / 2 - modalRectW / 2;
			var right = iron.App.w() / 2 + modalRectW / 2;
			var top = iron.App.h() / 2 - modalRectH / 2;
			var bottom = iron.App.h() / 2 + modalRectH / 2;
			if (mouse.x < left || mouse.x > right || mouse.y < top + modalHeaderH || mouse.y > bottom) {
				showFiles = false;
			}
		}
	}

	function render(g:kha.graphics2.Graphics) {
		uienabled = !showFiles;
		renderUI(g);
		renderFiles(g);
	}

	var assets:Array<TAsset> = [];
	var assetNames:Array<String> = [];

	public static var cameraType = 0;

	function renderUI(g:kha.graphics2.Graphics) {
		if (!show) return;

		if (!UITrait.uienabled && ui.inputRegistered) ui.unregisterInput();
		if (UITrait.uienabled && !ui.inputRegistered) ui.registerInput();

		var mouse = iron.system.Input.getMouse();
		g.color = 0xffffffff;

		g.end();
		ui.begin(g);
		// ui.begin(rt.g2); ////
		
		if (ui.window(Id.handle(), 0, 0, ww, iron.App.h())) {

			// ui.text("Ready"); // Console

		// if (ui.window(Id.handle(), 0, 0, rt.width, rt.height)) { ////

			if (ui.panel(Id.handle({selected: true}), "ASSETS")) {
				if (ui.button("Import")) {
					showFiles = true;
					filesDone = function(path:String) {
						iron.data.Data.getImage(path, function(image:kha.Image) {
							var ar = path.split("/");
							var name = ar[ar.length - 1];
							assets.push({image: image, name: name, file: path});
							assetNames.push(name);
						});
					}
				}

				if (assets.length > 0) {
					for (i in 0...assets.length) {
						var asset = assets[i];
						ui.image(asset.image);
						asset.name = ui.textInput(Id.handle().nest(i, {text: asset.name}), "Name", Right);
					}
				}
				// else {
					// ui.text("Drag & drop assets here");
				// }
			}
			ui.separator();
		}
		ui.end();
		g.begin(false);
	}

	function renderFiles(g:kha.graphics2.Graphics) {
		if (!showFiles) return;

		var left = iron.App.w() / 2 - modalW / 2;
		var top = iron.App.h() / 2 - modalH / 2;
		var filesImg = bundled.get('files');
		g.color = 0xffffffff;
		g.drawScaledImage(filesImg, left, top, modalW, modalH);

		var leftRect = Std.int(iron.App.w() / 2 - modalRectW / 2);
		var rightRect = Std.int(iron.App.w() / 2 + modalRectW / 2);
		var topRect = Std.int(iron.App.h() / 2 - modalRectH / 2);
		var bottomRect = Std.int(iron.App.h() / 2 + modalRectH / 2);
		topRect += modalHeaderH;
		
		uimodal.beginLayout(g, leftRect, topRect, modalRectW);
		var pathHandle = Id.handle();
		pathHandle.text = uimodal.textInput(pathHandle);
		var path = zui.Ext.fileBrowser(uimodal, pathHandle);
		uimodal.endLayout(false);

		uimodal.beginLayout(g, rightRect - 100, bottomRect - 30, 100);
		if (uimodal.button("OK")) {
			showFiles = false;
			filesDone(path);
		}
		uimodal.endLayout(false);

		uimodal.beginLayout(g, rightRect - 200, bottomRect - 30, 100);
		if (uimodal.button("Cancel")) {
			showFiles = false;
		}
		uimodal.endLayout();
	}
}

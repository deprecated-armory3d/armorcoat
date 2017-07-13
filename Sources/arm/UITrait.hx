package arm;

import zui.*;
import zui.Zui.State;
import zui.Canvas;
import iron.data.SceneFormat;
import iron.data.MeshData;
import iron.object.MeshObject;

class UITrait extends armory.Trait {

	public static var uienabled = true;
	public static var isScrolling = false;
	public static var isDragging = false;
	public static var dragAsset:TAsset = null;

	public static var showFiles = false;
	public static var filesDone:String->Void;
	public static var show = true;
	public static var dirty = true;

	var bundled:Map<String, kha.Image> = new Map();
	var ui:Zui;
	var uimodal:Zui;

	public static var ww = 200; // Panel width

	var meshes = ["Plane", "Sphere", "Cube", "Monkey"];

	// public static function onSetTarget(target:String) {
	// 	if (target == "shadowMap") return;

	// 	var g = iron.Scene.active.camera.renderPath.currentRenderTarget;
	// 	g.viewport(300, 0, 1280 - 300, 690);
	// 	g.scissor(300, 0, 1280 - 300, 690);
	// }

	// public static function onFrameRendered() {
	// 	var g = iron.Scene.active.camera.renderPath.currentRenderTarget;
	// 	g.viewport(0, 0, 1280, 690);
	// 	g.scissor(0, 0, 1280, 690);
	// }

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

		armory.system.Cycles.arm_export_tangents = false;

		iron.data.Data.getFont('droid_sans.ttf', function(f:kha.Font) {
			font = f;
			zui.Themes.dark.FILL_WINDOW_BG = true;
			zui.Nodes.getEnumTexts = getEnumTexts;
			zui.Nodes.mapEnum = mapEnum;
			ui = new Zui( { font: font } );
			uimodal = new Zui( { font: font } );
			// ui = new Zui( { font: f, scaleFactor: 8, theme: zui.Themes.light } ); ////
			loadBundled(['files', 'noise64'], done);
		});

		kha.System.notifyOnDropFiles(function(filePath:String) {
			if (StringTools.endsWith(filePath, ".obj")) importMesh(filePath);
			else importAsset(filePath);
		});
	}

	function importAsset(path:String) {
		if (!StringTools.endsWith(path, ".jpg") &&
			!StringTools.endsWith(path, ".png") &&
			!StringTools.endsWith(path, ".hdr")) return;
		
		iron.data.Data.getImage(path, function(image:kha.Image) {
			var ar = path.split("/");
			var name = ar[ar.length - 1];
			assets.push({image: image, name: name, file: path, id: assetId++});
			assetNames.push(name);
			hwnd.redraws = 2;
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

		iron.Scene.active.embedded.set('noise64.png', bundled.get('noise64'));

		notifyOnInit(function() {

			// iron.Scene.active.camera.renderPath.onSetTarget = onSetTarget;
			// iron.Scene.active.camera.renderPath.onFrameRendered = onFrameRendered;

			currentObject = cast(iron.Scene.active.getChild("Cube"), MeshObject);

			iron.App.notifyOnUpdate(update);
			iron.App.notifyOnRender2D(render);
		});
	}

	function update() {
		isScrolling = ui.isScrolling;
		updateUI();
		updateFiles();
	}

	function updateUI() {
		var mouse = iron.system.Input.getMouse();
		// if (mouse.started() && mouse.x < 50 && mouse.y < 50) show = !show;

		isDragging = dragAsset != null;
		if (mouse.released() && isDragging) {
			if (UINodes.show && mouse.x > UINodes.wx && mouse.y > UINodes.wy) {
				var index = 0;
				for (i in 0...assets.length) if (assets[i] == dragAsset) { index = i; break; }
				UINodes.acceptDrag(index);
			}
			dragAsset = null;
		}

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

		var ready = showFiles || dirty;
		// TODO: Texture params get overwritten
		if (ready && UINodes.inst._matcon != null) for (t in UINodes.inst._matcon.bind_textures) t.params_set = null;

		iron.Scene.active.camera.renderPath.ready = ready;
		dirty = false;
	}

	var assets:Array<TAsset> = [];
	var assetNames:Array<String> = [];
	var assetId = 0;

	public static var cameraType = 0;
	var textureRes = 2;
	function getTextureRes():Int {
		if (textureRes == 0) return 1024;
		if (textureRes == 1) return 2048;
		if (textureRes == 2) return 4096;
		if (textureRes == 3) return 8192;
		if (textureRes == 4) return 16384;
		if (textureRes == 5) return 20480;
		return 0;
	}

	var hwnd = Id.handle();
	function renderUI(g:kha.graphics2.Graphics) {
		if (!show) return;

		if (!UITrait.uienabled && ui.inputRegistered) ui.unregisterInput();
		if (UITrait.uienabled && !ui.inputRegistered) ui.registerInput();

		g.color = 0xffffffff;

		g.end();
		ui.begin(g);
		// ui.begin(rt.g2); ////
		
		if (ui.window(hwnd, 0, 0, ww, iron.App.h())) {

			if (ui.panel(Id.handle({selected: true}), "PROJECT")) {
				// ui.row([1/2, 1/2]);
				// ui.button("Open");
				// ui.button("Save");

				// if (ui.button("Help")) {
					// showSplash = true;
				// }

				if (ui.button("Export Textures")) {

					var textureSize = getTextureRes();

					showFiles = true;
					filesDone = function(path:String) {
						// var bo = new haxe.io.BytesOutput();
						// var pixels = texpaint.getPixels();
						// var rgb = haxe.io.Bytes.alloc(textureSize * textureSize * 3);
						// // BGRA to RGB
						// for (i in 0...textureSize * textureSize) {
						// 	rgb.set(i * 3 + 0, pixels.get(i * 4 + 2));
						// 	rgb.set(i * 3 + 1, pixels.get(i * 4 + 1));
						// 	rgb.set(i * 3 + 2, pixels.get(i * 4 + 0));
						// }
						// var pngwriter = new arm.format.png.Writer(bo);
		 //    			pngwriter.write(arm.format.png.Tools.buildRGB(textureSize, textureSize, rgb));
						// // var jpgdata:arm.format.jpg.Data.Data = {
						// // 	width: textureSize,
						// // 	height: textureSize,
						// // 	quality: 80,
						// // 	pixels: rgb
						// // };
						// // var jpgwriter = new arm.format.jpg.Writer(bo);
						// // jpgwriter.write(jpgdata);
						// #if kha_krom
						// Krom.fileSaveBytes(path + "/tex_basecol.png", bo.getBytes().getData());
						// #end

						// pixels = texpaint_nor.getPixels();
						// for (i in 0...textureSize * textureSize) {
						// 	rgb.set(i * 3 + 0, pixels.get(i * 4 + 2));
						// 	rgb.set(i * 3 + 1, pixels.get(i * 4 + 1));
						// 	rgb.set(i * 3 + 2, pixels.get(i * 4 + 0));
						// }
						// bo = new haxe.io.BytesOutput();
						// var pngwriter = new arm.format.png.Writer(bo);
		 //    			pngwriter.write(arm.format.png.Tools.buildRGB(textureSize, textureSize, rgb));
		 //    			#if kha_krom
		 //    			Krom.fileSaveBytes(path + "/tex_nor.png", bo.getBytes().getData());
		 //    			#end

		 //    			for (i in 0...textureSize * textureSize) {
						// 	rgb.set(i * 3 + 0, pixels.get(i * 4 + 3));
						// 	rgb.set(i * 3 + 1, pixels.get(i * 4 + 3));
						// 	rgb.set(i * 3 + 2, pixels.get(i * 4 + 3));
						// }
						// bo = new haxe.io.BytesOutput();
						// var pngwriter = new arm.format.png.Writer(bo);
		 //    			pngwriter.write(arm.format.png.Tools.buildRGB(textureSize, textureSize, rgb));
		 //    			#if kha_krom
		 //    			Krom.fileSaveBytes(path + "/tex_height.png", bo.getBytes().getData());
		 //    			#end

		 //    			pixels = texpaint_pack.getPixels(); // occ, rough, met
		 //    			for (i in 0...textureSize * textureSize) {
						// 	rgb.set(i * 3 + 0, pixels.get(i * 4 + 2));
						// 	rgb.set(i * 3 + 1, pixels.get(i * 4 + 2));
						// 	rgb.set(i * 3 + 2, pixels.get(i * 4 + 2));
						// }
						// bo = new haxe.io.BytesOutput();
						// var pngwriter = new arm.format.png.Writer(bo);
		 //    			pngwriter.write(arm.format.png.Tools.buildRGB(textureSize, textureSize, rgb));
		 //    			#if kha_krom
		 //    			Krom.fileSaveBytes(path + "/tex_occ.png", bo.getBytes().getData());
		 //    			#end

		 //    			for (i in 0...textureSize * textureSize) {
						// 	rgb.set(i * 3 + 0, pixels.get(i * 4 + 1));
						// 	rgb.set(i * 3 + 1, pixels.get(i * 4 + 1));
						// 	rgb.set(i * 3 + 2, pixels.get(i * 4 + 1));
						// }
						// bo = new haxe.io.BytesOutput();
						// var pngwriter = new arm.format.png.Writer(bo);
		 //    			pngwriter.write(arm.format.png.Tools.buildRGB(textureSize, textureSize, rgb));
		 //    			#if kha_krom
		 //    			Krom.fileSaveBytes(path + "/tex_rough.png", bo.getBytes().getData());
		 //    			#end

		 //    			for (i in 0...textureSize * textureSize) {
						// 	rgb.set(i * 3 + 0, pixels.get(i * 4));
						// 	rgb.set(i * 3 + 1, pixels.get(i * 4));
						// 	rgb.set(i * 3 + 2, pixels.get(i * 4));
						// }
						// bo = new haxe.io.BytesOutput();
						// var pngwriter = new arm.format.png.Writer(bo);
		 //    			pngwriter.write(arm.format.png.Tools.buildRGB(textureSize, textureSize, rgb));
		 //    			#if kha_krom
		 //    			Krom.fileSaveBytes(path + "/tex_met.png", bo.getBytes().getData());
		 //    			#end
					}
				}
				var hres = Id.handle({position: textureRes});
				textureRes = ui.combo(hres, ["1K", "2K", "4K", "8K", "16K", "20K"], "Res", true);
				// if (hres.changed) {
					// iron.App.notifyOnRender(resizeTargetsHandler);
				// }
				ui.combo(Id.handle(), ["Plane", "Mesh"], "UVs", true);
				// ui.text("Channels");
				ui.row([1/2, 1/2]);
				ui.check(Id.handle({selected: true}), "Base Color");
				ui.check(Id.handle({selected: true}), "Occlusion");
				ui.row([1/2, 1/2]);
				ui.check(Id.handle({selected: true}), "Roughness");
				ui.check(Id.handle({selected: true}), "Metallic");
				ui.check(Id.handle({selected: true}), "Normal Map");
			}

			ui.separator();

			if (ui.panel(Id.handle({selected: true}), "ASSETS")) {
				if (ui.button("Import Mesh")) {
					showFiles = true;
					filesDone = function(path:String) {
						importMesh(path);
					}
				}

				var hmesh = Id.handle({position: 2});
				var meshType = ui.combo(hmesh, meshes, "Mesh", true);
				if (hmesh.changed) {
					currentObject.visible = false;
					currentObject = cast iron.Scene.active.root.getChild(meshes[hmesh.position]);
					currentObject.visible = true;
					UITrait.dirty = true;
				}

				if (ui.button("Import Texture")) {
					showFiles = true;
					filesDone = function(path:String) {
						importAsset(path);
					}
				}

				if (assets.length > 0) {
					var i = assets.length - 1;
					while (i >= 0) {
						var asset = assets[i];
						if (ui.image(asset.image) == State.Started) {
							dragAsset = asset;
						}
						ui.row([1/8, 7/8]);
						var b = ui.button("X");
						asset.name = ui.textInput(Id.handle().nest(asset.id, {text: asset.name}), "", Right);
						assetNames[i] = asset.name;
						if (b) {
							asset.image.unload();
							assets.splice(i, 1);
							assetNames.splice(i, 1);
						}
						i--;
					}
				}
				else {
					ui.text("(Drag & drop assets here)", zui.Zui.Align.Center, 0xff151515);
					ui.text("(.png .jpg .hdr .obj)", zui.Zui.Align.Center, 0xff151515);
				}
			}
			ui.separator();
		}
		ui.end();
		g.begin(false);

		if (dragAsset != null) {
			UITrait.dirty = true;
			var mouse = iron.system.Input.getMouse();
			g.drawScaledImage(dragAsset.image, mouse.x, mouse.y, 128, 128);
		}
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
		
		g.end();
		var path = '/';
		uimodal.begin(g);
		if (uimodal.window(Id.handle(), leftRect, topRect, modalRectW, modalRectH - 100)) {
			var pathHandle = Id.handle();
			pathHandle.text = uimodal.textInput(pathHandle);
			var path = zui.Ext.fileBrowser(uimodal, pathHandle);
		}
		uimodal.end(false);
		g.begin(false);

		uimodal.beginLayout(g, rightRect - 100, bottomRect - 30, 100);
		if (uimodal.button("OK")) {
			showFiles = false;
			filesDone(path);
			UITrait.dirty = true;
		}
		uimodal.endLayout(false);

		uimodal.beginLayout(g, rightRect - 200, bottomRect - 30, 100);
		if (uimodal.button("Cancel")) {
			showFiles = false;
			UITrait.dirty = true;
		}
		uimodal.endLayout();
	}

	function importMesh(path:String) {

		iron.data.Data.getBlob(path, function(b:kha.Blob) {

			var obj = new ObjLoader(b.toString());
			var pa = new TFloat32Array(obj.indexedVertices.length);
			for (i in 0...pa.length) pa[i] = obj.indexedVertices[i];
			var uva = new TFloat32Array(obj.indexedUVs.length);
			for (i in 0...uva.length) uva[i] = obj.indexedUVs[i];
			var na = new TFloat32Array(obj.indexedNormals.length);
			for (i in 0...na.length) na[i] = obj.indexedNormals[i];
			var ia = new TUint32Array(obj.indices.length);
			for (i in 0...ia.length) ia[i] = obj.indices[i];

			var raw:TMeshData = {
				name: "Mesh",
				vertex_arrays: [
					{
						values: pa,
						attrib: "pos"
					},
					{
						values: na,
						attrib: "nor"
					},
					{
						values: uva,
						attrib: "tex"
					}
				],
				index_arrays: [
					{
						values: ia,
						material: 0
					}
				]
			};

			new MeshData(raw, function(md:MeshData) {
				currentObject.data.delete();
				// iron.App.notifyOnRender(clearTargetsHandler);
				currentObject.setData(md);
				UITrait.dirty = true;
			});
		});
	}
}

package arm;

import armory.object.Object;
import armory.system.Cycles;
import zui.*;
import zui.Nodes;
import iron.data.SceneFormat;
import iron.data.MaterialData;

class UINodes extends armory.Trait {

	public static var inst:UINodes;
	public static var show = true;

	public static var wx:Int;
	public static var wy:Int;

	var ui:Zui;
	var drawMenu = false;
	var showMenu = false;
	var hideMenu = false;
	var popupX = 0;
	var popupY = 0;

	var sc:iron.data.ShaderData.ShaderContext = null;
	public var _matcon:TMaterialContext = null;
	var _materialcontext:MaterialContext = null;

	static var font:kha.Font;

	public function new() {
		super();
		inst = this;

		// Load font for UI labels
		iron.data.Data.getFont('droid_sans.ttf', function(f:kha.Font) {

			iron.data.Data.getBlob('default_material.json', function(b:kha.Blob) {

				kha.Assets.loadImage('color_wheel', function(image:kha.Image) {

					canvas = haxe.Json.parse(b.toString());

					font = f;
					var t = Reflect.copy(zui.Themes.dark);
					t.FILL_WINDOW_BG = true;
					t._ELEMENT_H = 18;
					t._BUTTON_H = 16;
					// ui = new Zui({font: f, theme: t, scaleFactor: 2.5}); ////
					ui = new Zui({font: f, theme: t, color_wheel: image});
					ui.scrollEnabled = false;
					armory.Scene.active.notifyOnInit(sceneInit);
				});
			});
		});
	}

	function sceneInit() {
		// Store references to cube and plane objects
		notifyOnRender2D(render2D);
		notifyOnUpdate(update);
	}

	var mx = 0.0;
	var my = 0.0;
	var wh = 300;
	static var frame = 0;
	var mdown = false;
	var mreleased = false;
	var mchanged = false;
	var changed = false;
	function update() {
		if (frame == 8) parseMaterial(); // Temp cpp fix
		frame++;

		var mouse = iron.system.Input.getMouse();
		mreleased = mouse.released();
		mdown = mouse.down();

		if (!show) return;
		if (!UITrait.uienabled) return;
		var keyboard = iron.system.Input.getKeyboard();

		wx = 200;
		wy = iron.App.h() - wh;
		if (mouse.x < wx || mouse.y < wy) return;

		if (ui.isTyping) return;

		if (mouse.started("right")) {
			mx = mouse.x;
			my = mouse.y;
		}
		else if ((mouse.released("right") && mx == mouse.x && my == mouse.y) || keyboard.started("a")) { // Show menu if canvas was not panned
			showMenu = true;
			popupX = Std.int(mouse.x);
			popupY = Std.int(mouse.y);
		}
		else if (mouse.released()) {
			hideMenu = true;
		}

		if (keyboard.started("x")) {
			uinodes.removeNode(uinodes.nodeSelected, canvas);
			changed = true;
		}

		if (keyboard.started("p")) {
			trace(haxe.Json.stringify(canvas));
		}
	}

	static var uinodes = new Nodes();

	static var canvas:TNodeCanvas = null;

	static var bg:kha.Image = null;

	function getNodeX():Int {
		var mouse = iron.system.Input.getMouse();
		return Std.int((mouse.x - wx - uinodes.PAN_X()) / uinodes.SCALE);
	}

	function getNodeY():Int {
		var mouse = iron.system.Input.getMouse();
		return Std.int((mouse.y - wy - uinodes.PAN_Y()) / uinodes.SCALE);
	}

	function render2D(g:kha.graphics2.Graphics) {
		if (!show) return;
		
		if (!UITrait.uienabled && ui.inputRegistered) ui.unregisterInput();
		if (UITrait.uienabled && !ui.inputRegistered) ui.registerInput();
		
		g.end();

		if (bg == null) {
			// var w = rt.width;////
			var w = iron.App.w() - 200;
			// var h = rt.height;////
			var h = wh;
			bg = kha.Image.createRenderTarget(w, h);
			bg.g2.begin(true, 0xff141414);
			for (i in 0...Std.int(h / 40) + 1) {
				bg.g2.color = 0xff303030;
				bg.g2.drawLine(0, i * 40, w, i * 40);
				bg.g2.color = 0xff202020;
				bg.g2.drawLine(0, i * 40 + 20, w, i * 40 + 20);
			}
			for (i in 0...Std.int(w / 40) + 1) {
				bg.g2.color = 0xff303030;
				bg.g2.drawLine(i * 40, 0, i * 40, h);
				bg.g2.color = 0xff202020;
				bg.g2.drawLine(i * 40 + 20, 0, i * 40 + 20, h);
			}
			bg.g2.end();
		}

		// Start with UI
		ui.begin(g);
		// ui.begin(rt.g2); ////
		
		// Make window
		wx = 200;
		wy = iron.App.h() - wh;
		var hwin = Id.handle();
		if (ui.window(hwin, wx, wy, iron.App.w() - 200, wh)) {
		// if (ui.window(hwin, 0, 0, rt.width, rt.height)) { ////

			ui.g.color = 0xffffffff;
			ui.g.drawImage(bg, 0, 0);

			ui.g.font = font;
			ui.g.fontSize = 42;
			var title = "Material";
			// var title = "Material (right-click to add node)";
			var titlew = ui.g.font.width(42, title);
			var titleh = ui.g.font.height(42);
			ui.g.drawString(title, iron.App.w() - 200 - titlew - 20, wh - titleh - 10);
			// ui.g.drawString(title, rt.width - titlew - 20, rt.height - titleh - 10); ////
			
			// Recompile material on change
			ui.changed = false;
			uinodes.nodeCanvas(ui, canvas);

			if (ui.changed) {
				mchanged = true;
				if (!mdown) changed = true;
			}
			if ((mreleased && mchanged) || changed) {
				mchanged = changed = false;
				parseMaterial();
			}
		}

		ui.endWindow();

		if (drawMenu) {
			
			var numItems = 8;
			var ph = numItems * 20;
			var py = popupY;
			if (py + ph > iron.App.h()) py = iron.App.h() - ph;
			g.color = 0xff222222;
			g.fillRect(popupX, py, 120, ph);

			ui.beginLayout(g, popupX, py, 120);
			
			if (ui.button("Material Output")) {

				var node_id = uinodes.getNodeId(canvas.nodes);
				var n:TNode = {
					id: node_id,
					name: "Material Output",
					type: "OUTPUT_MATERIAL_PBR",
					x: getNodeX(),
					y: getNodeY(),
					color: 0xffb34f5a,
					inputs: [
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Base Color",
							type: "RGBA",
							color: 0xffc7c729,
							default_value: [0.8, 0.8, 0.8, 1.0]
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Opacity",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 1.0
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Occlusion",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 1.0
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Roughness",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 0.1
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Metallic",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 0.0
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Normal Map",
							type: "VECTOR",
							color: 0xff63c763,
							default_value: [0.5, 0.5, 1.0]
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Emission",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 0.0
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Height",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 0.0
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Subsurface",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 0.0
						}
					],
					outputs: [],
					buttons: []
				};
				canvas.nodes.push(n);
				uinodes.nodeDrag = n;
				uinodes.nodeSelected = n;
			}
			if (ui.button("RGB")) {
				var node_id = uinodes.getNodeId(canvas.nodes);
				var n:TNode = {
					id: node_id,
					name: "RGB",
					type: "RGB",
					x: getNodeX(),
					y: getNodeY(),
					color: 0xffb34f5a,
					inputs: [],
					outputs: [
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Color",
							type: "RGBA",
							color: 0xffc7c729,
							default_value: [0.5, 0.5, 0.5, 1.0]
						}
					],
					buttons: [
						{
							name: "default_value",
							type: "RGBA",
							output: 0
						}
					]
				};
				canvas.nodes.push(n);
				uinodes.nodeDrag = n;
				uinodes.nodeSelected = n;
			}
			if (ui.button("Value")) {
				var node_id = uinodes.getNodeId(canvas.nodes);
				var n:TNode = {
					id: node_id,
					name: "Value",
					type: "VALUE",
					x: getNodeX(),
					y: getNodeY(),
					color: 0xffb34f5a,
					inputs: [],
					outputs: [
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Value",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 0.5
						}
					],
					buttons: [
						{
							name: "default_value",
							type: "VALUE",
							output: 0,
							min: 0.0,
							max: 10.0
						}
					]
				};
				canvas.nodes.push(n);
				uinodes.nodeDrag = n;
				uinodes.nodeSelected = n;
			}
			if (ui.button("Checker Texture")) {
				var node_id = uinodes.getNodeId(canvas.nodes);
				var n:TNode = {
					id: node_id,
					name: "Checker Texture",
					type: "TEX_CHECKER",
					x: getNodeX(),
					y: getNodeY(),
					color: 0xff4982a0,
					inputs: [
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Vector",
							type: "VECTOR",
							color: 0xff6363c7,
							default_value: [0.0, 0.0, 0.0]
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Color 1",
							type: "RGB",
							color: 0xffc7c729,
							default_value: [0.8, 0.8, 0.8]
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Color 2",
							type: "RGB",
							color: 0xffc7c729,
							default_value: [0.2, 0.2, 0.2]
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Scale",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 5.0
						}
					],
					outputs: [
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Color",
							type: "RGBA",
							color: 0xffc7c729,
							default_value: [0.8, 0.8, 0.8]
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Fac",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 1.0
						}
					],
					buttons: []
				};
				canvas.nodes.push(n);
				uinodes.nodeDrag = n;
				uinodes.nodeSelected = n;
			}
			if (ui.button("Gradient Texture")) {
				var node_id = uinodes.getNodeId(canvas.nodes);
				var n:TNode = {
					id: node_id,
					name: "Gradient Texture",
					type: "TEX_GRADIENT",
					x: getNodeX(),
					y: getNodeY(),
					color: 0xff4982a0,
					inputs: [
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Vector",
							type: "VECTOR",
							color: 0xff6363c7,
							default_value: [0.0, 0.0, 0.0]
						}
					],
					outputs: [
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Color",
							type: "RGBA",
							color: 0xffc7c729,
							default_value: [0.8, 0.8, 0.8]
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Fac",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 1.0
						}
					],
					buttons: [
						{
							name: "gradient_type",
							type: "ENUM",
							// data: ["Linear", "Quadratic", "Easing", "Diagonal", "Radial", "Quadratic Sphere", "Spherical"],
							data: ["Linear", "Diagonal", "Radial", "Spherical"],
							default_value: 0,
							output: 0
						}
					]
				};
				canvas.nodes.push(n);
				uinodes.nodeDrag = n;
				uinodes.nodeSelected = n;
			}
			if (ui.button("Noise Texture")) {
				var node_id = uinodes.getNodeId(canvas.nodes);
				var n:TNode = {
					id: node_id,
					name: "Noise Texture",
					type: "TEX_NOISE",
					x: getNodeX(),
					y: getNodeY(),
					color: 0xff4982a0,
					inputs: [
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Vector",
							type: "VECTOR",
							color: 0xff6363c7,
							default_value: [0.0, 0.0, 0.0]
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Scale",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 5.0
						}
					],
					outputs: [
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Color",
							type: "RGBA",
							color: 0xffc7c729,
							default_value: [0.8, 0.8, 0.8]
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Fac",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 1.0
						}
					],
					buttons: []
				};
				canvas.nodes.push(n);
				uinodes.nodeDrag = n;
				uinodes.nodeSelected = n;
			}
			if (ui.button("Voronoi Texture")) {
				var node_id = uinodes.getNodeId(canvas.nodes);
				var n:TNode = {
					id: node_id,
					name: "Voronoi Texture",
					type: "TEX_VORONOI",
					x: getNodeX(),
					y: getNodeY(),
					color: 0xff4982a0,
					inputs: [
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Vector",
							type: "VECTOR",
							color: 0xff6363c7,
							default_value: [0.0, 0.0, 0.0]
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Scale",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 5.0
						}
					],
					outputs: [
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Color",
							type: "RGBA",
							color: 0xffc7c729,
							default_value: [0.8, 0.8, 0.8]
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Fac",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 1.0
						}
					],
					buttons: [
						{
							name: "coloring",
							type: "ENUM",
							data: ["Intensity", "Cells"],
							default_value: 0,
							output: 0
						}
					]
				};
				canvas.nodes.push(n);
				uinodes.nodeDrag = n;
				uinodes.nodeSelected = n;
			}
			if (ui.button("BrightContrast")) {
				var node_id = uinodes.getNodeId(canvas.nodes);
				var n:TNode = {
					id: node_id,
					name: "BrightContrast",
					type: "BRIGHTCONTRAST",
					x: getNodeX(),
					y: getNodeY(),
					color: 0xff4982a0,
					inputs: [
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Color",
							type: "RGBA",
							color: 0xffc7c729,
							default_value: [0.8, 0.8, 0.8]
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Bright",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 0.0
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Contrast",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 0.0
						}
					],
					outputs: [
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Color",
							type: "RGBA",
							color: 0xffc7c729,
							default_value: [0.8, 0.8, 0.8]
						}
					],
					buttons: []
				};
				canvas.nodes.push(n);
				uinodes.nodeDrag = n;
				uinodes.nodeSelected = n;
			}
			if (ui.button("Gamma")) {
				var node_id = uinodes.getNodeId(canvas.nodes);
				var n:TNode = {
					id: node_id,
					name: "Gamma",
					type: "GAMMA",
					x: getNodeX(),
					y: getNodeY(),
					color: 0xff4982a0,
					inputs: [
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Color",
							type: "RGBA",
							color: 0xffc7c729,
							default_value: [0.8, 0.8, 0.8]
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Gamma",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 1.0
						}
					],
					outputs: [
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Color",
							type: "RGBA",
							color: 0xffc7c729,
							default_value: [0.8, 0.8, 0.8]
						}
					],
					buttons: []
				};
				canvas.nodes.push(n);
				uinodes.nodeDrag = n;
				uinodes.nodeSelected = n;
			}
			if (ui.button("HueSatVal")) {
				var node_id = uinodes.getNodeId(canvas.nodes);
				var n:TNode = {
					id: node_id,
					name: "HueSatVal",
					type: "HUE_SAT",
					x: getNodeX(),
					y: getNodeY(),
					color: 0xff4982a0,
					inputs: [
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Hue",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 0.5
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Sat",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 1.0
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Val",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 1.0
						}
					],
					outputs: [
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Color",
							type: "RGBA",
							color: 0xffc7c729,
							default_value: [0.8, 0.8, 0.8]
						}
					],
					buttons: []
				};
				canvas.nodes.push(n);
				uinodes.nodeDrag = n;
				uinodes.nodeSelected = n;
			}
			if (ui.button("Invert")) {
				var node_id = uinodes.getNodeId(canvas.nodes);
				var n:TNode = {
					id: node_id,
					name: "Invert",
					type: "INVERT",
					x: getNodeX(),
					y: getNodeY(),
					color: 0xff4982a0,
					inputs: [
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Fac",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 0.5
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Color",
							type: "RGBA",
							color: 0xffc7c729,
							default_value: [0.8, 0.8, 0.8]
						}
					],
					outputs: [
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Color",
							type: "RGBA",
							color: 0xffc7c729,
							default_value: [0.8, 0.8, 0.8]
						}
					],
					buttons: []
				};
				canvas.nodes.push(n);
				uinodes.nodeDrag = n;
				uinodes.nodeSelected = n;
			}
			if (ui.button("Combine RGB")) {
				var node_id = uinodes.getNodeId(canvas.nodes);
				var n:TNode = {
					id: node_id,
					name: "Combine RGB",
					type: "COMBRGB",
					x: getNodeX(),
					y: getNodeY(),
					color: 0xff4982a0,
					inputs: [
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "R",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 0.0
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "G",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 0.0
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "B",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 0.0
						}
					],
					outputs: [
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Color",
							type: "RGBA",
							color: 0xffc7c729,
							default_value: [0.8, 0.8, 0.8]
						}
					],
					buttons: []
				};
				canvas.nodes.push(n);
				uinodes.nodeDrag = n;
				uinodes.nodeSelected = n;
			}
			if (ui.button("MixRGB")) {
				var node_id = uinodes.getNodeId(canvas.nodes);
				var n:TNode = {
					id: node_id,
					name: "MixRGB",
					type: "MIX_RGB",
					x: getNodeX(),
					y: getNodeY(),
					color: 0xff4982a0,
					inputs: [
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Fac",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 0.5
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Color1",
							type: "RGBA",
							color: 0xffc7c729,
							default_value: [0.5, 0.5, 0.5]
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Color2",
							type: "RGBA",
							color: 0xffc7c729,
							default_value: [0.5, 0.5, 0.5]
						}
					],
					outputs: [
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "Color",
							type: "RGBA",
							color: 0xffc7c729,
							default_value: [0.8, 0.8, 0.8]
						}
					],
					buttons: [
						{
							name: "blend_type",
							type: "ENUM",
							data: ["Mix", "Add", "Multiply", "Subtract", "Screen", "Divide", "Difference", "Darken", "Lighten", "Soft Light"],
							default_value: 0,
							output: 0
						},
						{
							name: "use_clamp",
							type: "BOOL",
							default_value: "false",
							output: 0
						}
					]
				};
				canvas.nodes.push(n);
				uinodes.nodeDrag = n;
				uinodes.nodeSelected = n;
			}
			if (ui.button("Camera Data")) {
				var node_id = uinodes.getNodeId(canvas.nodes);
				var n:TNode = {
					id: node_id,
					name: "Camera Data",
					type: "CAMERA",
					x: getNodeX(),
					y: getNodeY(),
					color: 0xff4982a0,
					inputs: [],
					outputs: [
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "View Vector",
							type: "VECTOR",
							color: 0xff6363c7,
							default_value: [0.0, 0.0, 0.0]
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "View Z Depth",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 0.0
						},
						{
							id: uinodes.getSocketId(canvas.nodes),
							node_id: node_id,
							name: "View Distance",
							type: "VALUE",
							color: 0xffa1a1a1,
							default_value: 0.0
						}
					],
					buttons: []
				};
				canvas.nodes.push(n);
				uinodes.nodeDrag = n;
				uinodes.nodeSelected = n;
			}
			if (ui.button("Image Texture")) {
				createImageTexture();
			}

			ui.endLayout();
		}

		ui.end();

		g.begin(false);

		if (showMenu) {
			showMenu = false;
			drawMenu = true;
			
		}
		if (hideMenu) {
			hideMenu = false;
			drawMenu = false;
		}
	}

	function make_mesh(data:ShaderData, matcon:TMaterialContext):armory.system.ShaderContext {
		var context_id = 'mesh';
		var con_mesh:armory.system.ShaderContext = data.add_context({
			name: context_id,
			depth_write: true,
			compare_mode: 'less',
			// cull_mode: 'clockwise' });
			cull_mode: 'none' });

		var vert = con_mesh.make_vert();
		var frag = con_mesh.make_frag();

		
		frag.ins = vert.outs;
		vert.add_uniform('mat3 N', '_normalMatrix');
		vert.add_uniform('mat4 WVP', '_worldViewProjectionMatrix');
		vert.write('gl_Position = WVP * vec4(pos, 1.0);');
		
		con_mesh.add_elem('tex', 2);
		vert.add_out('vec2 texCoord');
		vert.write('texCoord = tex;');

		vert.add_out('vec3 wnormal');
		vert.write('wnormal = normalize(N * nor);');
		frag.write_main_header('vec3 n = normalize(wnormal);');

		vert.add_out('vec3 wposition');
		vert.add_uniform('mat4 W', '_worldMatrix');
        vert.write_pre = true;
        vert.write('wposition = vec4(W * vec4(pos, 1.0)).xyz;');
        vert.write_pre = false;
		vert.add_out('vec3 eyeDir');
		vert.add_uniform('vec3 eye', '_cameraPosition');
		vert.write('eyeDir = eye - wposition;');
		frag.prepend('vec3 vVec = normalize(eyeDir);');

		var sout = Cycles.parse(canvas, con_mesh, vert, frag, null, null, null, matcon);
		var base = sout.out_basecol;
		var rough = sout.out_roughness;
		var met = sout.out_metallic;
		var occ = sout.out_occlusion;
		frag.write('vec3 basecol = $base;');
		frag.write('float roughness = $rough;');
		frag.write('float metallic = $met;');
		frag.write('float occlusion = $occ;');

		frag.write_header('vec2 octahedronWrap(const vec2 v) {return (1.0 - abs(v.yx)) * (vec2(v.x >= 0.0 ? 1.0 : -1.0, v.y >= 0.0 ? 1.0 : -1.0));}');
		frag.write_header('float packFloat(const float f1, const float f2) {float index = floor(f1 * 100.0); float alpha = clamp(f2, 0.0, 1.0 - 0.001);return index + alpha;}');

		frag.write('n /= (abs(n.x) + abs(n.y) + abs(n.z));');
		frag.write('n.xy = n.z >= 0.0 ? n.xy : octahedronWrap(n.xy);');

		frag.add_out('vec4[2] fragColor');
		frag.write('fragColor[0] = vec4(n.xy, packFloat(metallic, roughness), 1.0 - gl_FragCoord.z);');
		frag.write('fragColor[1] = vec4(basecol.rgb, occlusion);');

		con_mesh.data.shader_from_source = true;
		con_mesh.data.vertex_shader = vert.get();
		con_mesh.data.fragment_shader = frag.get();

		return con_mesh;
	}

	// function make_depth(data:ShaderData):armory.system.ShaderContext {
	// 	var context_id = 'depth';
	// 	var con_depth:armory.system.ShaderContext = data.add_context({
	// 		name: context_id,
	// 		depth_write: true,
	// 		compare_mode: 'less',
	// 		cull_mode: 'clockwise',
	// 		color_write_red: false,
	// 		color_write_green: false,
	// 		color_write_blue: false,
	// 		color_write_alpha: false });

	// 	var vert = con_depth.make_vert();
	// 	var frag = con_depth.make_frag();

		
	// 	frag.ins = vert.outs;
	// 	vert.add_uniform('mat4 WVP', '_worldViewProjectionMatrix');
	// 	vert.write('gl_Position = WVP * vec4(pos, 1.0);');

	// 	con_depth.data.shader_from_source = true;
	// 	con_depth.data.vertex_shader = vert.get();
	// 	con_depth.data.fragment_shader = frag.get();

	// 	return con_depth;
	// }


	function parseMaterial() {
		UITrait.dirty = true;

		var mout = false;
		for (n in canvas.nodes) if (n.type == "OUTPUT_MATERIAL_PBR") { mout = true; break; }

		if (mout) {

			iron.data.Data.getMaterial("Scene", "Material", function(m:iron.data.MaterialData) {

				var mat:TMaterial = {
					name: "Material",
					canvas: canvas
				};
				var _sd = new ShaderData(mat);
				
				if (sc == null) {
					for (c in m.shader.contexts) {
						if (c.raw.name == "mesh") {
							sc = c;
							break;
						}
					}
				}
				if (_materialcontext == null) {
					for (c in m.contexts) {
						if (c.raw.name == "mesh") {
							_materialcontext = c;
							_matcon = c.raw;
							break;
						}
					}
				}

				m.shader.raw.contexts.remove(sc.raw);
				m.shader.contexts.remove(sc);
				m.raw.contexts.remove(_matcon);
				m.contexts.remove(_materialcontext);

				_matcon = {
					name: "mesh",
					bind_textures: []
				}

				var con = make_mesh(_sd, _matcon);
				var cdata = con.data;

				// if (sc == null) {
					// from_source is synchronous..
					sc = new iron.data.ShaderData.ShaderContext(cdata, null, function(sc:iron.data.ShaderData.ShaderContext){});
					m.shader.raw.contexts.push(sc.raw);
					m.shader.contexts.push(sc);
					m.raw.contexts.push(_matcon);

					new MaterialContext(_matcon, function(self:MaterialContext) {
						_materialcontext = self;
						m.contexts.push(self);
					});

					// var dcon = make_depth(_sd);
					// var dcdata = dcon.data;

					// // from_source is synchronous..
					// var dsc = new iron.data.ShaderData.ShaderContext(dcdata, null, function(sc:iron.data.ShaderData.ShaderContext){});
					// m.shader.contexts.push(dsc);

					// var dmatcon:TMaterialContext = {
					// 	name: "depth"
					// }
					// m.raw.contexts.push(dmatcon);

					// new MaterialContext(dmatcon, function(self:MaterialContext) {
					// 	m.contexts.push(self);
					// });
			});
		}
	}

	public function createImageTexture() {
		var node_id = uinodes.getNodeId(canvas.nodes);
		var n:TNode = {
			id: node_id,
			name: "Image Texture",
			type: "TEX_IMAGE",
			x: getNodeX(),
			y: getNodeY(),
			color: 0xff4982a0,
			inputs: [
				{
					id: uinodes.getSocketId(canvas.nodes),
					node_id: node_id,
					name: "Vector",
					type: "VECTOR",
					color: 0xff6363c7,
					default_value: [0.0, 0.0, 0.0]
				}
			],
			outputs: [
				{
					id: uinodes.getSocketId(canvas.nodes),
					node_id: node_id,
					name: "Color",
					type: "RGBA",
					color: 0xffc7c729,
					default_value: ""
				},
				{
					id: uinodes.getSocketId(canvas.nodes),
					node_id: node_id,
					name: "Alpha",
					type: "VALUE",
					color: 0xffa1a1a1,
					default_value: 1.0
				}
			],
			buttons: [
				{
					name: "default_value",
					type: "ENUM",
					default_value: 0,
					output: 0
				}
			]
		};
		canvas.nodes.push(n);
		uinodes.nodeDrag = n;
		uinodes.nodeSelected = n;
	}

	public static function acceptDrag(assetIndex:Int) {
		inst.createImageTexture();
		uinodes.nodeSelected.buttons[0].default_value = assetIndex;
	}
}

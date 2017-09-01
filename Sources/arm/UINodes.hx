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

	public static var ww = 0;
	public static var wh = 0;
	public static var wx = 0;
	public static var wy = 0;

	var ui:Zui;
	var drawMenu = false;
	var showMenu = false;
	var hideMenu = false;
	var menuCategory = 0;
	var addNodeButton = false;
	var popupX = 0.0;
	var popupY = 0.0;

	var sc:iron.data.ShaderData.ShaderContext = null;
	public var _matcon:TMaterialContext = null;
	public var _materialcontext:MaterialContext = null;

	static var font:kha.Font;

	static var lastLayout = -1;
	public static function calcLayout() {		
		
		if (arm.App.layout == 0) {
			UINodes.wx = 0;
			UINodes.wh = 300;
			UINodes.wy = arm.App.realh() - UINodes.wh;
			UINodes.ww = arm.App.realw() - UITrait.ww;
			if (lastLayout != arm.App.layout) { nodes.panX += 300; nodes.panY -= 200; }
		}
		else {
			UINodes.wx = Std.int((arm.App.realw() - UITrait.ww) / 2);
			UINodes.wh = arm.App.realh();
			UINodes.wy = 0;
			UINodes.ww = Std.int((arm.App.realw() - UITrait.ww) / 2);
			if (lastLayout != arm.App.layout) { nodes.panX -= 300; nodes.panY += 200; }
		}

		lastLayout = arm.App.layout;
	}

	public function new() {
		super();
		inst = this;
		calcLayout();

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
	static var frame = 0;
	var mdown = false;
	var mreleased = false;
	var mchanged = false;
	var changed = false;
	function update() {
		if (frame == 8) parseMaterial(); // Temp cpp fix
		frame++;

		//
		var mouse = iron.system.Input.getMouse();
		mreleased = mouse.released();
		mdown = mouse.down();

		if (ui.changed) {
			mchanged = true;
			if (!mdown) changed = true;
		}
		if ((mreleased && mchanged) || changed) {
			mchanged = changed = false;
			parseMaterial();
		}
		//

		if (!show) return;
		if (!UITrait.uienabled) return;
		var keyboard = iron.system.Input.getKeyboard();

		if (mouse.x < wx || mouse.x > wx + ww || mouse.y < wy) return;

		if (ui.isTyping) return;

		if (mouse.started("right")) {
			mx = mouse.x;
			my = mouse.y;
		}
		else if (addNodeButton) {
			showMenu = true;
			addNodeButton = false;
		}
		else if (mouse.released()) {
			hideMenu = true;
		}

		if (keyboard.started("x")) {
			nodes.removeNode(nodes.nodeSelected, canvas);
			changed = true;
		}

		if (keyboard.started("p")) {
			trace(haxe.Json.stringify(canvas));
		}
	}

	static var nodes = new Nodes();
	static var canvas:TNodeCanvas = null;
	public static var grid:kha.Image = null;

	function getNodeX():Int {
		var mouse = iron.system.Input.getMouse();
		return Std.int((mouse.x - wx - nodes.PAN_X()) / nodes.SCALE);
	}

	function getNodeY():Int {
		var mouse = iron.system.Input.getMouse();
		return Std.int((mouse.y - wy - nodes.PAN_Y()) / nodes.SCALE);
	}

	public function drawGrid() {
		var w = ww + 40 * 2;
		var h = wh + 40 * 2;
		grid = kha.Image.createRenderTarget(w, h);
		grid.g2.begin(true, 0xff141414);
		for (i in 0...Std.int(h / 40) + 1) {
			grid.g2.color = 0xff303030;
			grid.g2.drawLine(0, i * 40, w, i * 40);
			grid.g2.color = 0xff202020;
			grid.g2.drawLine(0, i * 40 + 20, w, i * 40 + 20);
		}
		for (i in 0...Std.int(w / 40) + 1) {
			grid.g2.color = 0xff303030;
			grid.g2.drawLine(i * 40, 0, i * 40, h);
			grid.g2.color = 0xff202020;
			grid.g2.drawLine(i * 40 + 20, 0, i * 40 + 20, h);
		}
		grid.g2.end();
	}

	@:access(zui.Zui)
	function render2D(g:kha.graphics2.Graphics) {
		if (!show) return;
		
		if (!UITrait.uienabled && ui.inputRegistered) ui.unregisterInput();
		if (UITrait.uienabled && !ui.inputRegistered) ui.registerInput();

		g.end();

		if (grid == null) drawGrid();

		// Start with UI
		ui.begin(g);
		// ui.begin(rt.g2); ////
		
		// Make window
		var hwin = Id.handle();
		if (ui.window(hwin, wx, wy, ww, wh)) {
		// if (ui.window(hwin, 0, 0, rt.width, rt.height)) { ////

			ui.g.color = 0xffffffff;
			ui.g.drawImage(grid, (nodes.panX * nodes.SCALE) % 40 - 40, (nodes.panY * nodes.SCALE) % 40 - 40);

			ui.g.font = font;
			ui.g.fontSize = 42;
			var title = "Material";
			// var title = "Material (right-click to add node)";
			var titlew = ui.g.font.width(42, title);
			var titleh = ui.g.font.height(42);
			ui.g.drawString(title, ww - titlew - 20, wh - titleh - 10);

			// Recompile material on change
			ui.changed = false;
			nodes.nodeCanvas(ui, canvas);

			ui.g.color = 0xff111111;
			ui.g.fillRect(0, 0, ww, 24);
			ui.g.color = 0xffffffff;

			ui._x = 3;
			ui._y = 3;
			ui._w = 105;
			if (ui.button("Input")) { addNodeButton = true; menuCategory = 0; popupX = wx + ui._x; popupY = wy + ui._y; }
			ui._x += 105 + 3;
			ui._y = 3;
			if (ui.button("Output")) { addNodeButton = true; menuCategory = 1; popupX = wx + ui._x; popupY = wy + ui._y; }
			ui._x += 105 + 3;
			ui._y = 3;
			if (ui.button("Texture")) { addNodeButton = true; menuCategory = 2; popupX = wx + ui._x; popupY = wy + ui._y; }
			ui._x += 105 + 3;
			ui._y = 3;
			if (ui.button("Color")) { addNodeButton = true; menuCategory = 3; popupX = wx + ui._x; popupY = wy + ui._y; }
			ui._x += 105 + 3;
			ui._y = 3;
			if (ui.button("Converter")) { addNodeButton = true; menuCategory = 4; popupX = wx + ui._x; popupY = wy + ui._y; }
		}

		ui.endWindow();

		if (drawMenu) {
			
			var ph = NodeCreator.numNodes[menuCategory] * 20;
			var py = popupY;
			g.color = 0xff222222;
			g.fillRect(popupX, py, 105, ph);

			ui.beginLayout(g, Std.int(popupX), Std.int(py), 105);
			
			NodeCreator.draw(this, menuCategory);

			ui.endLayout();
		}

		if (showMenu) {
			showMenu = false;
			drawMenu = true;
			
		}
		if (hideMenu) {
			hideMenu = false;
			drawMenu = false;
		}

		ui.end();

		g.begin(false);
	}

	function make_base(matcon:TMaterialContext, con_mesh:armory.system.ShaderContext, vert:armory.system.Shader, frag:armory.system.Shader) {
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

		frag.prepend('float dotNV = max(dot(n, vVec), 0.0);');
		frag.prepend('vec3 vVec = normalize(eyeDir);');

		vert.add_out('vec3 mposition');
        vert.write_pre = true;
        vert.write('mposition = pos.xyz;');
        vert.write_pre = false;

		var sout = Cycles.parse(canvas, con_mesh, vert, frag, null, null, null, matcon);
		var base = sout.out_basecol;
		var rough = sout.out_roughness;
		var met = sout.out_metallic;
		var occ = sout.out_occlusion;
		var opac = sout.out_opacity;
		frag.write('vec3 basecol = $base;');
		frag.write('float roughness = $rough;');
		frag.write('float metallic = $met;');
		frag.write('float occlusion = $occ;');
		frag.write('float opacity = $opac;');
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

		make_base(matcon, con_mesh, vert, frag);

		//if discard_transparent:
        	var opac = 0.3;//mat_state.material.discard_transparent_opacity
        	frag.write('if (opacity < $opac) discard;');

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

	public function make_export():iron.data.ShaderData.ShaderContext {
		
		if (!getMOut()) return null;

		var mat:TMaterial = {
			name: "Material",
			canvas: canvas
		};
		var data = new ShaderData(mat);

		var matcon:TMaterialContext = {
			name: "mesh",
			bind_textures: []
		}

		var con_mesh:armory.system.ShaderContext = data.add_context({
			name: 'mesh',
			depth_write: false,
			compare_mode: 'always',
			cull_mode: 'none' });

		var vert = con_mesh.make_vert();
		var frag = con_mesh.make_frag();

		make_base(matcon, con_mesh, vert, frag);

		vert.write('vec2 tpos = vec2(tex.x * 2.0 - 1.0, tex.y * 2.0 - 1.0);');
		vert.write('gl_Position = vec4(tpos, 0.0, 1.0);');

		frag.add_out('vec4[3] fragColor');
		frag.write('fragColor[0] = vec4(pow(basecol.rgb, vec3(1.0 / 2.2)), occlusion);');
		frag.write('fragColor[1] = vec4(roughness, metallic, 0.0, 1.0);');
		if (frag.contains("vec3 texn")) {
			frag.write('fragColor[2] = vec4(texn.rgb * 0.5 + 0.5, 1.0);');
		}
		else {
			frag.write('fragColor[2] = vec4(0.5, 0.5, 1.0, 1.0);');
		}

		con_mesh.data.shader_from_source = true;
		con_mesh.data.vertex_shader = vert.get();
		con_mesh.data.fragment_shader = frag.get();

		var sc = new iron.data.ShaderData.ShaderContext(con_mesh.data, null, function(sc:iron.data.ShaderData.ShaderContext){});
		return sc;
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

	function getMOut():Bool {
		for (n in canvas.nodes) if (n.type == "OUTPUT_MATERIAL_PBR") return true;
		return false;
	}

	function parseMaterial() {
		UITrait.dirty = true;

		if (getMOut()) {

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

	public static function acceptDrag(assetIndex:Int) {
		NodeCreator.createImageTexture(inst);
		nodes.nodeSelected.buttons[0].default_value = assetIndex;
	}
}

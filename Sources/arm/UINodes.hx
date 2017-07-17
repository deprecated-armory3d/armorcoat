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
	public var _materialcontext:MaterialContext = null;

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
			nodes.removeNode(nodes.nodeSelected, canvas);
			changed = true;
		}

		if (keyboard.started("p")) {
			trace(haxe.Json.stringify(canvas));
		}
	}

	static var nodes = new Nodes();

	static var canvas:TNodeCanvas = null;

	static var bg:kha.Image = null;

	function getNodeX():Int {
		var mouse = iron.system.Input.getMouse();
		return Std.int((mouse.x - wx - nodes.PAN_X()) / nodes.SCALE);
	}

	function getNodeY():Int {
		var mouse = iron.system.Input.getMouse();
		return Std.int((mouse.y - wy - nodes.PAN_Y()) / nodes.SCALE);
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
			nodes.nodeCanvas(ui, canvas);
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
			
			NodeCreator.draw(this);

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
			frag.write('fragColor[2] = vec4(texn.rgb, 1.0);');
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

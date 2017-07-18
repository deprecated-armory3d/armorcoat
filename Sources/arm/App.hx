package arm;

class App {

	public static var layout = 1; // Hor, ver

	public static function w():Int {
		var ww = UINodes.ww;
		if (ww == 0) ww = Std.int((arm.App.realw() - UITrait.ww) / 2);
		if (layout == 0) return kha.System.windowWidth() - UITrait.ww;
		else return kha.System.windowWidth() - UITrait.ww - ww;
	}

	public static function h():Int {
		var wh = UINodes.wh;
		if (wh == 0) wh = arm.App.realh();
		if (layout == 0) return kha.System.windowHeight() - wh;
		else return kha.System.windowHeight();
	}

	public static function realw():Int {
		return kha.System.windowWidth();
	}

	public static function realh():Int {
		return kha.System.windowHeight();
	}
}

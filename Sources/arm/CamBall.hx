package arm;

import iron.object.Object;
import iron.Trait;
import iron.system.Input;
import iron.math.Vec4;
import iron.math.Quat;

@:keep
class CamBall extends Trait {

	public static var moved = false;

	public function new() {
		super();

		notifyOnUpdate(update);
	}

	function update() {
		if (Input.occupied) return;
		if (!UITrait.uienabled) return;
		if (UITrait.isScrolling) return;
		if (UITrait.isDragging) return;
		if (UITrait.cameraType != 0) return;
		if (!object.visible) return;

		var mouse = Input.getMouse();

		if (mouse.x > arm.App.realw() - UITrait.ww) return;
		if (UINodes.show && mouse.x > UINodes.wx && mouse.x < UINodes.wx + UINodes.ww && mouse.y > UINodes.wy && mouse.y < UINodes.wy + UINodes.wh) return;

		if (mouse.down("left")) {
			UITrait.dirty = true;
			
			// Rotate
			object.transform.rotate(new Vec4(0, 0, 1), mouse.movementX / 100);
			object.transform.buildMatrix();
			object.transform.rotate(object.transform.world.right(), mouse.movementY / 100);
			object.transform.buildMatrix();
		}
	}
}

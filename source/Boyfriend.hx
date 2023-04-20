package;

using StringTools;

class Boyfriend extends Character
{
	public var startedDeath:Bool = false;

	public function new(x:Float, y:Float, ?char:String = 'bf'):Void
	{
		super(x, y, char, true);
	}

	public override function update(elapsed:Float):Void
	{
		if (!debugMode && animation.curAnim != null)
		{
			if (animation.curAnim.name.startsWith('sing')) {
				holdTimer += elapsed;
			}
			else {
				holdTimer = 0;
			}

			if (animation.curAnim.name.endsWith('miss') && animation.curAnim.finished && !debugMode) {
				playAnim('idle', true, false, 10);
			}
		}

		super.update(elapsed);
	}
}
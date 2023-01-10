package;

class RatingData
{
	public var name:String = '';
	public var image:String = '';
	public var counter:String = '';

	public var hitWindow(get, null):Null<Int> = 0; //ms
	public var ratingMod:Float = 1;

	public var score:Int = 350;

	public var noteSplash:Bool = true;

	public function new(name:String):Void
	{
		this.name = name;
		this.image = name;
		this.counter = name + 's';

		if (hitWindow == null) {
			hitWindow = 0;
		}
	}

	public function get_hitWindow():Null<Int>
	{
		return Reflect.getProperty(OptionData, name + 'Window');
	}

	public function increase(blah:Int = 1):Void
	{
		Reflect.setProperty(PlayState.instance, counter, Reflect.field(PlayState.instance, counter) + blah);
	}
}
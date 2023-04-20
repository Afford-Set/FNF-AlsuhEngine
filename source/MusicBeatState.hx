package;

import Conductor;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;

using StringTools;

class MusicBeatState extends FlxState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep(default, null):Int = 0;
	private var curBeat(default, null):Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;

	public var controls(get, never):Controls;
	private function get_controls():Controls return Controls.instance;

	public static var camBeat:FlxCamera;

	public override function create():Void
	{
		camBeat = FlxG.camera;
		var skip:Bool = FlxTransitionableState.skipNextTransOut;

		super.create();

		if (!skip) {
			openSubState(new CustomFadeTransition(0.7, true));
		}

		FlxTransitionableState.skipNextTransOut = false;
	}

	#if !mobile
	var skippedFrames:Int = 0;
	var skippedFrames2:Int = 0;
	#end

	public override function update(elapsed:Float):Void
	{
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if (curStep > 0) {
				stepHit();
			}

			if (PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		super.update(elapsed);
	}

	private function updateSection():Void
	{
		if (stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);

		while (curStep >= stepsToDo)
		{
			curSection++;

			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);

			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if (curStep < 0) return;

		var lastSection:Int = curSection;

		curSection = 0;
		stepsToDo = 0;

		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if (stepsToDo > curStep) break;
				
				curSection++;
			}
		}

		if (curSection > lastSection) sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	private function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit:Float = ((Conductor.songPosition - OptionData.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	var exiting:Bool = false;

	public override function switchTo(nextState:FlxState):Bool
	{
		if (!FlxTransitionableState.skipNextTransIn)
		{
			if (!exiting)
			{
				openSubState(new CustomFadeTransition(0.6, false, function():Void
				{
					exiting = true;
					FlxG.switchState(nextState);
				}));
			}

			return exiting;
		}

		FlxTransitionableState.skipNextTransIn = false;
		return true;
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0) {
			beatHit();
		}
	}

	public function beatHit():Void
	{
		// do literally nothing dumbass
	}

	public function sectionHit():Void
	{
		// do literally nothing dumbass
	}

	function getBeatsOnSection():Float
	{
		#if hl
		var val:Null<Float> = null;

		if (PlayState.SONG == null && PlayState.SONG.notes[curSection] == null) {
			val = 4;
		}
		else {
			val = PlayState.SONG.notes[curSection].sectionBeats;
		}
		return
		#else
		var val:Null<Float> = PlayState.SONG != null && PlayState.SONG.notes[curSection] != null ? PlayState.SONG.notes[curSection].sectionBeats : 4;
		#end

		return val #if !hl == null ? 4 : val #end;
	}
}
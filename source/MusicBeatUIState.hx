package;

import Conductor;
import flixel.addons.ui.FlxUIState;

using StringTools;

class MusicBeatUIState extends FlxUIState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep(default, null):Int = 0;
	private var curBeat(default, null):Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;

	public override function create():Void
	{
		super.create();
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

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

	function getBeatsOnSection()
	{
		var val:Null<Float> = PlayState.SONG != null && PlayState.SONG.notes[curSection] != null ? PlayState.SONG.notes[curSection].sectionBeats : 4;

		return val == null ? 4 : val;
	}
}

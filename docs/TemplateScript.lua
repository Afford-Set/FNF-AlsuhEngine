-- Lua stuff

local allowStart = false;

function onStart(allowPlayCutscene)
	-- this function is very simple, it is more similar to onStartCountdown
	-- with this you can enable cut-scenes

	-- Example:

	-- for dialogue cutscenes:
	--[[
			if allowPlayCutscene and not allowStart then
				runTimer('startDialogue', 0.8);
				setProperty('inCutscene', true);
				allowStart = true;
				return Function_Stop;
			end
			return Function_Continue;
	-- ]]

	-- for mp4 cutscenes:
	--[[
			if allowPlayCutscene and not allowStart then
				startVideo('your-video', 'mp4');
				setProperty('inCutscene', true);
				allowStart = true;
				return Function_Stop;
			end
			return Function_Continue;
	-- ]]

	-- for webm cutscenes:
	--[[
			if allowPlayCutscene and not allowStart then
				startVideo('your-video', 'webm');
				setProperty('inCutscene', true);
				allowStart = true;
				return Function_Stop;
			end
			return Function_Continue;
	-- ]]
end

function onLoadStage()
	-- triggered after loading stage's settings
end

function onLoadStagePost()
	-- end of "onLoadStage"
end

function onCreate()
	-- triggered when the lua file is started, some variables weren't created yet
end

function onCreatePost()
	-- end of "create"
end

function onLoadHUD()
	-- triggered when hud is loading
end

function onLoadHUDPost()
	-- end of "onLoadHUD"
end

function onDestroy()
	-- triggered when the lua file is ended (Song fade out finished)
end

-- Gameplay/Song interactions
function onBeatHit()
	-- triggered 4 times per section
end

function onStepHit()
	-- triggered 16 times per section
end

function onUpdate(elapsed)
	-- start of "update", some variables weren't updated yet
end

function onUpdatePost(elapsed)
	-- end of "update"
end

function onStartCountdown()
	-- this function is deprecated, use "onStart" instead

	-- countdown started, duh
	-- return Function_Stop if you want to stop the countdown from happening (Can be used to trigger dialogues and stuff! You can trigger the countdown with startCountdown())
	return Function_Continue;
end

function onCountdownTick(counter)
	-- counter = 0 -> "Three"
	-- counter = 1 -> "Two"
	-- counter = 2 -> "One"
	-- counter = 3 -> "Go!"
	-- counter = 4 -> Nothing happens lol, tho it is triggered at the same time as onSongStart i think
end

function onSongStart()
	-- Inst and Vocals start playing, songPosition = 0
end

local allowEnd = false;

function onEndSong(allowPlayCutscene)
	-- song ended/starting transition (Will be delayed if you're unlocking an achievement)
	-- return Function_Stop to stop the song from ending for playing a cutscene or something.

	-- with this you can enable cut-scenes

	-- Example:

	-- for dialogue cutscenes:
	--[[
			if allowPlayCutscene and not allowEnd then
				runTimer('startDialogue', 0.8);
				setProperty('inCutscene', true);
				allowEnd = true;
				return Function_Stop;
			end
			return Function_Continue;
	-- ]]

	-- for mp4 cutscenes:
	--[[
			if allowPlayCutscene and not allowEnd then
				startVideo('your-video', 'mp4');
				setProperty('inCutscene', true);
				allowEnd = true;
				return Function_Stop;
			end
			return Function_Continue;
	-- ]]

	-- for webm cutscenes:
	--[[
			if allowPlayCutscene and not allowEnd then
				startVideo('your-video', 'webm');
				setProperty('inCutscene', true);
				allowEnd = true;
				return Function_Stop;
			end
			return Function_Continue;
	-- ]]
end

function onEndSongPost(allowPlayCutscene)
	-- end of "onEndSong"
end

--[[
-- this caller is no more available lol
-- use onEndSong instead
function onEnd()
	return Function_Continue;
end
- ]]

-- Substate interactions
function onPause()
	-- Called when you press Pause while not on a cutscene/etc
	-- return Function_Stop if you want to stop the player from pausing the game
	return Function_Continue;
end

function onResume()
	-- Called after the game has been resumed from a pause (WARNING: Not necessarily from the pause screen, but most likely is!!!)
end

function onGameOver()
	-- You died! Called every single frame your health is lower (or equal to) zero
	-- return Function_Stop if you want to stop the player from going into the game over screen
	return Function_Continue;
end

function onGameOverConfirm(retry)
	-- Called when you Press Enter/Esc on Game Over
	-- If you've pressed Esc, value "retry" will be false
end


-- Dialogue (When a dialogue is finished, it calls startCountdown again)
function onNextDialogue(line)
	-- triggered when the next dialogue line starts, dialogue line starts with 1
end

function onSkipDialogue(line)
	-- triggered when you press Enter and skip a dialogue line that was still being typed, dialogue line starts with 1
end


-- Note miss/hit
function goodNoteHit(id, direction, noteType, isSustainNote)
	-- Function called when you hit a note (after note hit calculations)
	-- id: The note member id, you can get whatever variable you want from this note, example: "getPropertyFromGroup('notes', id, 'strumTime')"
	-- noteData: 0 = Left, 1 = Down, 2 = Up, 3 = Right
	-- noteType: The note type string/tag
	-- isSustainNote: If it's a hold note, can be either true or false
end

function onHitCauses(id, direction, noteType, isSustainNote)
	-- this is a function like "goodNoteHit", only enabled when an hit note, while its "hitCausesMiss" variable's value is true
end

function opponentNoteHit(id, direction, noteType, isSustainNote)
	-- Works the same as goodNoteHit, but for Opponent's notes being hit
end

function noteMissPress(direction)
	-- Called after the note press miss calculations
	-- Player pressed a button, but there was no note to hit (ghost miss)
end

function noteMiss(id, direction, noteType, isSustainNote)
	-- Called after the note miss calculations
	-- Player missed a note by letting it go offscreen
end


-- Other function hooks
function onRecalculateRating()
	-- return Function_Stop if you want to do your own rating calculation,
	-- use setRatingPercent() to set the number on the calculation and setRatingString() to set the funny rating name
	-- NOTE: THIS IS CALLED BEFORE THE CALCULATION!!!
	return Function_Continue;
end

function onMoveCamera(focus)
	if focus == 'boyfriend' then
		-- called when the camera focus on boyfriend
	elseif focus == 'dad' then
		-- called when the camera focus on dad
	else
		-- called when the camera focus on girlfriend
	end
end

-- Event notes hooks
function onEventPushed(name)
	-- event note precache
end

function onEvent(name, value1, value2)
	-- event note triggered
	-- triggerEvent() does not call this function!!

	-- print('Event triggered: ', name, value1, value2);
end

function eventEarlyTrigger(name)
	--[[
	Here's a port of the Kill Henchmen early trigger but on Lua instead of Haxe:

	if name == 'Kill Henchmen'
		return 280;

	This makes the "Kill Henchmen" event be triggered 280 miliseconds earlier so that the kill sound is perfectly timed with the song
	]]--

	-- write your shit under this line, the new return value will override the ones hardcoded on the engine
end

-- Tween/Timer/Sound/Animation hooks
function onTweenUpdate(tag, elapsed)
	-- A tween you called has been updated, value "tag" is it's tag
end

function onTweenCompleted(tag)
	-- A tween you called has been completed, value "tag" is it's tag
end

function onTimerCompleted(tag, loops, loopsLeft)
	-- A loop from a timer you called has been completed, value "tag" is it's tag
	-- loops = how many loops it will have done when it ends completely
	-- loopsLeft = how many are remaining

	-- Example:
	-- for dialogues:
	-- 		if tag == 'startDialogue' then -- Timer completed, play dialogue
	--			startDialogue('dialogue', '');
	--		end
end

function onSoundFinished(tag)
	-- A sound you called has been finished, value "tag" is it's tag
	-- WARNING: your sound needs a tag, without it this function will not be called
end

function onAnimationProgress(obj, name, frameNumber, frameIndex)
	-- A animation you played on progress
end

function onAnimationFinished(obj, name)
	-- A animation you played has been finished
end

function onFinishBGVideo(path)
	-- A current video you played has been finished, value "path" is it's current video's path
end

-- Any other shit
function onOpenChartEditor()
	-- Called when you press Debug Key 1 while not on a cutscene/etc
	-- return Function_Stop if you want to stop the player to go chart editor
	return Function_Continue;
end

function onOpenCharacterEditor()
	-- Called when you press Debug Key 2 while not on a cutscene/etc
	-- return Function_Stop if you want to stop the player to go character editor
	return Function_Continue;
end
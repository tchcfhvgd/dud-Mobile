package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.net.curl.CURLCode;
import flixel.graphics.FlxGraphic;
import flixel.FlxObject;
import flixel.util.FlxCollision;
import flixel.effects.FlxFlicker;
import flixel.addons.display.FlxBackdrop;
import WeekData;

using StringTools;

class StoryMenuState extends MusicBeatState
{
	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();

	var scoreText:FlxText;

	private static var lastDifficultyName:String = '';
	var curDifficulty:Int = 1;

	private static var curWeek:Int = 0;

	var txtTracklist:FlxText;

	var grpWeekText:FlxTypedGroup<MenuItem>;

	var grpLocks:FlxTypedGroup<FlxSprite>;

	var loadedWeeks:Array<WeekData> = [];

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var mouseobject:FlxSprite;

	public static var brutal = false;
	public static var diff = 1;
	var diffbg:FlxSprite;
	var easydiff:FlxSprite;
	var normaldiff:FlxSprite;
	var brutaldiff:FlxSprite;

	override function create()
	{
		FlxG.mouse.visible = true;
		
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		PlayState.isStoryMode = true;
		WeekData.reloadWeekFiles(true);
		if(curWeek >= WeekData.weeksList.length) curWeek = 0;
		persistentUpdate = persistentDraw = true;

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		mouseobject = new FlxSprite(0, 0).makeGraphic(1, 1, 0xFFFFFFFF);
		add(mouseobject);

		var bg:FlxSprite = new FlxSprite(-285, -142);
		bg.frames = Paths.getSparrowAtlas('menu/song select');
		bg.scrollFactor.set();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		bg.animation.addByPrefix('idle', 'bg', 24, false);
		bg.animation.play('idle');
		add(bg);

		var backdrop:FlxBackdrop;
		add(backdrop = new FlxBackdrop(Paths.image('menu/grid')));
		backdrop.scrollFactor.set(0.2, 0.2);
		backdrop.velocity.set(20, 20);

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);

		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);

		var top:FlxSprite = new FlxSprite(-295, -234);
		top.frames = Paths.getSparrowAtlas('menu/song select');
		top.scrollFactor.set(0.1, 0.1);
		top.antialiasing = ClientPrefs.globalAntialiasing;
		top.animation.addByPrefix('idle', 'top', 24, false);
		top.animation.play('idle');
		add(top);

		scoreText = new FlxText(20, 10, 0, "SCORE: 49324858", 36);
		scoreText.setFormat(Paths.font("phantommuff.ttf"), 32, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreText.borderSize = 1.25;
		scoreText.scrollFactor.set(0.05, 0.05);

		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		var num:Int = 0;
		for (i in 0...WeekData.weeksList.length)
		{
			var weekFile:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var isLocked:Bool = weekIsLocked(WeekData.weeksList[i]);
			if(!isLocked || !weekFile.hiddenUntilUnlocked)
			{
				loadedWeeks.push(weekFile);
				WeekData.setDirectoryFromWeek(weekFile);
				var weekThing:MenuItem = new MenuItem(0, 375, WeekData.weeksList[i]);
				weekThing.ID = i;
				weekThing.scrollFactor.set(0.05, 0.05);
				weekThing.y += ((weekThing.height + 50) * num);
				weekThing.targetY = num;
				grpWeekText.add(weekThing);

				weekThing.screenCenter(X);
				weekThing.antialiasing = ClientPrefs.globalAntialiasing;
				// weekThing.updateHitbox();

				// Needs an offset thingie
				if (isLocked)
				{
					var lock:FlxSprite = new FlxSprite(weekThing.width + 10 + weekThing.x);
					lock.frames = ui_tex;
					lock.animation.addByPrefix('lock', 'lock');
					lock.animation.play('lock');
					lock.ID = i;
					lock.antialiasing = ClientPrefs.globalAntialiasing;
					grpLocks.add(lock);
				}
				num++;
			}
		}

		WeekData.setDirectoryFromWeek(loadedWeeks[0]);

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		if(lastDifficultyName == '')
		{
			lastDifficultyName = CoolUtil.defaultDifficulty;
		}
		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));

		txtTracklist = new FlxText(FlxG.width * 0.05, 485, 0, "", 32);
		txtTracklist.setFormat(Paths.font("phantommuff.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		txtTracklist.borderSize = 1.25;
		txtTracklist.scrollFactor.set(0.05, 0.05);
		add(txtTracklist);
		add(scoreText);

		FlxG.camera.follow(camFollowPos, null, 1);
		camFollowPos.setPosition((FlxG.mouse.screenX + 720) / 2, ((FlxG.mouse.screenY + 1280) / 2) - 500);

		diffbg = new FlxSprite(899, 209).loadGraphic(Paths.image('menu/difficulty/bg'));
		diffbg.scrollFactor.set(0.05, 0.05);
		diffbg.screenCenter(Y);
		diffbg.antialiasing = ClientPrefs.globalAntialiasing;
		add(diffbg);

		easydiff = new FlxSprite(994, 230).loadGraphic(Paths.image('menu/difficulty/easy'));
		easydiff.scrollFactor.set(0.04, 0.04);
		easydiff.antialiasing = ClientPrefs.globalAntialiasing;
		add(easydiff);

		normaldiff = new FlxSprite(941, 328).loadGraphic(Paths.image('menu/difficulty/normal'));
		normaldiff.scrollFactor.set(0.04, 0.04);
		normaldiff.antialiasing = ClientPrefs.globalAntialiasing;
		add(normaldiff);

		brutaldiff = new FlxSprite(954, 426).loadGraphic(Paths.image('menu/difficulty/brutal'));
		brutaldiff.scrollFactor.set(0.04, 0.04);
		brutaldiff.antialiasing = ClientPrefs.globalAntialiasing;
		add(brutaldiff);

		easydiff.y -= 15;
		normaldiff.y -= 15;
		brutaldiff.y -= 15;

		diffstuff();

		changeWeek();
		changeDifficulty();

		addTouchPad("UP_DOWN", "B");
		addTouchPadCamera();
		
		super.create();
	}

	override function closeSubState() {
		persistentUpdate = true;
		changeWeek();
		super.closeSubState();
	}

	var oldsong = '';

	override function update(elapsed:Float)
	{
		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		camFollow.setPosition((FlxG.mouse.screenX + 720) / 2, ((FlxG.mouse.screenY + 1280) / 2) - 500);

		// scoreText.setFormat('VCR OSD Mono', 32);
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 30, 0, 1)));
		if(Math.abs(intendedScore - lerpScore) < 10) lerpScore = intendedScore;

		scoreText.text = "WEEK SCORE:" + lerpScore;

		// FlxG.watch.addQuick('font', scoreText.font);

		if (!movedBack && !selectedWeek)
		{
			var upP = controls.UI_UP_P;
			var downP = controls.UI_DOWN_P;

			if(FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				changeWeek(-FlxG.mouse.wheel);
				changeDifficulty();
			}

			mouseobject.x = FlxG.mouse.x;
			mouseobject.y = FlxG.mouse.y;
			
			for (item in grpWeekText.members)
			{
				if(FlxCollision.pixelPerfectCheck(mouseobject, item, 1)) {
					item.color = 0xFFFFFFFF;
					if(!((item.ID - curWeek) >= 3) && !((item.ID - curWeek) <= -3) && FlxG.mouse.justPressed) {
						if((item.ID - curWeek) == 0) {
							if (!weekIsLocked(loadedWeeks[curWeek].fileName))
							{
								selectedWeek = true;
								if (stopspamming == false)
								{
									FlxG.sound.play(Paths.sound('confirmMenu'));
									stopspamming = true;
								}
								FlxFlicker.flicker(item, 1, 0.06, false, false, function(flick:FlxFlicker)
								{
									// We can't use Dynamic Array .copy() because that crashes HTML5, here's a workaround.
									var songArray:Array<String> = [];
									var leWeek:Array<Dynamic> = loadedWeeks[curWeek].songs;
									for (i in 0...leWeek.length) {
										songArray.push(leWeek[i][0]);
									}
								
									// Nevermind that's stupid lmao
									PlayState.storyPlaylist = songArray;
									PlayState.isStoryMode = true;
								
									var diffic = CoolUtil.getDifficultyFilePath(curDifficulty);
									if(diffic == null) diffic = '';
								
									PlayState.storyDifficulty = curDifficulty;
								
									var addstuff = '';
									switch(diff) {
										case 0:
											addstuff = '-easy';
										case 2:
											addstuff = '-brutal';
									}
									PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + addstuff, PlayState.storyPlaylist[0].toLowerCase());
									PlayState.brutal = brutal;
									PlayState.campaignScore = 0;
									PlayState.campaignMisses = 0;
									LoadingState.loadAndSwitchState(new PlayState(), true);
									FreeplayState.destroyFreeplayVocals();
								});
							} else {
								FlxG.sound.play(Paths.sound('cancelMenu'));
							}
						} else {
							curWeek = item.ID;
						}
					}
				} else {
					item.color = 0xFFCCCCCC;
				}
				item.targetY = item.ID - curWeek;
			}
		}

		if(FlxCollision.pixelPerfectCheck(mouseobject, diffbg, 1)) {
			diffbg.alpha = 1;
			if(FlxG.mouse.justPressed) {
				diff += 1;
				if(diff > 2) {
					diff = 0;
				}
				if(diff == 2) {
					brutal = true;
				} else {
					brutal = false;
				}
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				diffstuff();
			}
		} else {
			diffbg.alpha = 0.6;
		}

		if(oldsong != WeekData.weeksList[curWeek]) {
			updateText();
			oldsong = WeekData.weeksList[curWeek];
		}

		if (controls.BACK && !movedBack && !selectedWeek)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			MusicBeatState.switchState(new MainMenuState());
		}

		super.update(elapsed);

		grpLocks.forEach(function(lock:FlxSprite)
		{
			lock.y = grpWeekText.members[lock.ID].y;
			lock.visible = (lock.y > FlxG.height / 2);
		});
	}

	function diffstuff() {
		switch(diff) {
			case 0:
				easydiff.alpha = 1;
				normaldiff.alpha = 0.6;
				brutaldiff.alpha = 0.6;
			case 1:
				easydiff.alpha = 0.6;
				normaldiff.alpha = 1;
				brutaldiff.alpha = 0.6;
			case 2:
				easydiff.alpha = 0.6;
				normaldiff.alpha = 0.6;
				brutaldiff.alpha = 1;
		}
	}
	
	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	var tweenDifficulty:FlxTween;
	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = CoolUtil.difficulties.length-1;
		if (curDifficulty >= CoolUtil.difficulties.length)
			curDifficulty = 0;

		WeekData.setDirectoryFromWeek(loadedWeeks[curWeek]);

		var diff:String = CoolUtil.difficulties[curDifficulty];
		var newImage:FlxGraphic = Paths.image('menudifficulties/' + Paths.formatToSongPath(diff));
		//trace(Paths.currentModDirectory + ', menudifficulties/' + Paths.formatToSongPath(diff));
		lastDifficultyName = diff;

		#if !switch
		intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
		#end
	}

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	function changeWeek(change:Int = 0):Void
	{
		curWeek += change;

		if (curWeek >= loadedWeeks.length)
			curWeek = 0;
		if (curWeek < 0)
			curWeek = loadedWeeks.length - 1;

		var leWeek:WeekData = loadedWeeks[curWeek];
		WeekData.setDirectoryFromWeek(leWeek);

		var leName:String = leWeek.storyName;

		var bullShit:Int = 0;

		var unlocked:Bool = !weekIsLocked(leWeek.fileName);
		for (item in grpWeekText.members)
		{
			item.targetY = bullShit - curWeek;
			bullShit++;
		}

		var assetName:String = leWeek.weekBackground;
		PlayState.storyWeek = curWeek;

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		var diffStr:String = WeekData.getCurrentWeek().difficulties;
		if(diffStr != null) diffStr = diffStr.trim(); //Fuck you HTML5

		if(diffStr != null && diffStr.length > 0)
		{
			var diffs:Array<String> = diffStr.split(',');
			var i:Int = diffs.length - 1;
			while (i > 0)
			{
				if(diffs[i] != null)
				{
					diffs[i] = diffs[i].trim();
					if(diffs[i].length < 1) diffs.remove(diffs[i]);
				}
				--i;
			}

			if(diffs.length > 0 && diffs[0].length > 0)
			{
				CoolUtil.difficulties = diffs;
			}
		}
		
		if(CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty))
		{
			curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty)));
		}
		else
		{
			curDifficulty = 0;
		}

		var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
		//trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
		if(newPos > -1)
		{
			curDifficulty = newPos;
		}
		updateText();
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!weekCompleted.exists(leWeek.weekBefore) || !weekCompleted.get(leWeek.weekBefore)));
	}

	function updateText()
	{
		var leWeek:WeekData = loadedWeeks[curWeek];
		var stringThing:Array<String> = [];
		for (i in 0...leWeek.songs.length) {
			stringThing.push(leWeek.songs[i][0]);
		}

		txtTracklist.text = '';
		for (i in 0...stringThing.length)
		{
			txtTracklist.text += stringThing[i] + '\n';
		}

		txtTracklist.text = 'TRACKS\n' + txtTracklist.text.toUpperCase();

		txtTracklist.screenCenter();
		txtTracklist.x -= FlxG.width * 0.35;
		txtTracklist.y += 50;

		#if !switch
		intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
		#end
	}
}

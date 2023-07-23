package;

#if desktop
import Discord.DiscordClient;
#end
import editors.ChartingState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import lime.utils.Assets;
#if (flixel >= "5.3.0")
import flixel.sound.FlxSound;
#else
import flixel.system.FlxSound;
#end
import openfl.utils.Assets as OpenFlAssets;
import flixel.FlxObject;
import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxCollision;
import flixel.effects.FlxFlicker;
import WeekData;
#if MODS_ALLOWED
import sys.FileSystem;
#end

using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	private static var curSelected:Int = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = '';

	var scoreText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	private var grpSongs:FlxTypedGroup<FlxSprite>;
	private var curPlaying:Bool = false;

	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;
	
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var mouseobject:FlxSprite;
	var freeplayartstuff:FlxSprite;

	var diffbg:FlxSprite;
	var easydiff:FlxSprite;
	var normaldiff:FlxSprite;
	var brutaldiff:FlxSprite;

	override function create()
	{
		FlxG.mouse.visible = true;

		//Paths.clearStoredMemory();
		//Paths.clearUnusedMemory();
		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		for (i in 0...WeekData.weeksList.length) {
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		WeekData.loadTheFirstEnabledMod();

		/*		//KIND OF BROKEN NOW AND ALSO PRETTY USELESS//

		var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));
		for (i in 0...initSonglist.length)
		{
			if(initSonglist[i] != null && initSonglist[i].length > 0) {
				var songArray:Array<String> = initSonglist[i].split(":");
				addSong(songArray[0], 0, songArray[1], Std.parseInt(songArray[2]));
			}
		}*/

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);
		bg.screenCenter();

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

		grpSongs = new FlxTypedGroup<FlxSprite>();
		add(grpSongs);

		var top:FlxSprite = new FlxSprite(-295, -234);
		top.frames = Paths.getSparrowAtlas('menu/song select');
		top.scrollFactor.set(0.1, 0.1);
		top.antialiasing = ClientPrefs.globalAntialiasing;
		top.animation.addByPrefix('idle', 'top', 24, false);
		top.animation.play('idle');
		add(top);

		freeplayartstuff = new FlxSprite();
		freeplayartstuff.loadGraphic('assets/images/menu/freeplay/art_' + songs[curSelected].songName.toLowerCase() + '.png');
		add(freeplayartstuff);
		freeplayartstuff.scrollFactor.set(0.05, 0.05);
		freeplayartstuff.antialiasing = ClientPrefs.globalAntialiasing;
		freeplayartstuff.scale.set(0.55, 0.55);
		freeplayartstuff.updateHitbox();
		freeplayartstuff.screenCenter();

		for (i in 0...songs.length)
		{
			var songText:FlxSprite = new FlxSprite(10, 310 + (i * 150));
			songText.loadGraphic('assets/images/menu/freeplay/text_' + songs[i].songName.toLowerCase() + '.png');
			freeplayartstuff.loadGraphic('assets/images/menu/freeplay/art_' + songs[i].songName.toLowerCase() + '.png');
			songText.ID = i;
			grpSongs.add(songText);
			songText.scrollFactor.set(0.05, 0.05);
			songText.antialiasing = ClientPrefs.globalAntialiasing;
			songText.updateHitbox();
		}

		freeplayartstuff.loadGraphic('assets/images/menu/freeplay/art_' + songs[curSelected].songName.toLowerCase() + '.png');

		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.scrollFactor.set(0.05, 0.05);
		scoreText.setFormat(Paths.font("phantommuff.ttf"), 32, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreText.borderSize = 1.25;
		scoreText.y += 10;
		add(scoreText);

		if(curSelected >= songs.length) curSelected = 0;
		intendedColor = bg.color;

		if(lastDifficultyName == '')
		{
			lastDifficultyName = CoolUtil.defaultDifficulty;
		}
		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));
		
		changeSelection();
		changeDiff();

		var swag:Alphabet = new Alphabet(1, 0, "swag");

		var leText:String = "Press SPACE to listen to the Song";
		var size:Int = 28;
		var text:FlxText = new FlxText(0, FlxG.height - 22, FlxG.width, leText, size);
		text.setFormat(Paths.font("phantommuff.ttf"), size, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.borderSize = 1.25;
		text.scrollFactor.set(0.05, 0.05);
		text.y -= 25;
		add(text);

		FlxG.camera.follow(camFollowPos, null, 1);
		camFollowPos.setPosition(((FlxG.mouse.screenX + 720) / 2) - 40, ((FlxG.mouse.screenY + 1280) / 2) - 450);

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

		super.create();
	}

	override function closeSubState() {
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	var holdTime:Float = 0;
	var oldsong = '';
	var selectedthinglol = false;

	override function update(elapsed:Float)
	{
		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		camFollow.setPosition(((FlxG.mouse.screenX + 720) / 2) - 40, ((FlxG.mouse.screenY + 1280) / 2) - 450);
		
		grpSongs.forEach(function(spr:FlxSprite) {
			spr.y = FlxMath.lerp(spr.y, 310 + ((spr.ID - curSelected) * 150), CoolUtil.boundTo(elapsed * 9.6, 0, 1));
		});

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, CoolUtil.boundTo(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(Highscore.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}
		
		while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}

		scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
		positionHighscore();

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;
		var space = FlxG.keys.justPressed.SPACE;

		var shiftMult:Int = 1;
		
		if(!selectedthinglol) {
			if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

			if(songs.length > 1 && FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
				changeSelection(-shiftMult * FlxG.mouse.wheel, false);
				changeDiff();
			}
	
			if (controls.BACK)
			{
				persistentUpdate = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}
	
			if(space)
			{
				if(instPlaying != curSelected)
				{
					#if PRELOAD_ALL
					destroyFreeplayVocals();
					FlxG.sound.music.volume = 0;
					Paths.currentModDirectory = songs[curSelected].folder;
					var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
					PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
					if (PlayState.SONG.needsVoices)
						vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
					else
						vocals = new FlxSound();
	
					FlxG.sound.list.add(vocals);
					FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.7);
					vocals.play();
					vocals.persist = true;
					vocals.looped = true;
					vocals.volume = 0.7;
					instPlaying = curSelected;
					#end
				}
			}
	
			mouseobject.x = FlxG.mouse.x;
			mouseobject.y = FlxG.mouse.y;
	
			for (item in grpSongs.members)
			{
				if(FlxCollision.pixelPerfectCheck(mouseobject, item, 1)) {
					item.color = 0xFFFFFFFF;
					if(!((item.ID - curSelected) >= 3) && !((item.ID - curSelected) <= -3) && FlxG.mouse.justPressed) {
						if((item.ID - curSelected) == 0) {
							selectedthinglol = true;
							FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
							FlxFlicker.flicker(item, 1, 0.06, false, false, function(flick:FlxFlicker)
							{
								curSelected = item.ID;
								persistentUpdate = false;
								var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
								trace(songLowercase);
							
								var addstuff = '';
								switch(StoryMenuState.diff) {
									case 0:
										addstuff = '-easy';
									case 2:
										addstuff = '-brutal';
								}
								PlayState.SONG = Song.loadFromJson(songLowercase + addstuff, songLowercase);
								PlayState.brutal = StoryMenuState.brutal;
								PlayState.isStoryMode = false;
								PlayState.storyDifficulty = curDifficulty;
								
								LoadingState.loadAndSwitchState(new PlayState());
							
								FlxG.sound.music.volume = 0;
										
								destroyFreeplayVocals();
							});
						} else {
							curSelected = item.ID;
						}
					}
				} else {
					item.color = 0xFFCCCCCC;
				}
			}

			if(FlxCollision.pixelPerfectCheck(mouseobject, diffbg, 1)) {
				diffbg.alpha = 1;
				if(FlxG.mouse.justPressed) {
					StoryMenuState.diff += 1;
					if(StoryMenuState.diff > 2) {
						StoryMenuState.diff = 0;
					}
					if(StoryMenuState.diff == 2) {
						StoryMenuState.brutal = true;
					} else {
						StoryMenuState.brutal = false;
					}
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					diffstuff();
				}
			} else {
				diffbg.alpha = 0.6;
			}
	
			if(oldsong != songs[curSelected].songName) {
				freeplayartstuff.loadGraphic('assets/images/menu/freeplay/art_' + songs[curSelected].songName.toLowerCase() + '.png');
				oldsong = songs[curSelected].songName;
			}
			freeplayartstuff.updateHitbox();
			freeplayartstuff.screenCenter();
		}

		super.update(elapsed);
	}

	function diffstuff() {
		switch(StoryMenuState.diff) {
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

	public static function destroyFreeplayVocals() {
		if(vocals != null) {
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = CoolUtil.difficulties.length-1;
		if (curDifficulty >= CoolUtil.difficulties.length)
			curDifficulty = 0;

		lastDifficultyName = CoolUtil.difficulties[curDifficulty];

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		PlayState.storyDifficulty = curDifficulty;
		positionHighscore();
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		var bullShit:Int = 0;

		for (item in grpSongs.members)
		{
			bullShit++;

			item.color = 0xFFCCCCCC;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if ((item.ID - curSelected) == 0)
			{
				item.color = 0xFFFFFFFF;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
		
		Paths.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;

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
	}

	private function positionHighscore() {
		scoreText.x = FlxG.width - scoreText.width - 6;
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Paths.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
}
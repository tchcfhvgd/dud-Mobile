package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxCollision;
import flixel.math.FlxMath;
import sys.FileSystem;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using StringTools;

class DudSonas extends MusicBeatState
{
	public static var curSelected:Int = 0;
	var menuItems:FlxTypedGroup<FlxSprite>;
	var textitems:FlxTypedGroup<FlxText>;
	private var camGame:FlxCamera;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var mouseobject:FlxSprite;
	var allduds:Array<String> = [];
	var backdrop:FlxBackdrop;

	override function create()
	{
		#if MODS_ALLOWED
		Paths.pushGlobalMods();
		#end
		WeekData.loadTheFirstEnabledMod();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Dud Menu", null);
		#end

		camGame = new FlxCamera();

		FlxG.cameras.reset(camGame);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		for (file in FileSystem.readDirectory('assets/images/dudsonas/')) {
			var path = haxe.io.Path.join(['assets/images/dudsonas/', file]);
			if (!sys.FileSystem.isDirectory(path)) {
				allduds.push(file);
			}
		}

		mouseobject = new FlxSprite(0, 0).makeGraphic(1, 1, 0xFFFFFFFF);
		add(mouseobject);

		var bg:FlxSprite = new FlxSprite(-218, -321).loadGraphic(Paths.image('menu/gradient'));
		bg.scrollFactor.set();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		add(backdrop = new FlxBackdrop(Paths.image('menu/grid')));
		backdrop.scrollFactor.set(0.2, 0.2);
		backdrop.velocity.set(20, 20);

		var top:FlxSprite = new FlxSprite(-295, -234);
		top.frames = Paths.getSparrowAtlas('menu/song select');
		top.scrollFactor.set(0.1, 0.1);
		top.antialiasing = ClientPrefs.globalAntialiasing;
		top.animation.addByPrefix('idle', 'top', 24, false);
		top.animation.play('idle');
		add(top);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		textitems = new FlxTypedGroup<FlxText>();
		add(textitems);

		for (i in 0...allduds.length)
		{
			var menuItem:FlxSprite = new FlxSprite().loadGraphic('assets/images/dudsonas/' + allduds[i]);
			menuItem.ID = i;
			menuItems.add(menuItem);
			menuItem.scale.x = 200 / menuItem.width;
			if(allduds[i] == 'dude.png') {
				menuItem.scale.y = 400 / menuItem.height;
			} else {
				menuItem.scale.y = 200 / menuItem.height;
			}
			menuItem.updateHitbox();
			menuItem.scrollFactor.set(0.05, 0.05);
			menuItem.screenCenter();
			menuItem.visible = false;
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;

			var scoreText:FlxText;
			scoreText = new FlxText(20, 10, 0, allduds[i].split('.')[0], 36);
			scoreText.setFormat(Paths.font("phantommuff.ttf"), 32, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			scoreText.borderSize = 1.25;
			scoreText.scrollFactor.set(0.05, 0.05);
			scoreText.screenCenter();
			scoreText.y = menuItem.y + menuItem.height + 25;
			scoreText.ID = i;
			textitems.add(scoreText);
		}

		var scoreText:FlxText;
		scoreText = new FlxText(20, 35, 0, "Press R to get a new dud", 36);
		scoreText.setFormat(Paths.font("phantommuff.ttf"), 32, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreText.borderSize = 1.25;
		scoreText.scrollFactor.set(0.05, 0.05);
		add(scoreText);

		FlxG.camera.follow(camFollowPos, null, 1);

		dostuff();

		camFollowPos.setPosition((FlxG.mouse.screenX + 720) / 2, (FlxG.mouse.screenY + 1280) / 2);

		addTouchPad("NONE", "A_B");
		addTouchPadCamera();
		
		super.create();
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
			if(FreeplayState.vocals != null) FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		camFollow.setPosition((FlxG.mouse.screenX + 720) / 2, (FlxG.mouse.screenY + 1280) / 2);

		if (!selectedSomethin)
		{
			if(FlxG.keys.justPressed.R || touchPad.buttonA.justPressed) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				curSelected = FlxG.random.int(0, allduds.length - 1);
				dostuff();
			}

			if (controls.BACK) {
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}
		}

		super.update(elapsed);
	}

	function dostuff() {
		menuItems.forEach(function(spr:FlxSprite) {
			spr.visible = false;
			if(spr.ID == curSelected) {
				spr.visible = true;
			}
		});
		textitems.forEach(function(spr:FlxText) {
			spr.visible = false;
			if(spr.ID == curSelected) {
				spr.visible = true;
			}
		});
	}
}

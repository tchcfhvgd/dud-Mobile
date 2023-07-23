package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxCollision;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.6.3'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	
	var optionShit:Array<String> = [
		'storymenu',
		'freeplay',
		'credits',
		'options',
		'dudsonas'
	];

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;
	var oldcurselected = 0;
	var mouseobject:FlxSprite;
	var backdrop:FlxBackdrop;

	override function create()
	{
		oldcurselected = curSelected;
		FlxG.mouse.visible = true;

		#if MODS_ALLOWED
		Paths.pushGlobalMods();
		#end
		WeekData.loadTheFirstEnabledMod();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		camGame = new FlxCamera();

		FlxG.cameras.reset(camGame);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

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

		var dud:FlxSprite = new FlxSprite(500, -316).loadGraphic(Paths.image('menu/dud'));
		dud.scrollFactor.set(0.1, 0.1);
		dud.screenCenter();
		dud.antialiasing = ClientPrefs.globalAntialiasing;
		add(dud);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (i in 0...optionShit.length)
		{
			var coolx = -75 + (i * 200);
			var cooly = i * 140;
			switch(i) {
				case 0:
					coolx = -87;
					cooly = 11;
				case 1:
					coolx = 7;
					cooly = 64;
				case 2:
					coolx = 167;
					cooly = 208;
				case 3:
					coolx = 366;
					cooly = 274;
				case 4:
					coolx = 655;
					cooly = 391;
			}
			cooly += 25;
			var menuItem:FlxSprite = new FlxSprite(coolx, cooly);
			menuItem.frames = Paths.getSparrowAtlas('menu/buttons');
			menuItem.animation.addByPrefix('idle', 'unselected ' + optionShit[i], 24);
			menuItem.animation.addByPrefix('selected', 'selected ' + optionShit[i], 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItems.add(menuItem);
			menuItem.scrollFactor.set(0.05, 0.05);
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			menuItem.updateHitbox();
		}

		FlxG.camera.follow(camFollowPos, null, 1);

		// NG.core.calls.event.logEvent('swag').send();

		dostuff();

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
			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			#if desktop
			if (FlxG.keys.anyJustPressed(debugKeys))
			{
				if(CoolUtil.devmode) {
					selectedSomethin = true;
					MusicBeatState.switchState(new MasterEditorMenu());
				}
			}
			#end

			mouseobject.x = FlxG.mouse.x;
			mouseobject.y = FlxG.mouse.y;

			dostuff();
			menuItems.forEach(function(spr:FlxSprite) {
				if(FlxCollision.pixelPerfectCheck(mouseobject, spr, 1)) {
					curSelected = spr.ID;
					spr.animation.play('selected');
					spr.centerOffsets();
					if (FlxG.mouse.justPressed) {
						selectedSomethin = true;
						FlxG.sound.play(Paths.sound('confirmMenu'));
				
						menuItems.forEach(function(cooliospr:FlxSprite) {
							if(curSelected != cooliospr.ID) {
								FlxTween.tween(cooliospr, {alpha: 0}, 0.4, {
									ease: FlxEase.quadOut,
									onComplete: function(twn:FlxTween)
									{
										cooliospr.kill();
									}
								});
							} else {
								FlxFlicker.flicker(cooliospr, 1, 0.06, false, false, function(flick:FlxFlicker)
								{
									var daChoice:String = optionShit[curSelected];
				
									switch (daChoice)
									{
										case 'storymenu':
											MusicBeatState.switchState(new StoryMenuState());
										case 'freeplay':
											MusicBeatState.switchState(new FreeplayState());
										case 'credits':
											MusicBeatState.switchState(new CreditsState());
										case 'options':
											LoadingState.loadAndSwitchState(new options.OptionsState());
										case 'dudsonas':
											MusicBeatState.switchState(new DudSonas());
									}
								});
							}
						});
					}
				}
			});
		}

		super.update(elapsed);
	}

	function dostuff() {
		menuItems.forEach(function(spr:FlxSprite) {
			spr.animation.play('idle');
			spr.centerOffsets();
			spr.updateHitbox();
			if(oldcurselected != curSelected) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				oldcurselected = curSelected;
			}
		});
	}
}

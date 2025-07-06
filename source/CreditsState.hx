package;

#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import lime.utils.Assets;
import flixel.util.FlxTimer;
import flixel.util.FlxSave;
import lime.app.Application;
import flixel.util.FlxCollision;

using StringTools;

class CreditsState extends MusicBeatState
{
    public static var curSelected = 0;
    var stickmangroup:FlxTypedGroup<FlxSprite>;
    var namebg:FlxSprite;
    var nameText:FlxText;
    var descbg:FlxSprite;
    var descText:FlxText;

    var xposcam = 0.0;
    var yposcam = 0.0;

    var creditstuff:Array<Array<Dynamic>> = [
        ['white ninja',		        'whiteninja',   'director/coder/artist',    'http://www.whiteninja00.com/'                              ],
        ['john daily',		        'john',		    'director/charter',		    'https://www.youtube.com/channel/UCodLS1PxWyQguqoHEWNPcYw'  ],
		['Tiburones 202',	        'tibrune',	    'coder',		    	    'https://youtube.com/channel/UCuJM5h8kgRHyFNg56LsOjNw'      ],
		['Imjustatomixx',	        'atomixx',	    'musician',		            'https://twitter.com/imjustatomixx'                         ],
		['The Deserved One',        'deserved',	    'artist',				    'https://youtube.com/channel/UCaCeT66DtOsY0J9QBMw-tSg'      ],
		['spoon dice music',        'spoondice',    'musician',		            'https://www.youtube.com/c/SpoonDice'                       ],
		['Jacelol',	                'experiance',   'musician',			        'https://twitter.com/JaceLOL_'                              ],
		['solar',			        'solar',	    'charter',				    'https://youtube.com/channel/UCYXS3uSdDgcH6CvEn_AgnXw'      ],
		['sir chapurato',	        'chap',		    'charter/musician',		    'https://www.youtube.com/channel/UC37f51A8bNepi7PvD8owOxQ'  ],
        ['tumid',	                'bro',		    'musician',		            'https://www.youtube.com/channel/UC6aZ9FDGvgtMEaWR6YSXn3A'  ],
        ['egglo',	                'egglo',	    'musician',				    'https://www.youtube.com/@EggloImao'                        ],
		['Simox',	                'simox',	    'charter',		            'https://www.youtube.com/channel/UC8cwN_xk8ugqL2_y7LPVOVA'  ],
        ['Golden',	                'goldud',	    'charter',		            'https://twitter.com/GoldennightX'                          ],
        ['Lelazyone',	            'lazy',	        'charter',		            'https://www.youtube.com/channel/UCIkyshtrRmsmPx4q0FqW-2w'  ]
    ];

    var bg:FlxSprite;
    var backgroundx = -787;
    var backgroundy = -300;
    var sprx = 0.0;
    var spry = 0.0;
    var namebgx = 0.0;
    var namebgy = 0.0;
    var descbgx = 0.0;
    var descbgy = 0.0;
    var youcan = false;
	var mouseobject:FlxSprite;

	override function create()
	{
        #if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		mouseobject = new FlxSprite(0, 0).makeGraphic(1, 1, 0xFFFFFFFF);
		add(mouseobject);

        bg = new FlxSprite(backgroundx, backgroundy).loadGraphic(Paths.image('credits/background', 'preload'));
        bg.width = 6000;
        bg.antialiasing = ClientPrefs.globalAntialiasing;
        bg.scrollFactor.set();
        add(bg);

        stickmangroup = new FlxTypedGroup<FlxSprite>();
		add(stickmangroup);

        for(i in 0...creditstuff.length) {
            var stickman:FlxSprite;
            stickman = new FlxSprite(0, 0).loadGraphic(Paths.image('credits/' + creditstuff[i][1], 'preload'));
            stickman.antialiasing = ClientPrefs.globalAntialiasing;
            stickman.ID = i;
            stickmangroup.add(stickman);
        }

        namebg = new FlxSprite(0, 0).loadGraphic(Paths.image('credits/creditthingdesc', 'preload'));
        namebg.antialiasing = ClientPrefs.globalAntialiasing;
        namebg.width = 1020;
        namebg.height = 50;
        namebg.color = 0xDD000000;
        add(namebg);

        nameText = new FlxText(0, 0, 0, "", 32);
		nameText.setFormat(Paths.font("phantommuff.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		nameText.borderSize = 2.4;
		add(nameText);

        descbg = new FlxSprite(0, 0).loadGraphic(Paths.image('credits/creditthingdesc', 'preload'));
        descbg.antialiasing = ClientPrefs.globalAntialiasing;
        descbg.width = 1020;
        descbg.height = 50;
        descbg.color = 0xDD000000;
        add(descbg);

        descText = new FlxText(0, 0, 0, "", 32);
		descText.setFormat(Paths.font("phantommuff.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.borderSize = 2.4;
		add(descText);

        changeSelection();

        stickmangroup.forEach(function(spr:FlxSprite)
        {
            spr.x = (spr.ID * 160) - xposcam;
            spr.y = -yposcam;
            if(spr.ID == curSelected) {
                sprx = spr.x;
                spry = spr.y;
            }
        });

        descbg.scale.x = (descText.width + 20) / 1020;
        descbg.updateHitbox();
        descbgx = sprx + (stickmangroup.members[curSelected].width / 2) - (descbg.width / 2);
        descbgy = spry - descbg.height - 10;
        descbg.x = descbgx;
        descbg.y = descbgy;
        descText.x = descbgx + 10;
        descText.y = descbgy + 5;
        namebg.scale.x = (nameText.width + 20) / 1020;
        namebg.updateHitbox();
        namebgx = sprx + (stickmangroup.members[curSelected].width / 2) - (namebg.width / 2);
        namebgy = descbgy - namebg.height - 5;
        namebg.x = namebgx;
        namebg.y = namebgy;
        nameText.x = namebgx + 10;
        nameText.y = namebgy + 5;

		addTouchPad("LEFT_RIGHT", "A_B");
		
		super.create();
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

        var coolval = CoolUtil.boundTo(elapsed * 9.6, 0, 1);

        stickmangroup.forEach(function(spr:FlxSprite)
        {
            spr.x = FlxMath.lerp(spr.x, (spr.ID * 160) - xposcam, coolval);
            spr.y = FlxMath.lerp(spr.y, -yposcam, coolval);
            if(spr.ID == curSelected) {
                sprx = spr.x;
                spry = spr.y;
            }
        });

        descbg.scale.x = FlxMath.lerp(descbg.scale.x, (descText.width + 20) / 1020, coolval);
        descbg.updateHitbox();
        descbgx = sprx + (stickmangroup.members[curSelected].width / 2) - (descbg.width / 2);
        descbgy = spry - descbg.height - 10;
        descbg.x = FlxMath.lerp(descbg.x, descbgx, coolval);
        descbg.y = FlxMath.lerp(descbg.y, descbgy, coolval);
        descText.x = FlxMath.lerp(descText.x, descbgx + 10, coolval);
        descText.y = FlxMath.lerp(descText.y, descbgy + 5, coolval);
        namebg.scale.x = FlxMath.lerp(namebg.scale.x, (nameText.width + 20) / 1020, coolval);
        namebg.updateHitbox();
        namebgx = sprx + (stickmangroup.members[curSelected].width / 2) - (namebg.width / 2);
        namebgy = descbgy - namebg.height - 5;
        namebg.x = FlxMath.lerp(namebg.x, namebgx, coolval);
        namebg.y = FlxMath.lerp(namebg.y, namebgy, coolval);
        nameText.x = FlxMath.lerp(nameText.x, namebgx + 10, coolval);
        nameText.y = FlxMath.lerp(nameText.y, namebgy + 5, coolval);

		var upP = controls.UI_LEFT_P;
		var downP = controls.UI_RIGHT_P;

		if(FlxG.mouse.wheel != 0)
		{
			changeSelection(-1 * FlxG.mouse.wheel);
		}

		mouseobject.x = FlxG.mouse.x;
		mouseobject.y = FlxG.mouse.y;

		for (item in stickmangroup.members)
		{
			if(FlxCollision.pixelPerfectCheck(mouseobject, item, 1)) {
                item.color = 0xFFFFFFFF;
                item.alpha = 1;
				if(FlxG.mouse.justPressed) {
					if(item.ID == curSelected) {
						CoolUtil.browserLoad(creditstuff[curSelected][3]);
					} else {
						movecam(item);
						item.color = 0xFFFFFFFF;
						item.alpha = 1;
						curSelected = item.ID;
					}
				}
			} else {
				if(item.ID == curSelected) {
					item.color = 0xFFFFFFFF;
					item.alpha = 1;
				} else {
					item.color = 0xFFDDDDDD;
					item.alpha = 0.7;
				}
			}
		}

        if (upP)
			changeSelection(-1);
		if (downP)
			changeSelection(1);

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}
		if(controls.ACCEPT) {
            if(creditstuff[curSelected][0].toUpperCase() == 'DUD') {
                Application.current.window.alert('take a peek in the files', 'hint');
            }
            CoolUtil.browserLoad(creditstuff[curSelected][3]);
        }
		super.update(elapsed);
	}

	function changeSelection(change:Int = 0)
	{
		if(change != 0) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

        curSelected += change;
        
		if (curSelected < 0)
			curSelected = creditstuff.length - 1;
		if (curSelected >= creditstuff.length)
			curSelected = 0;

        stickmangroup.forEach(function(spr:FlxSprite)
        {
            if(spr.ID == curSelected) {
				movecam(spr);
            }
        });
	}

	function movecam(spr:FlxSprite) {
		xposcam = (spr.ID * 160) + (spr.width / 2) - 640;
		yposcam = (spr.height / 2) - 400;
		nameText.text = creditstuff[spr.ID][0].toUpperCase();
		descText.text = creditstuff[spr.ID][2].toUpperCase();
	}
}

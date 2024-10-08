package;

import format.csv.*;
import haxe.DynamicAccess;
import haxe.Json;
import haxe.Utf8;
import haxe.ds.Map;
import sys.FileSystem;
import sys.io.File;

using StringTools;

/**
 * @author YellowAfterlife
 */
class Main {
	public static var loc:Map<String, String>;
	static var tagsPerMod:Map<Mod, Array<String>> = new Map();
	static var tagsPerModInit:Map<String, Array<String>> = new Map();
	static var tagsFound:Map<String, Bool> = new Map();
	static var tagList:Array<String> = [];
	static var parseText_meta:Array<String>;

	static function replaceCsvVariant(src:UnicodeString):UnicodeString {
		var csv = Reader.parseCsv(File.getContent("docs/variables.csv"));

		for (row in csv) {
			if (Std.string(row[0]).contains("+"))
				row[1] = "+" + row[1];
			if (Std.string(row[0]).contains("-"))
				row[1] = "-" + row[1];
			if (Std.string(row[0]).contains("%"))
				row[1] = row[1] + "%";

			src = src.replace("[$={" + row[0] + "}]", row[1]);
		}

		return src;
	}

	static function parseText(src:UnicodeString) {
		src = src.replace("\r", "");
		src = src.replace("[$=*]", "◈ ");
		src = replaceCsvVariant(src);
		var start = 0;
		var result = new StringBuf();
		var pos = src.indexOf("[$=");
		var meta = [];
		while (pos >= 0) {
			var end = src.indexOf("]", pos);
			var sub:UnicodeString = src.substring(start, pos);
			result.add(sub);
			result.add("\u200b"); // ZERO WIDTH SPACE
			meta.push(src.substring(pos + 3, end));
			start = end + 1;
			pos = src.indexOf("[$=", pos + 1);
		}
		result.addSub(src, start);
		parseText_meta = meta;
		return result.toString();
	}

	static function fixup(name:String):String {
		return switch (name) {
			case Mod.HeatSeeking: return "Guidance";
			case Mod.TargettingSystems: return "Targeting";
			case Mod.SplinterShot: return "Splinter";
			case Mod.RetaliationShields: return "ReflexiveShields";
			case Mod.DefenseDrone: return "DefensiveDrones";
			case Mod.Max: return "Final-tier Construct";
			case Mod.DefaultWeapon: return "Standard";
			case Mod.DefaultBody: return "Standard";
			case Mod.DefaultShield: return "Standard";
			case Mod.Split: return "SplitShot";
			case Mod.ArcBarrier: return "FormationRampart";
			case Mod.FleetCommander: return "Fleet";
			case Mod.Reconstitution: return "Flotilla";
			case Mod.Subsumption: return "RocketDrones";
			case Mod.TerminalDirective: return "PredatorDrones";
			case Mod.GraceProtocol: return "ReinforcedDrones";
			case Mod.VoidSlice: return "Displacement";
			default: name;
		}
	}

	static function addTile(b:StringBuf, mod:Mod, kind:String = "Mod", post:String = "", sub:String = "") {
		if(sub != "") sub = ' $sub';
		b.add('<div class="hex $mod$sub"');
		var name = fixup(mod);
		var title = loc[kind + "Title" + post + name];
		if (title != null) {
			if (title.endsWith(":")) {
				title = title.substr(0, title.length - 1);
			}
		} else {
			if (mod == Mod.ShieldRadius) {
				title = loc["ModTitleShieldEffectRadius"];
				if (title.endsWith(":")) {
					title = title.substr(0, title.length - 1);
				}
			} else {
				if (name == mod)
					trace("404 " + name);
				title = name;
			}
		}

		// add tags:
		var tags:Array<String> = tagsPerMod[mod];
		if (tags == null) {
			tags = [];
			inline function add(arr:Array<String>) {
				if (arr != null)
					for (tag in arr)
						tags.push(tag);
			}
			var tagKey = title.toLowerCase();
			tagKey = ~/^(weapon|body|shield|wild mod): /.replace(tagKey, "");
			add(tagsPerModInit[tagKey]);
			add(tagsPerModInit[(mod : String).toLowerCase()]);
			tagsPerMod[mod] = tags;
		}
		if (tags != null) {
			b.add(' data-hex-tags="');
			for (tag in tags) {
				if (!tagsFound[tag]) {
					tagsFound[tag] = true;
					tagList.push(tag);
				}
				b.add('$tag;');
			}
			b.add('"');
		}

		// ModShortNames.check(mod, title);

		// add title:
		var desc = loc[kind + "Full" + post + name];
		if (desc == null && mod == Mod.BladeDrone)
			desc = loc["GearFullWeaponBlade"];
		if (desc != null) {
			title = parseText(title + "\n\n" + desc);
			title = title.replace("\n", "&#10;");
			if (parseText_meta != null)
				b.add(' data-hex-meta="${parseText_meta.join(";")}"');
		}
		title = title.replace('"', '&quot;');
		b.add(' title="$title"');
		b.add('>');
		b.add('</div>\n');
	}

	static function addSingle(b:StringBuf, mod:Mod, ?kind:String, ?post:String, ?sub:String) {
		b.add('<section class="single">\n');
		addTile(b, mod, kind, post, sub);
		b.add("</section>\n");
	}

	static function genBranches() {
		var b = new StringBuf();
		function add(top:Mod, left:Mod, right:Mod, bottom:Mod) {
			b.add('<section class="branch">\n');
			addTile(b, top);
			addTile(b, left);
			addTile(b, right);
			addTile(b, bottom);
			b.add("</section>\n");
		}

		add(Mod.Magnitude, Mod.Payload, Mod.SplinterShot, Mod.ChargedShot);
		add(Mod.Velocity, Mod.Snipe, Mod.Calibrate, Mod.Breach);
		add(Mod.RapidFire, Mod.BurstFire, Mod.Warpath, Mod.SiegeWeaponry);
		add(Mod.AddedProjectiles, Mod.FocusFire, Mod.FiringArray, Mod.Fusillade);
		add(Mod.TargettingSystems, Mod.HeatSeeking, Mod.HomingStrike, Mod.Convergence);
		add(Mod.BlastRadius, Mod.HighExplosive, Mod.ConcentratedBlast, Mod.Rupture);
		add(Mod.Candescence, Mod.Corrosion, Mod.Purge, Mod.Purification);

		add(Mod.Ally, Mod.Nanotech, Mod.EchoStrike, Mod.Evolution);
		add(Mod.IntegratedWeaponry, Mod.Outmaneuver, Mod.Wingman, Mod.Overpower);
		add(Mod.Guardian, Mod.NanotechDissemination, Mod.DecoySignal, Mod.MediCharge);
		add(Mod.Turret, Mod.PointDefense, Mod.WarMachine, Mod.CounterArtillery);
		add(Mod.Mines, Mod.AutoMines, Mod.LoadedMines, Mod.Retribution);
		add(Mod.Drones, Mod.GraceProtocol, Mod.Subsumption, Mod.AdvancedEngineering);
		add(Mod.AssaultDrones, Mod.TerminalDirective, Mod.BattalionDrones, Mod.FleetCommander);
		add(Mod.DefenseDrone, Mod.ArcBarrier, Mod.Counterpulse, Mod.Reconstitution);
		add(Mod.ElegantConstruction, Mod.SelfDestruction, Mod.ShieldedDrones, Mod.Overseer);
		add(Mod.PriorityZero, Mod.Overclock, Mod.TacticalLink, Mod.SupportSpecialist);

		add(Mod.HullStrength, Mod.Absorption, Mod.Juggernaut, Mod.ForceArmor);
		add(Mod.HullRegeneration, Mod.RegenerativeShields, Mod.RapidReconstruction, Mod.AdrenalModule);

		add(Mod.ShieldDurability, Mod.RetaliationShields, Mod.Barrier, Mod.OmniShield);
		add(Mod.ShieldCooldown, Mod.VolatileShields, Mod.FlashShielding, Mod.Discharge);
		add(Mod.ShieldRadius, Mod.RadiantShields, Mod.FocusedShields, Mod.WeaponizedShields);

		add(Mod.Efficiency, Mod.Gemini, Mod.Conversion, Mod.Regression);
		add(Mod.AdaptiveArmor, Mod.Channeling, Mod.Rebuke, Mod.CoreShielding);

		add(Mod.ImprovedThrusters, Mod.DeadlyWake, Mod.Streamline, Mod.Blink);
		add(Mod.KineticBoost, Mod.Aegis, Mod.Lance, Mod.EmergencySystems);
		add(Mod.Stabilization, Mod.Agility, Mod.PowerReserves, Mod.Strafe);

		add(Mod.Skirmish, Mod.Blitz, Mod.Terminate, Mod.EssenceSap);

		return b.toString();
	}

	static function genSupers() {
		var b = new StringBuf();
		function addPair(sup:Mod, one:Mod, two:Mod) {
			b.add('<section class="super">\n');
			addTile(b, one);
			addTile(b, two);
			addTile(b, sup);
			b.add("</section>\n");
		}
		function addText(sup:Mod, textEN:String, textJA:String) {
			b.add('<section class="super-text">');
			b.add('<div class="text content-en">$textEN</div><div class="text content-ja">$textJA</div>');
			addTile(b, sup);
			b.add("</section>\n");
		}
		addText(Mod.HiddenPower,'4x<br/>Secondary Damage', '4x<br/>副次ダメージ源');
		addPair(Mod.VitalBond, Mod.Max, Mod.RapidReconstruction);
		addPair(Mod.TempestBreak, Mod.DeadlyWake, Mod.FlashShielding);
		addPair(Mod.SaturationFire, Mod.Calibrate, Mod.SiegeWeaponry);
		addPair(Mod.Mortar, Mod.Overseer, Mod.Mines);
		addPair(Mod.CelestialSurge, Mod.Lance, Mod.Stabilization);
		addPair(Mod.Rancor, Mod.ChargedShot, Mod.Absorption);
		addPair(Mod.ChargedMines, Mod.ChargedShot, Mod.LoadedMines);
		addPair(Mod.Sanctuary, Mod.Aegis, Mod.Barrier);
		addPair(Mod.Annihilation, Mod.Payload, Mod.ConcentratedBlast);
		addPair(Mod.ApexMachinery, Mod.Max, Mod.ShieldedDrones);
		addPair(Mod.DyingStar, Mod.Candescence, Mod.CoreShielding);
		addPair(Mod.WarpStrike, Mod.Snipe, Mod.Blink);
		addPair(Mod.BurnoutReactors, Mod.SelfDestruction, Mod.Candescence);
		addText(Mod.LastStand, '10x<br/>Shield/Body Mods', '10x<br/>防御MOD');
		addPair(Mod.Barrage, Mod.FocusFire, Mod.BurstFire);
		addPair(Mod.VoidSlice, Mod.Blink, Mod.Strafe);
		addPair(Mod.LeafOnTheWind, Mod.Streamline, Mod.Warpath);
		addPair(Mod.SingularStrikeNew, Mod.Payload, Mod.Juggernaut);
		addPair(Mod.Deflagration, Mod.Rupture, Mod.Purge);
		addText(Mod.Mastery, '10x<br/>Weapon Mods', '10x<br/>武器MOD');
		addPair(Mod.Apotheosis, Mod.KineticBoost, Mod.Strafe);
		addText(Mod.Ataraxia, '4x<br/>Unspent Upgrades', '4x<br/>未使用アップグレード');
		addPair(Mod.Infuse, Mod.Magnitude, Mod.Discharge);
		addPair(Mod.ChargedShields, Mod.ChargedShot, Mod.FocusedShields);
		addPair(Mod.StrafingStrikes, Mod.Warpath, Mod.Strafe);
		return b.toString();
	}

	static function wildCommon() {
		var b = new StringBuf();
		function add(mod:Mod, sub:String = "")
			addSingle(b, mod, "Mod", "", sub);
		add(Mod.Slipstream, "rc");
		add(Mod.GalvanicOutburst, "rc");
		add(Mod.Rampage, "rc");
		add(Mod.Hypermetabolism, "rc");
		add(Mod.DoubleTap, "rc");
		add(Mod.HeavyCaliber, "rc");
		add(Mod.EnergizedShields, "rc");
		add(Mod.SolarHeart, "rc");
		add(Mod.PolarInversion);
		add(Mod.PropulsiveMunitions);
		add(Mod.ScorchingWake, "rc");
		add(Mod.SpecialistMine);
		add(Mod.SpecialistDrone);
		add(Mod.SpecialistTurret);
		add(Mod.SpecialistAlly);
		add(Mod.Masochism, "rc");
		add(Mod.Defiance, "rc");
		return b.toString();
	}

	static function wildRare() {
		var b = new StringBuf();
		function add(mod:Mod, sub:String = "")
			addSingle(b, mod, "Mod", "", sub);
		add(Mod.ChaoticAmbition, "rc");
		add(Mod.OutrageModule);
		add(Mod.PhantomStrike);
		add(Mod.Discord);
		add(Mod.Transmogrification);
		add(Mod.DeathBlossom);
		add(Mod.Revelation);
		add(Mod.Winnow);
		add(Mod.Obsession);
		add(Mod.Bravado);
		add(Mod.EvolutionaryNiche, "rc");
		add(Mod.SpontaneousGeneration, "rc");
		return b.toString();
	}

	static function wildUltraRare() {
		var b = new StringBuf();
		function add(mod:Mod, sub:String = "")
			addSingle(b, mod, "Mod", "", sub);
		add(Mod.Grandeur, "rc");
		add(Mod.TwinStrike, "rc");
		add(Mod.Farsight, "rc");
		add(Mod.ExplosiveGrowth);
		add(Mod.PowerSpike);
		add(Mod.Maelstrom);
		add(Mod.Ricochet, "rc");
		add(Mod.Challenger, "rc");
		return b.toString();
	}

	static function weapons() {
		var b = new StringBuf();
		function add(mod:Mod)
			addSingle(b, mod, "Gear", "Weapon");
		add(Mod.DefaultWeapon);
		add(Mod.Split);
		add(Mod.Railgun);
		add(Mod.Grenade);
		add(Mod.Torrent);
		add(Mod.Pulse);
		add(Mod.Flak);
		add(Mod.ThermalLance);
		add(Mod.Salvo);
		add(Mod.Vortex);
		add(Mod.BladeDrone);
		add(Mod.Dart);
		add(Mod.Swords);
		return b.toString();
	}

	static function bodies() {
		var b = new StringBuf();
		function add(mod:Mod)
			addSingle(b, mod, "Gear", "Body");
		add(Mod.DefaultBody);
		add(Mod.Assault);
		add(Mod.Stealth);
		add(Mod.Sentinel);
		add(Mod.Engineer);
		add(Mod.Firefly);
		add(Mod.Carrier);
		add(Mod.Hullbreaker);
		add(Mod.Battery);
		add(Mod.Architect);
		add(Mod.Research);
		add(Mod.Viper);
		add(Mod.Courser);
		add(Mod.Leviathan);
		return b.toString();
	}

	static function genShields() {
		var b = new StringBuf();
		function add(mod:Mod)
			addSingle(b, mod, "Gear", "Shield");
		add(Mod.DefaultShield);
		add(Mod.Halo);
		add(Mod.Temporal);
		add(Mod.Reflect);
		add(Mod.Warp);
		add(Mod.Shockwave);
		add(Mod.Amp);
		add(Mod.Bastion);
		add(Mod.Helix);
		add(Mod.Siphon);
		return b.toString();
	}

	static function main()
	{
		var html = File.getContent("docs/base.html");
		var jscript = File.getContent("docs/base.js");
		var hexStat:sys.FileStat = sys.FileSystem.stat("docs/hex.css");
		var styleStat:sys.FileStat = sys.FileSystem.stat("docs/style.css");
		var scriptStat:sys.FileStat = sys.FileSystem.stat("docs/script.js");
		var mainStat:sys.FileStat = sys.FileSystem.stat("docs/main.js");

		html = StringTools.replace(html, "<!--lastupdate-->", DateTools.format(Date.now(), "%Y-%m-%d").toString());
		html = StringTools.replace(html, "<!--lastupdateHex-->", DateTools.format(hexStat.mtime, "%Y%m%d_%H%M%S").toString());
		html = StringTools.replace(html, "<!--lastupdateStyle-->", DateTools.format(styleStat.mtime, "%Y%m%d_%H%M%S").toString());
		html = StringTools.replace(html, "<!--lastupdateScript-->", DateTools.format(scriptStat.mtime, "%Y%m%d_%H%M%S").toString());
		html = StringTools.replace(html, "<!--lastupdateMain-->", DateTools.format(mainStat.mtime, "%Y%m%d_%H%M%S").toString());

		// English
		var csv = Reader.parseCsv(File.getContent("docs/localization.csv"));
		loc = new Map();
		for (row in csv) loc[row[0]] = row[1];
		html = StringTools.replace(html, "<!--branches-->", genBranches());
		Sys.println("[EN] Branch");
		html = StringTools.replace(html, "<!--supers-->", genSupers());
		Sys.println("[EN] Super");
		html = StringTools.replace(html, "<!--wildCommon-->", wildCommon());
		Sys.println("[EN] Wild Normal");
		html = StringTools.replace(html, "<!--wildRare-->", wildRare());
		Sys.println("[EN] Wild Rare");
		html = StringTools.replace(html, "<!--wildUltraRare-->", wildUltraRare());
		Sys.println("[EN] Wild Ultra");
		html = StringTools.replace(html, "<!--weapons-->", weapons());
		Sys.println("[EN] Weapon");
		html = StringTools.replace(html, "<!--bodies-->", bodies());
		Sys.println("[EN] Body");
		html = StringTools.replace(html, "<!--shields-->", genShields());
		Sys.println("[EN] Shield");

		// Japanese
		csv = Reader.parseCsv(File.getContent("docs/Japanese.csv"));
		loc = new Map();
		for (row in csv) loc[row[0]] = row[1];
		html = StringTools.replace(html, "<!--branchesJP-->", genBranches());
		Sys.println("[JP] Branch");
		html = StringTools.replace(html, "<!--supersJP-->", genSupers());
		Sys.println("[JP] Super");
		html = StringTools.replace(html, "<!--wildCommonJP-->", wildCommon());
		Sys.println("[JP] Wild Normal");
		html = StringTools.replace(html, "<!--wildRareJP-->", wildRare());
		Sys.println("[JP] Wild Rare");
		html = StringTools.replace(html, "<!--wildUltraRareJP-->", wildUltraRare());
		Sys.println("[JP] Wild Ultra");
		html = StringTools.replace(html, "<!--weaponsJP-->", weapons());
		Sys.println("[JP] Weapon");
		html = StringTools.replace(html, "<!--bodiesJP-->", bodies());
		Sys.println("[JP] Body");
		html = StringTools.replace(html, "<!--shieldsJP-->", genShields());
		Sys.println("[JP] Shield");

		jscript = StringTools.replace(jscript, "[[shorten_data]]", ModShortNames.print(1));
		jscript = StringTools.replace(jscript, "[[prefab_data]]", ModShortNames.print(2));

		File.saveContent("docs/index.html", html);
		File.saveContent("docs/main.js", jscript);

		Sys.println("All Done!");
	}
}

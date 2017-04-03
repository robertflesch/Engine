/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine {
import flash.display.StageDisplayState;
import flash.system.Capabilities;

import com.developmentarc.core.tasks.TaskController;

import com.voxelengine.renderer.Renderer;
import com.voxelengine.worldmodel.MouseKeyboardHandler;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.oxel.OxelBad;
import com.voxelengine.utils.GUID;

public class Globals  {

	// Yahoo Game Networks Big DB table names
	static public const BIGDB_TABLE_INVENTORY:String = "inventory";
	static public const BIGDB_TABLE_MODEL_METADATA:String = "modelMetadata";
	static public const BIGDB_TABLE_MODEL_INFO:String = "modelInfo";
	static public const BIGDB_TABLE_OXEL_DATA:String = "oxelData";
	static public const BIGDB_TABLE_ANIMATIONS:String = "animations";
	static public const BIGDB_TABLE_AMMO:String = "ammo";
	static public const BIGDB_TABLE_REGIONS:String = "regions";

	// Yahoo Game Networks Big DB table indexs
	static public const BIGDB_TABLE_REGIONS_INDEX_OWNER:String = "owner";
	static public const BIGDB_TABLE_MODEL_METADATA_INDEX_OWNER:String = "owner";

	// Local file names for import
	static public const REGION_EXT:String = ".rjson";
	static public const APP_EXT:String = ".json";
	static public const IVM_EXT:String = ".ivm";
	static public const MODEL_INFO_EXT:String = ".mjson";
	static public const ANI_EXT:String = ".ajson";
	static public const AMMO_EXT:String = ".ammo";

	static public const VOXELVERSE:String 	= "VoxelVerse";
	public static var g_app:VoxelVerse;

	public static var g_mouseKeyboardHandler:MouseKeyboardHandler = new MouseKeyboardHandler();
	public static var g_textInput:Boolean

	public static const DOUBLE_MESSAGE_WAITING_PERIOD:int = 100;

	public static var g_nearplane:Number = 1/4;
	//public static var g_farplane:Number = 65536 / 4;
	public static var g_farplane:Number = 16777216 / 4; // MUCH MUCH better range at 24 bit Z buffer.
	public static const UNITS_PER_METER:int = 16;
	static public const AVATAR_HEIGHT:Number = ( UNITS_PER_METER * 2 ) - ( UNITS_PER_METER * 0.2 ); // 80% of two meters
	static public const AVATAR_WIDTH:int = UNITS_PER_METER;
	static public const AVATAR_HEIGHT_FOOT:int = 0;
	static public const AVATAR_HEIGHT_HEAD:Number = AVATAR_HEIGHT;
	static public const AVATAR_HEIGHT_CHEST:int = 20;

	static public const GRAVITY:int = 10;

	static public const VERSION_000:int 		  = 0;
	static public const VERSION_001:int 		  = 1;
	static public const VERSION_002:int 		  = 2;
	static public const VERSION_003:int 		  = 3;
	static public const VERSION_004:int 		  = 4;
	static public const VERSION_005:int 		  = 5;
	static public const VERSION_006:int 		  = 6;
	static public const VERSION_007:int 		  = 7;
	static public const VERSION_008:int 		  = 8;
	static public const VERSION_009:int 		  = 9;
	static public const VERSION:int 			  = VERSION_009;

	static public const MANIFEST_VERSION:int = 100;

	public static var g_underwater:Boolean
	public static var g_oxelBreakEnabled:Boolean
	public static var g_oxelBreakData:GrainCursor = new GrainCursor()
	public static function oxelBreakDataSet( $gc:GrainCursor ):void { g_oxelBreakData.bound = $gc.grain; g_oxelBreakData.set_values( $gc.grainX, $gc.grainY, $gc.grainZ, $gc.grain ); g_oxelBreakEnabled = true }
	public static function oxelBreakDataReset():void { g_oxelBreakData.set_values( 0,0,0,0 ); g_oxelBreakEnabled = false }

	public static var g_landscapeTaskController:TaskController = new TaskController();
	public static var g_flowTaskController:TaskController =  new TaskController();
	public static var g_lightTaskController:TaskController =  new TaskController();

	public static var GAME_ID:String = "voxelverse-lpeje46xj0krryqaxq0vog";
	public static var GAME_ID_DEV:String = "voxelversedev-yeiensar20ofthu906l6ma"
	//public static var g_gamesNetworkID:String = "servertestgame-co3lwnb10a4ytwvxddjtq";

	private static var g_debug:Boolean  = false;
	public static function get isDebug():Boolean  { return g_debug };
	public static function set setDebug( $val:Boolean ):void  { g_debug = $val };

	public static const CATEGORY_METAL:String				= "METAL";
	public static const CATEGORY_LEATHER:String				= "LEATHER";
	public static const CATEGORY_PLANT:String				= "PLANT";

	public static const MODIFIER_DAMAGE:String				= "DAMAGE";
	public static const MODIFIER_SPEED:String				= "SPEED";
	public static const MODIFIER_DURABILITY:String			= "DURABILITY";
	public static const MODIFIER_LUCK:String				= "LUCK";

	// code throws an exception when WRITE or READ is done from this object
	public static const BAD_OXEL:OxelBad = new OxelBad();



	static private const PLANE_INWARD_FACING:int = -1;
	static private const PLANE_OUTWARD_FACING:int = 1;

	public static const AXIS_X:uint = 0;
	public static const AXIS_Y:uint = 1;
	public static const AXIS_Z:uint = 2;

	public static const POSX:uint = 0;
	public static const NEGX:uint = 1;
	public static const POSY:uint = 2;
	public static const NEGY:uint = 3;
	public static const POSZ:uint = 4;
	public static const NEGZ:uint = 5;
	public static const ALL_DIRS:uint = 6;

	public static var Plane:Array = [  { id: POSX, name: "POSX" }
									 , { id: NEGX, name: "NEGX" }
									 , { id: POSY, name: "POSY" }
									 , { id: NEGY, name: "NEGY" }
									 , { id: POSZ, name: "POSZ" }
									 , { id: NEGZ, name: "NEGZ" }
									 ];

	private static const  g_horizontalDirections:Array = [ Globals.POSX, Globals.NEGX, Globals.POSZ, Globals.NEGZ ];
	public static function get horizontalDirections():Array { return g_horizontalDirections; }
	public static function isHorizontalDirection( $val:uint ):Boolean {
		if ( Globals.POSX == $val || Globals.NEGX == $val || Globals.POSZ == $val || Globals.NEGZ == $val )
			return true
		return false
	}

	private static const  g_allButDownDirections:Array = [ Globals.POSY, Globals.POSX, Globals.NEGX, Globals.POSZ, Globals.NEGZ ];
	public static function get allButDownDirections():Array { return g_allButDownDirections; }

	private static const g_adjacentFacesPOSX:Array = [POSY, NEGY, POSZ, NEGZ];
	private static const g_adjacentFacesNEGX:Array = [POSY, NEGY, POSZ, NEGZ];
	private static const g_adjacentFacesPOSY:Array = [POSX, NEGX, POSZ, NEGZ];
	private static const g_adjacentFacesNEGY:Array = [POSX, NEGX, POSZ, NEGZ];
	private static const g_adjacentFacesPOSZ:Array = [POSX, NEGX, POSY, NEGY];
	private static const g_adjacentFacesNEGZ:Array = [POSX, NEGX, POSY, NEGY];
	public static function adjacentFaces( $face:int ):Array
	{
		if ( POSX == $face )
			return g_adjacentFacesPOSX;
		else if ( NEGX == $face )
			return g_adjacentFacesNEGX;
		else if ( POSY == $face )
			return g_adjacentFacesPOSY;
		else if ( NEGY == $face )
			return g_adjacentFacesNEGY;
		else if ( POSZ == $face )
			return g_adjacentFacesPOSZ;
		else ( NEGZ == $face )
			return g_adjacentFacesNEGZ;

		return g_adjacentFacesNEGZ;
	}

	//public static var g_seed:int = 6429;
	//public static var g_seed:int = 1972; // has two water flow voxels
	private static var g_seed:int = 0; // has two water flow voxels
	public static function seed():int { return g_seed; }
	public static function seedSet( val:int ):void { g_seed = val; }

	private static var g_active:Boolean = false; // app is active
	public static function get active():Boolean{ return g_active; }
	public static function set active( val:Boolean ):void { g_active = val; }

	// This eats the first click on the screen when it is activated
//	private static var g_clicked:Boolean = false; // app has been clicked on after an activate has happened
//	public static function get clicked():Boolean { return g_clicked; }
//	public static function set clicked( val:Boolean ):void  { g_clicked = val; }

	private static var g_appPath:String;
	public static function get appPath():String{ return g_appPath; }
	public static function set appPath( val:String ):void
	{
		g_appPath = val;
		g_modelPath = g_appPath + "assets/models/";
		g_soundPath = g_appPath + "assets/sounds/";
		g_regionPath = g_appPath + "assets/regions/";
		g_texturePath = g_appPath + "assets/textures/";
	}

	private static var g_modelPath:String;
	public static function get modelPath():String{ return g_modelPath; }
	private static var g_soundPath:String;
	public static function get soundPath():String { return g_soundPath; }
	private static var g_regionPath:String;
	public static function get regionPath():String { return g_regionPath; }

	private static var g_texturePath:String;
	public static function get texturePath():String { return g_texturePath; }

	public static function isGuid(val:String):Boolean { return 30 < val.length; }
	public static function getUID():String { return GUID.create() }

	private static var g_online:Boolean = false;
	public static function get online():Boolean { return g_online }
	public static function set online(val:Boolean):void { g_online = val; }

	private static var g_inRoom:Boolean = false;
	public static function get inRoom():Boolean { return g_inRoom }
	public static function set inRoom(val:Boolean):void { g_inRoom = val; }

	private static var g_muted:Boolean = false;
	public static function get muted():Boolean { return g_muted }
	public static function set muted(val:Boolean):void { g_muted = val; }

	private static var g_sandbox:Boolean = false;
	public static function get sandbox():Boolean { return g_sandbox }
	public static function set sandbox(val:Boolean):void { g_sandbox = val; }

	public static const MODE_PUBLIC:String = "Public";
	public static const MODE_PRIVATE:String = "Private";
	public static const MODE_MANAGE:String = "Manage";

	private static var g_mode:String = MODE_PUBLIC;
	public static function get mode():String { return g_mode }
	public static function set mode(val:String):void { g_mode = val; }

	private static var g_autoFlow:Boolean = true;
	public static function get autoFlow():Boolean { return g_autoFlow }
	public static function set autoFlow(val:Boolean):void { g_autoFlow = val; }

	private static var _openWindowCount:int = 0;
	static public function get openWindowCount():int { return _openWindowCount; }
	static public function set openWindowCount(value:int):void
	{
		_openWindowCount = value;
		var isAndroid:Boolean = (Capabilities.manufacturer.indexOf("Android") != -1)
		if ( isAndroid )
				return;

		if ( 0 == _openWindowCount ) {
			if ( StageDisplayState.FULL_SCREEN_INTERACTIVE == Globals.g_app.stage.displayState )
				Globals.g_app.stage.mouseLock = true;
		}
		else {
			if ( StageDisplayState.FULL_SCREEN_INTERACTIVE == Globals.g_app.stage.displayState )
				Globals.g_app.stage.mouseLock = false;
		}
		//Log.out( "VoxelVerseGui.openWindowCount - adjust - current count: " + _openWindowCount );
	}
}
}
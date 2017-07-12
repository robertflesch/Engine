/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under uinted States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel
{
import com.voxelengine.events.PersistenceEvent;
import com.voxelengine.pools.FlowInfoPool;

import flash.events.IOErrorEvent;
import flash.events.Event;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.LoadingEvent;
import com.voxelengine.utils.ColorUtils;
import com.voxelengine.utils.StringUtils;
import com.voxelengine.worldmodel.oxel.FlowInfo;

import flash.utils.getTimer;

public class TypeInfo
{
	public static const INVALID:uint						= 0;	//  0
	private static var  enum_val:uint						= 100; // TypeInfo.MIN_TYPE_INFO
	public static const AIR:uint							= enum_val++;	//  100
	public static const GRASS:uint							= enum_val++;	//  101
	public static const DIRT:uint							= enum_val++;	//  102
	public static const SAND:uint							= enum_val++;	//  103
	public static const STONE:uint							= enum_val++;	//  104
	public static const GRAVEL:uint							= enum_val++;	//  105
	public static const PLANK:uint							= enum_val++;	//  106
	public static const WATER:uint							= enum_val++;	//  107
	public static const MIST:uint							= enum_val++;	//  108
	public static const LEAF:uint							= enum_val++;	//  109
	public static const BARK:uint							= enum_val++;	//  110
	public static const LAVA:uint							= enum_val++;	//  111
	public static const RED:uint							= enum_val++;	// 112
	public static const BLUE:uint							= enum_val++;	// 113
	public static const GREEN:uint							= enum_val++;	// 114
	public static const CLOUD:uint							= enum_val++;	// 115
	public static const BALLOON:uint						= enum_val++;	// 116
	public static const ROPE:uint							= enum_val++;	// 117
	public static const IRON:uint							= enum_val++;	// 118
	public static const WHITE:uint							= enum_val++;	// 119
	public static const STONE_WALL:uint						= enum_val++;	// 120
	public static const COPPER:uint							= enum_val++;	// 121
	public static const BRONZE:uint							= enum_val++;	// 122
	public static const STEEL:uint							= enum_val++;	// 123
	public static const GLASS:uint							= enum_val++;	// 124
	public static const NO_QUADS:uint						= enum_val++;	// 125;
	public static const BRANCH:uint							= enum_val++;	// 126;
	public static const FIRE:uint							= 145;
	public static const VINE:uint							= 152;
	public static const CUSTOM_GLASS:uint					= 167;
// NO MORE!!

	// WARNING use sparingly
	static public function getTypeId( type:* ):int	{
		if ( type is int )
			return type;
		else if ( type is Number )
			return (type as int);
		else if ( type is String )
		{
			var typeString:String = type.toUpperCase();
			var ti:TypeInfo = typeInfoByName[ typeString ];
			if ( ti )
				return ti.type;
			//for ( var i:int = TypeInfo.MIN_TYPE_INFO; i < TypeInfo.MAX_TYPE_INFO; i++ )
			//{
				//
				//if ( TypeInfo.typeInfo[i] && ( typeString == TypeInfo.typeInfo[i].name.toUpperCase() ) )
					//return TypeInfo.typeInfo[i].type;
			//}
		}

		Log.out( "TypeInfo.getTypeId - WARNING - INVALID type found: " + type, Log.WARN );

		return AIR;
	}

	public static var typeInfo:Vector.<TypeInfo> = new Vector.<TypeInfo>(1024);
	public static var typeInfoByName:Array = new Array;

	[inline]
	static public function name( type:int ):String { return typeInfo[type].name; }

	[inline]
	static public function flowable( type:int ):Boolean { return typeInfo[type].flowable; }

	[inline]
	static public function changeType( type:int ):uint { return typeInfo[type]._changeType; }

	[inline]
	static public function drawable( type:int ):Boolean { return (( typeInfo[type].solid || typeInfo[type].alpha ) ? true: false); }

	[inline]
	static public function hasAlpha( type:int ):Boolean {  return typeInfo[type].alpha; }

	[inline] // solid is a collidable object
	static public function isSolid( type:int ):Boolean { return  typeInfo[type].solid;	}

	[inline]
	static public function isLight( type:int ):Boolean { return (typeInfo[type].lightInfo.lightSource) }

	static public const MIN_TYPE_INFO:uint = 100;
	static public const MAX_TYPE_INFO:uint = 1024;

	//////////////////////////////////////////////////////////////////////////////////////////////
	private var _typeId:uint				= TypeInfo.INVALID;
	private var _changeType:uint			= TypeInfo.AIR;
	private var _category:String 			= "INVALID";
	private var _subCat:String 				= "INVALID";

	private var _maxpix:uint 				= 256;
	private var _minpix:uint 				= 1;
	private var _toptt:int					= TileType.TILE_FIXED;
	private var _ut:Number					= 0;
	private var _vt:Number					= 0;
	private var _sidett:int					= TileType.TILE_FIXED;
	private var _us:Number					= 0;
	private var _vs:Number					= 0;
	private var _bottomtt:int				= TileType.TILE_FIXED;
	private var _ub:Number					= 0;
	private var _vb:Number					= 0;
	private var _solid:Boolean 				= true;
	private var _animated:Boolean 			= false;
	private var _placeable:Boolean  		= true;

	private var _flammable:Boolean 			= false;
	private var _flame:Boolean  			= false;
	private var _spreadInterval:int			= 1000; // ms
	private var _spreadChance:int			= 100;
	private var _burnTime:int				= 10;

	private var _interactions:Interactions 	= null;

	private var _flowable:Boolean 			= false;
	private var _flowInfo:FlowInfo 			= FlowInfoPool.poolGet();
	private var _flowScalable:Boolean		= true;

	private var _lightInfo:Light  			= new Light();
	private var _color:uint					= 0xffffffff;
	private var _damage:Number				= 1;

	private var _speed:Number				= 1;
	private var _durability:Number			= 1;
	private var _luck:Number				= 1;

	private var _countColor:uint			= 0x00ffffff; // the color to be used to show how many of this object exist
	private var _name:String				= "";
	private var _image:String				= "Invalid.png";
	private var _alpha:Boolean				= false;


	public function get interactions():Interactions { return _interactions; }
	public function get type():uint 		{ return _typeId; }
	public function get alpha():Boolean 	{
		if ( _alpha )
			return true;
		else if ( ColorUtils.extractAlpha( _color ) != 255 )
			return true;
		else
			return false;
	}
	public function get category():String 		{ return _category; }
	public function get subCat():String 		{ return _subCat; }
	public function get flowInfo():FlowInfo		{ return _flowInfo; }
	public function get placeable():Boolean 	{ return _placeable; }

	public function get lightInfo():Light 		{ return _lightInfo; }

	public function get flame():Boolean 		{ return _flame; }
	public function get flammable():Boolean 	{ return _flammable }
	public function get spreadInterval():int	{ return _spreadInterval }
	public function get burnTime():int			{ return _burnTime }
	public function get spreadChance():int		{ return _spreadChance }

	public function get solid():Boolean 		{ return _solid; }
	public function get flowable():Boolean 		{ return _flowable; }
	public function get animated():Boolean 		{ return _animated; }
	public function get color():uint	 		{ return _color; }
	public function get maxpix():uint 			{ return _maxpix; }
	public function get minpix():uint 			{ return _minpix; }
	public function set minpix(val:uint):void	{ _minpix = val; }
	public function get ut():Number				{ return _ut; }
	public function get vt():Number				{ return _vt; }
	public function get us():Number				{ return _us; }
	public function get vs():Number				{ return _vs; }
	public function get ub():Number				{ return _ub; }
	public function get vb():Number				{ return _vb; }
	public function get top():uint 				{ return _toptt; }
	public function get bottom():uint 			{ return _bottomtt; }
	public function get side():uint 			{ return _sidett; }

	public function get damage():Number { return _damage; }
	public function get speed():Number { return _speed; }
	public function get durability():Number { return _durability; }
	public function get luck():Number { return _luck; }
	public function get countColor():uint {return _countColor;}
	public function get name():String { return _name; }
	public function get image():String { return _image; }

	public function TypeInfo( $typeId:int ):void {
		_typeId = $typeId;
		//super( ObjectInfo.OBJECTINFO_VOXEL );
	}

	public function getJSON():String
	{
		var typesJson:String = "{\"model\":";
		typesJson += JSON.stringify( this );
		typesJson +=  "}";

		return typesJson;
	}

	public function toString():String {
		return "TypeInfo - TYPE: " + _typeId + " CLASS: " + _category + " NAME: " + _name + " color:" + color + " Solid: " + solid + " MAXPIX: " + _maxpix + " UT: " + _ut + " VT: " + _vt + " Image: " + image;
	}

	static private var _fileName:String;
	static public function load( $fileName:String ):void {
		PersistenceEvent.addListener( PersistenceEvent.LOAD_SUCCEED, loadSucceed );
		PersistenceEvent.addListener( PersistenceEvent.LOAD_FAILED, loadFail );
		PersistenceEvent.addListener( PersistenceEvent.LOAD_NOT_FOUND, loadFail );

		_fileName = $fileName;
		PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_REQUEST, 0, Globals.APP_EXT, $fileName, null, null ) );

		function loadSucceed(e:PersistenceEvent):void {
			PersistenceEvent.removeListener( PersistenceEvent.LOAD_SUCCEED, loadSucceed );
			PersistenceEvent.removeListener( PersistenceEvent.LOAD_FAILED, loadFail );
			PersistenceEvent.removeListener( PersistenceEvent.LOAD_NOT_FOUND, loadFail );

			Log.out( "TypeInfo.loadSucceed: " + Globals.appPath + $fileName + Globals.APP_EXT, Log.INFO );

			loadTypeDataFromJSON( e.data as String );
		}

		function loadFail(e:PersistenceEvent):void {
			PersistenceEvent.removeListener( PersistenceEvent.LOAD_SUCCEED, loadSucceed );
			PersistenceEvent.removeListener( PersistenceEvent.LOAD_FAILED, loadFail );
			PersistenceEvent.removeListener( PersistenceEvent.LOAD_NOT_FOUND, loadFail );
			Log.out("TypeInfo.load.loadFail: " + e.toString(), Log.ERROR);
		}
	}

	static public function errorAction(e:IOErrorEvent):void
	{
		Log.out("TypeInfo.errorAction: " + e.toString(), Log.ERROR);
	}

	static private function onTypesLoadedAction(event:Event):void
	{
		var jsonString:String = StringUtils.trim(String(event.target.data));
		loadTypeDataFromJSON( jsonString );
	}

	static private function loadTypeDataFromJSON( $data:String ):void {
		//Log.out( "TypeInfo.loadTypeDataFromJSON - loading", Log.WARN );
		var timer:int = getTimer();
		var ti:TypeInfo = new TypeInfo( 0 );
		ti._typeId = 0;
		ti._category = "INVALID";
		ti._name = "INVALID";
		ti._solid = false;
		ti._placeable = false;
		TypeInfo.typeInfo[ti._typeId] = ti;
		TypeInfo.typeInfoByName[ti.name.toUpperCase()] = ti;


		try
		{
			var result:Object = JSON.parse( $data );
			var types:Object = result.types;
			for each ( var v:Object in types )
			{
				ti = new TypeInfo( v.id );
				ti.init( v );
				TypeInfo.typeInfo[ti._typeId] = ti;
				TypeInfo.typeInfoByName[ti.name.toUpperCase()] = ti;
			}

			LoadingEvent.create( LoadingEvent.LOAD_TYPES_COMPLETE );
		}
		catch ( error:Error )
		{
			throw new Error( "TypeInfo.onTypesLoadedAction - - unable to PARSE types.json" );
		}
		//Log.out( "TypeInfo.loadTypeDataFromJSON - took: " + (getTimer() - timer), Log.WARN );
	}

	public function init( $json:Object ):void
	{
		if ( !$json.id  )
			throw new Error( "TypeInfo.init - WARNING - unable to find type id: " + JSON.stringify($json) );
		_typeId = $json.id;

		if ( !$json.category  )
			throw new Error( "TypeInfo.init - WARNING - unable to find category: " + JSON.stringify($json) );
		_category = $json.category;

		if ( $json.subCat  )
			_subCat = $json.subCat.toLowerCase();

		if ( !$json.name  )
			throw new Error( "TypeInfo.init - WARNING - unable to find name: " + JSON.stringify($json) );
		_name = $json.name;

		if ( !$json.image  )
			throw new Error( "TypeInfo.init - WARNING - unable to find name: " + JSON.stringify($json) );
		_image = $json.image;

		if ( $json.countColor  )
			_countColor = $json.countColor;

		if ( $json.color  )
		{
			_color = ColorUtils.placeRedNumber( _color, $json.color.r );
			_color = ColorUtils.placeGreenNumber( _color, $json.color.g );
			_color = ColorUtils.placeBlueNumber( _color, $json.color.b );
			_color = ColorUtils.placeAlphaNumber( _color, $json.color.a );
		}

		if ( $json.uv )
		{
			if ( $json.uv.maxpix )
				_maxpix = $json.uv.maxpix;
			if ( $json.uv.minpix )
				_minpix = $json.uv.minpix;
			if ( $json.uv.top )
				_toptt = $json.uv.top;
			_ut = $json.uv.ut;
			_vt = $json.uv.vt;
			if ( $json.uv.side )
				_sidett = $json.uv.side;
			_us = $json.uv.us;
			_vs = $json.uv.vs;
			if ( $json.uv.bottom )
				_bottomtt = $json.uv.bottom;
			_ub = $json.uv.ub;
			_vb = $json.uv.vb;
		}

		if ( $json.stats )
		{
			if ( $json.stats.damage )
				_damage = $json.stats.damage;
			if ( $json.stats.speed )
				_speed = $json.stats.speed;
			if ( $json.stats.durability )
				_durability = $json.stats.durability;
			if ( $json.stats.luck )
				_luck = $json.stats.luck;
		}

		if ( $json.interactions )
		{
			_interactions = new Interactions( _name );
			_interactions.fromJson( $json.interactions );
		}
		else
		{
//				Log.out( "TypeInfo.init - No interactions defined for type " + _name, Log.WARN );
			_interactions = new Interactions( _name );
			_interactions.setDefault();
		}

		if ( $json.alpha )
		{
			if ( true ==  $json.alpha )
				_alpha = true;
			else
				_alpha = false;
		}

		if ( $json.solid )
		{
			if ( "true" ==  $json.solid.toLowerCase() )
				_solid = true;
			else
				_solid = false;
		}
		if ( $json.flowable )
		{
			_flowable = true;
			_flowInfo.fromJson( $json.flowable );
			if ( $json.flowable[3] )
				_spreadInterval = $json.flowable[3];
			if ( $json.flowable[4] )
				_flowScalable = $json.flowable[4]
			if ( $json.flowable[5] )
				_changeType = $json.flowable[5]
		}
		else
		{
			_flowable = false;
		}

		if ( $json.flammable )
		{
			_spreadChance = $json.flammable[0]
			_burnTime = $json.flammable[1];
			_flammable = true;
		}
		else
		{
			_flammable = false;
		}

		if ( $json.animated )
		{
			if ( "true" ==  $json.animated.toLowerCase() )
				_animated = true;
			else
				_animated = false;
		}
		if ( $json.placeable )
		{
			if ( "true" ==  $json.placeable.toLowerCase() )
				_placeable = true;
			else
				_placeable = false;
		}
		if ( $json.light )
		{
			if ( $json.light.lightSource )
				if ( "true" ==  $json.light.lightSource.toLowerCase() )
					_lightInfo.lightSource = true;

			if ( $json.light.attn )
				_lightInfo.attn = $json.light.attn;

			if ( $json.light.color )
				_lightInfo.color = $json.light.color;

			if ( $json.light.fullBright )
				if ( "true" ==  $json.light.fullBright.toLowerCase() )
					_lightInfo.fullBright = true;

			if ( $json.light.fallOffFactor )
				_lightInfo.fallOffFactor = $json.light.fallOffFactor;
		}
		if ( $json.flame )
		{
			if ( "true" ==  $json.flame.toLowerCase() )
				_flame = true;
			else
				_flame = false;
		}
	}
}
}
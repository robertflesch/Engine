/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel
{
	import flash.geom.Vector3D;

	import flash.events.IOErrorEvent;
	import flash.text.TextField; 
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLLoaderDataFormat;
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.events.LoadingEvent;
	import com.voxelengine.utils.ColorUtils;
	import com.voxelengine.utils.StringUtils;	
	import com.voxelengine.worldmodel.inventory.ObjectInfo;
	import com.voxelengine.worldmodel.oxel.Lighting;
	import com.voxelengine.worldmodel.oxel.FlowInfo;
	/**
	 * ...
	 * @author Bob
	 */
	public class TypeInfo extends ObjectInfo
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
		public static const UNUSED_1:uint						= enum_val++;	// 119
		public static const STONE_WALL:uint						= enum_val++;	// 120
		public static const COPPER:uint							= enum_val++;	// 121
		public static const BRONZE:uint							= enum_val++;	// 122
		public static const STEEL:uint							= enum_val++;	// 123
		public static const GLASS:uint							= enum_val++;	// 124
		public static const EDITCURSOR_SQUARE:uint				= 1000;
		public static const EDITCURSOR_ROUND:uint				= 1001;
		public static const EDITCURSOR_CYLINDER:uint			= 1002;
		public static const EDITCURSOR_CYLINDER_ANIMATED:uint	= 1003;
		// NO MORE!!
		
		// WARNING use sparingly
		static public function getTypeId( type:* ):int
		{
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
			
			return AIR
		}
		
		public static var typeInfo:Vector.<TypeInfo> = new Vector.<TypeInfo>(1024);
		public static var typeInfoByName:Array = new Array;
		
		static public function drawable( type:int ):Boolean
		{
			if ( typeInfo[type].solid || typeInfo[type].alpha )
				return true;
			return false;
		}
		
		// This ideally should be define by texture, but then it is very hard to operate on programattically
		static public function hasAlpha( type:int ):Boolean
		{
			if ( typeInfo[type].alpha || AIR == type )
				return true;
			return false;	
		}

		// solid is a collidable object
		static public function isSolid( type:int ):Boolean
		{
			if ( typeInfo[type].solid )
				return true;
			return false;	
		}
		
		
		
		static public const MIN_TYPE_INFO:uint = 100;
		static public const MAX_TYPE_INFO:uint = 1024;

		//////////////////////////////////////////////////////////////////////////////////////////////
		private var _typeId:uint				= TypeInfo.INVALID;
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
		private var _flowable:Boolean 			= false;
		private var _animated:Boolean 			= false;
		private var _placeable:Boolean  		= true;
		private var _flame:Boolean  			= false;
		private var _interactions:Interactions 	= null;
		private var _flowInfo:FlowInfo 			= null;
		private var _lightInfo:Light  			= new Light();
		private var _color:uint					= 0xffffffff;
		private var _damage:Number				= 1;
		private var _speed:Number				= 1;
		private var _durability:Number			= 1;
		private var _luck:Number				= 1;
		private var _countColor:uint			= 0x00ffffff; // the color to be used to show how many of this object exist
		private var _name:String				= "";
		private var _image:String				= "Invalid.png";
		
		public function get interactions():Interactions { return _interactions; }
		public function get type():uint 		{ return _typeId; }
		public function get alpha():Boolean 		
		{ 
			if ( ColorUtils.extractAlpha( _color ) != 255 ) 
				return true 
			else 
				return false; 
		}
		public function get category():String 		{ return _category; }
		public function get subCat():String 		{ return _subCat; }
		public function get flowInfo():FlowInfo		{ return _flowInfo; }
		public function get placeable():Boolean 	{ return _placeable; }
		
		public function get lightInfo():Light 		{ return _lightInfo; }
		
		public function get flame():Boolean 		{ return _flame; }
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
			super( ObjectInfo.OBJECTINFO_VOXEL );
		}
		
		public function getJSON():String
		{
			var typesJson:String = "{\"model\":";
			typesJson += JSON.stringify( this );			
			typesJson +=  "}"
			
			return typesJson;
		}
		
		public function toString():String {
			return "TypeInfo - TYPE: " + _typeId + " CLASS: " + _category + " NAME: " + _name + " color:" + color + " Solid: " + solid + " MAXPIX: " + _maxpix + " UT: " + _ut + " VT: " + _vt + " Image: " + image;
		}

		static public function loadTypeData( typeName:String ):void
		{
			var urlLoader:URLLoader = new URLLoader();
			//Log.out( "TypeInfo.loadTypeData - loading: " + Globals.appPath + typeName, Log.WARN );
			urlLoader.load(new URLRequest( Globals.appPath + typeName ));
			urlLoader.addEventListener(Event.COMPLETE, onTypesLoadedAction);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, errorAction);			
		}

		static public function errorAction(e:IOErrorEvent):void
		{
			Log.out("TypeInfo.errorAction: " + e.toString(), Log.ERROR);
		}	
		
		static private function onTypesLoadedAction(event:Event):void 
		{
			//Log.out( "TypeInfo.onTypesLoadedAction - loading", Log.WARN );
			var ti:TypeInfo = new TypeInfo( 0 );
			ti._typeId = 0;
			ti._category = "INVALID";
			ti._name = "INVALID";
			ti._solid = false;
			ti._placeable = false;
			TypeInfo.typeInfo[ti._typeId] = ti;
			TypeInfo.typeInfoByName[ti.name.toUpperCase()] = ti;
			
			
			var jsonString:String = StringUtils.trim(String(event.target.data));
			try
			{
				var result:Object = JSON.parse(jsonString);
			}
			catch ( error:Error )
			{
				throw new Error( "TypeInfo.onTypesLoadedAction - - unable to PARSE types.json" );					
			}
			var types:Object = result.types;
			for each ( var v:Object in types )		   
			{
				ti = new TypeInfo( v.id );
				ti.init( v );
				TypeInfo.typeInfo[ti._typeId] = ti;
				TypeInfo.typeInfoByName[ti.name.toUpperCase()] = ti;
			}
			
			Globals.g_app.dispatchEvent( new LoadingEvent( LoadingEvent.LOAD_TYPES_COMPLETE ) );
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
				_maxpix = $json.uv.maxpix;
				_minpix = $json.uv.minpix;
				_toptt = $json.uv.top; 
				_ut = $json.uv.ut;
				_vt = $json.uv.vt;
				_sidett = $json.uv.side; 
				_us = $json.uv.us;
				_vs = $json.uv.vs;
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
				_flowInfo = new FlowInfo();
				_flowInfo.fromJson( $json.flowable );
			}
			else
			{
				_flowable = false;
				_flowInfo = new FlowInfo();
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
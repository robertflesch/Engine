/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel
{
	import com.voxelengine.events.LoadingEvent;
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.utils.ColorUtils;
	import com.voxelengine.worldmodel.models.Attribute;
	import com.voxelengine.worldmodel.oxel.Lighting;
	import com.voxelengine.worldmodel.oxel.FlowInfo;
	import flash.geom.Vector3D;

	import flash.events.IOErrorEvent;
	import mx.utils.StringUtil;
	import flash.text.TextField; 
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLLoaderDataFormat;
	/**
	 * ...
	 * @author Bob
	 */
	public class TypeInfo 
	{
		private var _typeId:uint				= Globals.INVALID;
		private var _category:String 			= "INVALID";
		private var _subCat:String 				= "INVALID";
		private var _name:String 				= "INVALID"

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
		private var _image:String				= "grey64.png";
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
		
		public function set name(val:String):void 	{ _name = val; }
		public function set image(val:String):void 	{ _image = val; }
		
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
		public function get name():String 			{ return _name; }
		public function get image():String 			{ return _image; }
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
		
		public function TypeInfo():void { }
		
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
			var ti:TypeInfo = new TypeInfo();
			ti._typeId = 0;
			ti._category = "INVALID";
			ti._name = "INVALID";
			ti._solid = false;
			ti._placeable = false;
			Globals.Info[ti._typeId] = ti;
			
			
			var jsonString:String = StringUtil.trim(String(event.target.data));
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
				ti = new TypeInfo();
				ti.init( v );
				Globals.Info[ti._typeId] = ti;
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
			
			if ( $json.image  )
				_image = $json.image;

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
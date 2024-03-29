/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.biomes
{
	import com.voxelengine.Log;
	import com.voxelengine.worldmodel.tasks.landscapetasks.*;
	import com.voxelengine.worldmodel.tasks.tests.*;
	import com.voxelengine.worldmodel.TypeInfo;


	/**
	 * ...
	 * @author Robert Flesch
	 */
	public class LayerInfo
	{
		private var _task:Class = null;
		private var _functionName:String = null;
		private var _data:String = "";
		private var _offset:int = 1;
		private var _range:int = 1;
		private var _type:int = TypeInfo.STONE;
		private var _optionalString:String = "";
		private var _optionalInt:int = 0;
		
		public function get task():Class { return _task; }
		public function get functionName():String { return _functionName; }
		public function get data():String { return _data; }
		public function get offset():int { return _offset; }
		public function get range():int { return _range; }
		public function get type():int { return _type; }
		public function set type(val:int):void { _type = val; }
		public function get optionalString():String { return _optionalString; }
		public function set optionalString( $val:String ):void  { _optionalString = $val; }
		public function get optionalInt():int { return _optionalInt; }
		
		public function set offset(value:int):void { _offset = value; }
		public function set range(value:int):void { _range = value; }
		
		public function replaceData( val:String ):void { _data = val; }
		
		public function clone():LayerInfo
		{
			var newLayerInfo:LayerInfo = new LayerInfo( _functionName, _data, _type, _range, _offset, _optionalString, _optionalInt );
			//newLayerInfo._task = _task; // I think this is instance specific - RSF
			
			return newLayerInfo;
		}

		static public function fromObject( $obj:Object ):LayerInfo
		{
			var biomes:Object = $obj.biomes;
			var layer:Object =	biomes.layers[0];
			var grainSize:int;
			if ( $obj.grainSize )
				grainSize = $obj.grainSize;
			else
				grainSize = layer.offset;
			return new LayerInfo( layer.functionName, "", layer.type, 0, grainSize, "", 0 );
		}

		public function LayerInfo( functionName:String = null, data:String = "", type:int = 0 , range:int = 0, offset:int = 0, optional1:String = "", optional2:int = 0 )
		{
			_functionName = functionName;
			if ( _functionName && 0 < _functionName.length )
			{
				if ( 0 <= _functionName.indexOf( "Test" ) )
					_task = TestLibrary.getAsset( _functionName );
				else
					_task = TaskLibrary.getAsset( _functionName );
			}
			_data = data;
			_offset = offset;
			_range = range;
			_type = type;
			_optionalString = optional1;
			_optionalInt = optional2;			
		}
		
		public function fromJSON( layerInfo:Object ):void
		{
			if ( layerInfo.functionName )
			{
				_functionName = layerInfo.functionName;
				//Log.out( "LayerInfo.initJSON loading data for layer - " + _functionName );
				if ( 0 <= _functionName.indexOf( "Test" ) ) {
					_task = TestLibrary.getAsset("GenerateOxel");
					Log.out( "LayerInfo.fromJSON - TEST FUNCTION IN MJSON function name: " + _functionName, Log.WARN );
				}
				else
					_task = TaskLibrary.getAsset( _functionName );
			}
			
			if ( layerInfo.type )
			{
				type = TypeInfo.getTypeId( layerInfo.type );
			}
			
			if ( layerInfo.data )
				_data = layerInfo.data;
			if ( layerInfo.range )
				_range = int(layerInfo.range);
				
			if ( layerInfo.offset )
				_offset = int(layerInfo.offset);
				
			if ( layerInfo.optionalString )
				_optionalString =  layerInfo.optionalString;
		    
			if ( layerInfo.optionalInt )
				_optionalInt =  layerInfo.optionalInt;
				
			if ( layerInfo.oxelRange )
				_optionalInt =  layerInfo.oxelRange;
		}
		
		public function toJSON(k:*):* 
		{ 
			if ( "LoadModelFromIVM" == _functionName )
			{
				return {
						functionName: 	_functionName,
						data: 			_data
						};
			}
 
			if ( 0 == _optionalString.length && 0 == _optionalInt && 0 == _data.length )
			{
				return {
						functionName: 	_functionName,
						offset: 		_offset,
						range: 			_range,
						type: 			_type
						};
			}
			
			// give it all to them!
			return {
				    functionName: 	_functionName,
					data: 			_data,
			        offset: 		_offset,
					range: 			_range,
					type: 			_type,
					optionalString: _optionalString,
					optionalInt: 	_optionalInt
					};
		}
		
		public function toString():String
		{
			return " LayerInfo task: " + _task + " data: " + data + " range: " + range + " offset: " + offset + " type: " + TypeInfo.typeInfo[_type].name + " task: " + task; 
		}
	}
}
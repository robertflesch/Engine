/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.scripts
{
	import com.voxelengine.Log;
	import com.voxelengine.worldmodel.models.types.VoxelModel;

import flash.utils.getQualifiedClassName;

	public class Script
	{
		protected var _name:String = null;
		public function get name():String  						{ return _name; }
		public function set name(val:String ):void 				{ _name = val; }

		protected var _instanceGuid:String = null;
		public function get instanceGuid():String  					{ return _instanceGuid; }
		public function set instanceGuid(val:String ):void 				{ _instanceGuid = val; }

		protected var _modelScript:Boolean; // true if add from modelInfo, false is added from instanceInfo
		public function get modelScript():Boolean  { return _modelScript; }
		public function set modelScript(value:Boolean):void  { _modelScript = value; }

		protected var _vm:VoxelModel; // I hate to add direct link to model, but it saves a ton of searching.
		public function get vm():VoxelModel { return _vm; }
		public function set vm(value:VoxelModel):void { _vm = value; }

		public function Script( $params:Object ){ }

		public function init():void {}
		
		public function dispose():void { 
			_vm = null; 
			_instanceGuid = null;
		}

		public function toString():String {
			Log.out( "This object: " + getCurrentClassName(this) + " does not override toString", Log.WARN );
			return Script.getCurrentClassName(this);
		}

		public function fromObject( $obj:Object):void {
			Log.out( "This object: " + getCurrentClassName(this) + " does not override fromObject", Log.WARN );
		}

		public function fromString( $params:String ):void {
			try {
				var obj:Object = JSON.parse($params);
				if (obj)
					fromObject(obj);
			} catch (e:Error) {
				Log.out( "This object: " + getCurrentClassName(this) + " had an error when parsing is params in fromString params: " + $params, Log.WARN );
			}
		}

		public static function getCurrentClassName(c:Object):String{
			var namePath:String = getQualifiedClassName( c );
			var i:int = namePath.lastIndexOf("::") + 2;
			namePath = namePath.substring(i);
			return namePath;
		}

		public function toObject():Object {
			return {name: getCurrentClassName( this ) , param: paramsObject() };
		}

		protected function paramsObject():Object {
			return { };
		}

		public function paramsString():String {
			return JSON.stringify( paramsObject() );
		}



	}
}

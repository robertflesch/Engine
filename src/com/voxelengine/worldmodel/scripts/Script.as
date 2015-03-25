/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.scripts
{
	import com.voxelengine.Log;
	import com.voxelengine.worldmodel.models.ModelInfo;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	
	/**
	 * ...
	 * @author Robert Flesch - RSF 
	 * 
	 */
	public class Script
	{
		protected var _instanceGuid:String = null;
		protected var _modelScript:Boolean; // true if add from modelInfo, false is added from instanceInfo
		
		public function get instanceGuid():String  					{ return _instanceGuid; }
		public function set instanceGuid(val:String ):void 				{ _instanceGuid = val; }
		
		public function get modelScript():Boolean  { return _modelScript; }
		public function set modelScript(value:Boolean):void  { _modelScript = value; }

		public function Script() 
		{ 
		}
		
		public function processClassJson( modelInfo:ModelInfo ):void {		
			
		}
		
		public function dispose():void { ; }
		
		public function toJSON(k:*):* {
			
			var className:String = getCurrentClassName(this);
			return { name : className }
		}
		
		public static function getCurrentClassName(c:Object):String
			{
				var cString:String = c.toString();
				var cSplittedFirst:Array = cString.split('[object ');
				var cFirstString:String = String(cSplittedFirst[1]);
				var cSplittedLast:Array = cFirstString.split(']');
				var cName:String = cSplittedLast.join('');

				return cName;
			}		
			
		}
}

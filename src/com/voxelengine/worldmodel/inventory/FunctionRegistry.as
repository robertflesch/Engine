/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory
{
import flash.utils.Dictionary;		
import com.voxelengine.Log;
	/**
	 * ...
	 * @author Bob
	 */
	public class FunctionRegistry 
	{
		static private var _nameToFunction:Dictionary = new Dictionary();
		static public function functionAdd( $func:Function, $name:String ):void {
			//Log.out( "FunctionRegistry.functionAdd - adding: " + $name, Log.WARN );
			_nameToFunction[$name] = $func;
		}
		
		static public function functionGet( $name:String ):Function {
			var callBack:Function = _nameToFunction[$name];
			if ( null == callBack )
				Log.out( "FunctionRegistry.functionGet - not found for: " + $name, Log.ERROR );
			return callBack;
		}
		
	} // FunctionRegistry
} // Package
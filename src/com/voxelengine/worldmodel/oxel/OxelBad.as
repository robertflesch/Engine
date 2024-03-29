/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.oxel
{
	import com.voxelengine.worldmodel.TypeInfo;
//
	public class OxelBad extends Oxel {
		public static const INVALID_OXEL:OxelBad = new OxelBad();

		private static var _s_constructed_count:int = 0;
		
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//     Constructor - can only be made once for reference
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		public function OxelBad() {
			// have to be able to construct one!
			super();
			_s_constructed_count++;
			if ( 1 < _s_constructed_count )
				throw new Error("OxelBad - ERROR - construction of OxelBad");
		}
		
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//     Getters/Setters
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		override public function get gc():GrainCursor { throw new Error( "OxelBad - trying to get GC from bad oxel" ); }
		
		override public function get type():int 
		{ 
			throw new Error("OxelBad - ERROR - type - get");
			return TypeInfo.INVALID;
		}
		/*
		override public function set type( val:int, $guid:String ):void 
		{ 
			throw new Error("OxelBad - ERROR - type - set");
		}
*/
		override public function get dirty():Boolean 
		{ 
			throw new Error("OxelBad - ERROR - type - set");
			return true;
		}
		override public function set dirty( isDirty:Boolean ):void 
		{ 
			throw new Error("OxelBad - ERROR - type - set");
		}
	}
}
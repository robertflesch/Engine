/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.utils
{
import com.voxelengine.Log;

public class JSONUtil
{
	static public function parse( $jsonString:String, $fileName:String, $logInfo:String ):Object {
		try {
			var jsonResult:Object = JSON.parse( $jsonString );
		}
		catch ( error:Error ) {
			Log.out("----------------------------------------------------------------------------------" );
			Log.out( $logInfo + " - ERROR PARSING: fileName: " + $fileName + "  data: " + $jsonString, Log.ERROR, error );
			Log.out("----------------------------------------------------------------------------------" );
		}
		return jsonResult;
	}
}
}
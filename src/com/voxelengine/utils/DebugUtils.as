/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.utils {
    
public class DebugUtils
{
	public static function getObjectAddress(obj:*):String {
		try {
			// wrong number of parameters so an exception is thrown.
			// this allow us to grab the address of the object from the stack.
			FakeClass(obj);
		}
		catch (e:Error) {
			var memoryHash:String = String(e).replace(/.*([@|\$].*?) to .*$/gi, '$1');
		}

		return memoryHash;
	}
}
}

internal final class FakeClass { }    
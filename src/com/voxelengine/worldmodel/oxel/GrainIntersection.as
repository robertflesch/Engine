/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.worldmodel.oxel
{
import flash.geom.Vector3D;
import com.voxelengine.worldmodel.models.types.VoxelModel;

public class GrainIntersection
{
	public var point:Vector3D = new Vector3D();
	public var wsPoint:Vector3D = new Vector3D();
	public var invalid:Boolean = false;
	public var oxel:Oxel = null;
	public var model:VoxelModel = null;
	public var gc:GrainCursor = new GrainCursor();
	public var axis:int;
	public var near:Boolean = true;
	
	public final function toString():String
	{
		if ( gc && model )
			return " GCI Info: point: " + point + "   wsPoint: " + wsPoint + " gc: " + gc + " model: " + model.instanceInfo.instanceGuid; 
		if ( gc )
			return " GCI Info: point: " + point + "   wsPoint: " + wsPoint + " gc: " + gc; 
		else			
			return " GCI Info: point: " + point + "   wsPoint: " + wsPoint;
	}
}
}
/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.inventory {
	
import com.voxelengine.events.ModelBaseEvent;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.Matrix;

import org.flashapi.swing.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.layout.AbsoluteLayout;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.InventoryVoxelEvent;
import com.voxelengine.GUI.*;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.inventory.*;
import com.voxelengine.worldmodel.models.ModelMetadataCache;
import com.voxelengine.worldmodel.models.ModelMetadata;


public class BoxTrashCan extends VVBox
{
	private var _count:Label;
	private var _objectInfo:ObjectInfo;
	public function get objectInfo():ObjectInfo { return _objectInfo; }
	
	public function BoxTrashCan( $widthParam:Number, $heightParam:Number, $borderStyle:String = BorderStyle.NONE )
	{
		super( $widthParam, $heightParam, $borderStyle );
		layout = new AbsoluteLayout();
		autoSize = false;
		dragEnabled = true;
	}	
}	

}
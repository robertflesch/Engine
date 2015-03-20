/*==============================================================================
  Copyright 2011-2014 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.events
{
	import flash.events.Event;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	
	/**
	 * ...
	 * @author Robert Flesch - RSF 
	 */
	public class UIRegionModelEvent extends Event
	{
		static public const SELECTED_MODEL_CHANGED:String	= "SELECTED_MODEL_CHANGED";
		static public const SELECTED_MODEL_REMOVED:String	= "SELECTED_MODEL_REMOVED";
		
		private var _voxelModel:VoxelModel;
		private var _parentVM:VoxelModel;
		public function get voxelModel():VoxelModel { return _voxelModel; }
		public function get parentVM():VoxelModel { return _parentVM; }
		
		public function UIRegionModelEvent( $type:String, $vm:VoxelModel, $parentVM:VoxelModel, $bubbles:Boolean = true, $cancellable:Boolean = false )
		{
			super( $type, $bubbles, $cancellable );
			_voxelModel = $vm;
			_parentVM = $parentVM;
		}
		
		public override function clone():Event
		{
			return new UIRegionModelEvent(type, _voxelModel, _parentVM, bubbles, cancelable);
		}
	   
		public override function toString():String
		{
			return formatToString("UIRegionModelEvent", "bubbles", "cancelable") + " instanceGuid: " + _voxelModel.instanceInfo.instanceGuid + "  parentInfo: " + _parentVM ? _parentVM.instanceInfo.modelGuid : "No parent";
		}
		
		
	}
}

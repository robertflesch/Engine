/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.events
{
	import flash.events.Event;
	import flash.utils.ByteArray;
	import com.voxelengine.worldmodel.models.VoxelModelMetadata;
	
	/**
	 * ...
	 * @author Robert Flesch - RSF 
	 */
	public class ModelMetadataEvent extends Event
	{
		static public const INFO_LOADED_PERSISTANCE:String  = "INFO_LOADED_PERSISTANCE";
		static public const INFO_COLLECTED:String  = "INFO_COLLECTED";
		
		private var _vmm:VoxelModelMetadata;

		public function ModelMetadataEvent( $type:String, $vmm:VoxelModelMetadata, $bubbles:Boolean = true, $cancellable:Boolean = false )
		{
			super( $type, $bubbles, $cancellable );
			_vmm = $vmm;
		}
		
		public override function clone():Event
		{
			return new ModelMetadataEvent(type, _vmm, bubbles, cancelable);
		}
	   
		public override function toString():String
		{
			return formatToString("ModelMetadataEvent", "bubbles", "cancelable") + " VoxelModelMetadata: " + _vmm.toString();
		}
		
		public function get vmm():VoxelModelMetadata 
		{
			return _vmm;
		}
		
		
	}
}

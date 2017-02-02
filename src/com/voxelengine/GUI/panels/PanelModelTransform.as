/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.panels
{
import org.flashapi.swing.*
import org.flashapi.swing.event.*
import org.flashapi.swing.constants.*
import org.flashapi.swing.list.ListItem

import com.voxelengine.Log
import com.voxelengine.GUI.components.*
import com.voxelengine.worldmodel.animation.Animation
import com.voxelengine.worldmodel.models.ModelTransform
import com.voxelengine.worldmodel.models.types.VoxelModel;

public class PanelModelTransform extends ExpandableBox
{
	private var _ani:Animation
	private var _mt:ModelTransform
	
	public function PanelModelTransform( $parent:ExpandableBox, $ebco:ExpandableBoxConfigObject ) {		
		_ani = $ebco.rootObject
		_mt = $ebco.item
		if ( null == _mt ) {
			$ebco.item = _mt = ModelTransform.defaultObject()
			$ebco.items.push( _mt )
			_ani.changed = true
		}
		
		$ebco.itemBox.showNew = false
		super( $parent, $ebco )
	}
	
	override protected function yesDelete():void {
		// now I need to iterate thru the items, and find the right one to delete
		var itemSig:String = _mt.toString()
		var mts:Vector.<ModelTransform> = _ebco.items as Vector.<ModelTransform>
		for ( var i:int; i < mts.length; i++ ) {
			var mt:ModelTransform = mts[i]
			// don't add the deleted item to the list
			if ( mt.toString() == itemSig ) {
				mts.splice( i, 1 )
			}
		}
		
		// This could be done via events too
		_parent.changeMode()
		_parent.changeMode()
	}
	
	override protected function collapasedInfo():String  {
		if ( !_mt ) {
			Log.out( "PanelModelTransform.collapsedInfo - null == _mt", Log.ERROR )
			return "PanelModelTransform.collapsedInfo - null == _mt"
		}
			
		if ( ModelTransform.INVALID == _mt.type )
			return "No transforms "
		return ModelTransform.typeToString( _mt.type ) + "  " + _mt.deltaAsString()
	}

	override protected function hasElements():Boolean {
		if ( 0 < _mt.originalDelta.length ) 
			return true
		 
		return false
	}
	
	override protected function expand():void {
		super.expand()
		
		_itemBox.addElement( new ComponentSpacer( _itemBox.width, 4 ) )
		
		_itemBox.addElement( new ComponentComboBoxWithLabel( "Transform type", typeChanged, ModelTransform.typeToString( _mt.type ), ModelTransform.typesList(), _itemBox.width ) )
		_itemBox.addElement( new ComponentLabelInput( "time (ms)"
											  , timeChanged
											  , _mt.originalTime ? String( _mt.originalTime ) : "Missing time"
											  , _itemBox.width - 10 ) )
											  
		_itemBox.addElement( new ComponentVector3DSideLabel( deltaChanged, "delta", "X: ", "Y: ", "Z: ",  _mt.originalDelta, _itemBox.width, updateVal ) )
	}
	
	private function typeChanged( $le:ListEvent ): void {
		var li:ListItem = $le.target.getItemAt( $le.target.selectedIndex )
		 _mt.type = ModelTransform.stringToType( li.value )
		setChanged() 
	}
	
	private function timeChanged($e:TextEvent):void { 
		_mt.originalTime = int ( $e.target.label )
		if ( isNaN( _mt.originalTime ) )
			_mt.originalTime = 1000
		//Log.out( "deltaChanged: " + _mt.originalTime )
		setChanged() 
	}
	
	private function deltaChanged():void { 
		//Log.out( "deltaChanged: " + _mt.originalDelta )
		setChanged() 
	}
	
	override protected function setChanged():void {
		_ani.changed = true
		VoxelModel.selectedModel.stateLock( false );
		VoxelModel.selectedModel.stateReset(); // have to reset first since it is already in this state
		VoxelModel.selectedModel.stateSet( _ani.name, 0 );
		//VoxelModel.selectedModel.updateAnimations( _ani.name, 1 );
		VoxelModel.selectedModel.stateLock( true )
	}
}
}
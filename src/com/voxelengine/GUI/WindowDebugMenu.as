/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI
{
	import com.voxelengine.worldmodel.models.types.EditCursor;
	import com.voxelengine.worldmodel.models.types.Player;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	import com.voxelengine.worldmodel.oxel.GrainCursorIntersection;
	import flash.events.Event;
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.layout.*;
    import org.flashapi.swing.constants.*;
	
	import flash.geom.Vector3D;

	import com.developmentarc.core.tasks.TaskController;	
	
	import com.voxelengine.worldmodel.MemoryManager;
	import com.voxelengine.pools.*;
	import com.voxelengine.renderer.VertexIndexBuilder;
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;	
	public class WindowDebugMenu extends VVCanvas
	{
		static private var _s_currentInstance:WindowDebugMenu = null;
		static public function get currentInstance():WindowDebugMenu { return _s_currentInstance; }
		private var _smids:Vector.<StaticMemoryDisplay> = new Vector.<StaticMemoryDisplay>;
		private var _modelLoc:Label = new Label();
		private var _gcLabel:Label = new Label("grain: 0 x: 0  y: 0  z: 0");

		
		public function WindowDebugMenu():void 
		{ 
			super( 100, 100 );
			_s_currentInstance = this;
			
			//glowColor = "red";
			//glow = true;
			shadow = true;
			
			autoSize = true;
			padding = 0;
			layout.orientation = LayoutOrientation.VERTICAL;
			
			//addButton( "Save ModelIVM"	, Globals.g_gui.saveModelIVM );
			//addButton( "Save ModelMeta"	, Globals.g_gui.saveModelMeta );
			//addButton( "Save Map"	, Globals.g_gui.saveMap );
			
			addSpace();
			addModelLocation();
			
			addSpace();
			addSpace();
			
			addInt( "Total  CPU Mem: ", MemoryManager.currentMemory );
			addInt( "Drawn Oxels:", VertexIndexBuilder.totalOxels );
			addSpace();
			
//			addInt( "Landscape Tasks: ", TaskController.taskCount );
//			addInt( "       Flow Tasks: ", FlowTaskController.taskCount );
//			addSpace();

			addInt( "Used Vertex Buf:", VertexIndexBuilderPool.totalUsed );
			addInt( "Remaining:", VertexIndexBuilderPool.remaining );
			addSpace();
			
			addInt( "GPU Vertex Mem:", VertexIndexBuilder.totalVertexMemory );
			addInt( "GPU Index Mem:", VertexIndexBuilder.totalIndexMemory );
			addSpace();
			
			addInt( "Used Oxels: ", OxelPool.totalUsed );
			addInt( "Remaining: ", OxelPool.remaining );
			addSpace();

			addInt( "Used Neighbors: ", NeighborPool.totalUsed );
			addInt( "Remaining: ", NeighborPool.remaining );
			addSpace();
			
			addInt( "Used ChildVectors:", ChildOxelPool.totalUsed );
			addInt( "Remaining:", ChildOxelPool.remaining );
			addSpace();
			
			addInt( "Used GrainCursor:", GrainCursorPool.totalUsed );
			addInt( "Remaining:", GrainCursorPool.remaining );
			addSpace();
				
			addInt( "Used OxelPool:", OxelPool.totalUsed );
			addInt( "Remaining:", OxelPool.remaining );
			addSpace();
			
			addInt( "Used QuadPool:", QuadPool.totalUsed );
			addInt( "QuadPool:", QuadPool.remaining );
			addSpace();
			
			addInt( "Used ParticlePool:", ParticlePool.totalUsed );
			addInt( "ParticlePool:", ParticlePool.remaining );
			addSpace();

			addInt( "Used ProjectilePool:", ProjectilePool.totalUsed );
			addInt( "ProjectilePool:", ProjectilePool.remaining );
			addSpace();

			addInt( "Land Tasks:", Globals.g_landscapeTaskController.queueSize );
			addInt( "Flow Tasks:", Globals.g_flowTaskController.queueSize );
			addInt( "Light Tasks:", Globals.g_lightTaskController.queueSize );
			addSpace();
			
			addString( "selected model:", null );

			_gcLabel.textAlign = TextAlign.CENTER;
			_gcLabel.textFormat.color = 0xFFFFFF;
			addElement( _gcLabel );
			
			//addStaticMemoryNumberDisplay( _target, 100, 0, "           Total Voxels: ", Quad.count );
			
			display( 0, 240 );	
			
			Globals.g_app.addEventListener( Event.ENTER_FRAME, onEnterFrame );
		} 
		
		private function addInt( title:String, callback:Function ):void
		{
			var smid:StaticMemoryIntDisplay = new StaticMemoryIntDisplay( title, callback );
			smid.width = 200;
			addElement( smid );
			_smids.push( smid );
		}
		
		private function addString( title:String, callback:Function ):void
		{
			var smsd:StaticMemoryStringDisplay = new StaticMemoryStringDisplay( title, callback );
			smsd.width = 200;
			addElement( smsd );
			_smids.push( smsd );
		}
		
		private function addButton( title:String, callback:Function ):void
		{
			var but:Button = new Button( title );
			but.width = 120;
			but.addEventListener(UIMouseEvent.PRESS, callback );
			addElement( but );
		}
		
		private function addSpace():void
		{
			var space:Label = new Label();
			space.height = 10;
			addElement( space );
		}
		
		private function fullScreenHandler(e:UIMouseEvent):void 
		{
			VoxelVerseGUI.currentInstance.toggleFullscreen();
		}
		
		private function onEnterFrame( event:Event ):void
		{
			for each ( var smid:StaticMemoryDisplay in _smids )
			{
				smid.updateFunction();
			}
			
			if ( _modelLoc )
			{
				_modelLoc.text = ""; 
				if ( Player.player )
				{
					var loc:Vector3D = VoxelModel.controlledModel.instanceInfo.positionGet
					_modelLoc.text = "x: " + int( loc.x ) + "  y: " + int( loc.y ) + "  z: " + int( loc.z ); 
				}
			}
			
			updateGC();
		}

		private function updateGC():void
		{
			// TO DO I dont like this direct call into the EditCursor
			if (Globals.g_app && EditCursor.editing ) {
				if ( VoxelModel.selectedModel && EditCursor.currentInstance.gciData )
				{
					var gci:GrainCursorIntersection = EditCursor.currentInstance.gciData;
					var rot:Vector3D = VoxelModel.controlledModel.instanceInfo.rotationGet;
					_gcLabel.text = "grain: " + gci.gc.grain + " x: " + int( gci.gc.grainX ) + "  y: " + int( gci.gc.grainY ) + "  z: " + int( gci.gc.grainZ ); 
				}
			}
		}
		
		private function addModelLocation():void
		{
			addElement( _modelLoc );
		}
		
	}
}

import com.voxelengine.worldmodel.models.types.VoxelModel;
import org.flashapi.swing.Canvas;
import org.flashapi.swing.Label;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.layout.AbsoluteLayout;
import com.voxelengine.GUI.VVCanvas;
class StaticMemoryDisplay extends VVCanvas
{
	public function StaticMemoryDisplay() {
		super( 200, 10 );
	}
	
	public function updateFunction():void {};
}

class StaticMemoryIntDisplay extends StaticMemoryDisplay
{
	private var _prefix:Label = new Label();
	private var _data:Label = new Label();
	private var _value:Function = null;
	static private const PREFIX_WIDTH:int = 90;
	static private const FONT_COLOR:int = 0xffffff;
	
	
	public function StaticMemoryIntDisplay( prefix:String, value:Function ) 
	{
		super();
		_value = value;
		
		layout = new AbsoluteLayout();
		_prefix.textAlign = TextAlign.RIGHT
		_prefix.text = prefix;
		_prefix.width = PREFIX_WIDTH;
		_prefix.x = 0;
		_prefix.y = 0;
		_prefix.fontColor = FONT_COLOR;
		_prefix.fontSize = 10;
		addElement( _prefix );
		_data.textAlign = TextAlign.RIGHT
		_data.width = 60;
		_data.x = PREFIX_WIDTH;
		_data.y = 0;
		_data.fontColor = FONT_COLOR;
		_data.fontSize = 10;
		addElement( _data );
	}
	
	override public function updateFunction():void
	{
		var k:int = _value();
		var result:String = addCommasToLargeInt(k);
		_data.text = result;
	}
	
	public static function addCommasToLargeInt( value:int ):String 
	{
		var answer:String = "";
		var sub:String = "";
		var remainder:String = value.toString();
		var len:int = remainder.length;
		if ( 3 < len )
		{
			for (; 3 < len;) {
				sub = "," + remainder.substr( len - 3, len );
				remainder = remainder.substr( 0, len - 3 );
				len = remainder.length;
				if ( 3 >= len )
					answer = remainder + sub + answer;
				else
					answer = sub + answer;
			}
		}
		else
			answer = remainder;
		
		return answer;
	}
}

import com.voxelengine.Globals;
class StaticMemoryStringDisplay extends StaticMemoryDisplay
{
	private var _prefix:Label = new Label();
	private var _data:Label = new Label();
	private var _value:Function = null;
	static private const PREFIX_WIDTH:int = 90;
	static private const FONT_COLOR:int = 0xffffff;
	
	public function StaticMemoryStringDisplay( prefix:String, value:Function ) 
	{
		super();
		_value = value;
		
		layout = new AbsoluteLayout();
		_prefix.textAlign = TextAlign.RIGHT
		_prefix.text = prefix;
		_prefix.width = PREFIX_WIDTH;
		_prefix.x = 0;
		_prefix.y = 0;
		_prefix.fontColor = FONT_COLOR;
		_prefix.fontSize = 10;
		addElement( _prefix );
		_data.textAlign = TextAlign.RIGHT
		_data.width = 60;
		_data.x = PREFIX_WIDTH;
		_data.y = 0;
		_data.fontColor = FONT_COLOR;
		_data.fontSize = 10;
		addElement( _data );
	}
	
	override public function updateFunction():void
	{
		if ( VoxelModel.selectedModel && VoxelModel.selectedModel.instanceInfo )
			_data.text = VoxelModel.selectedModel.instanceInfo.instanceGuid;
		else	
			_data.text = "";
	}
	
}
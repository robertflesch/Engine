/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.actionBars
{
	import com.voxelengine.GUI.WindowBeastControlQuery;
	import com.voxelengine.GUI.WindowHeading;
	import com.voxelengine.worldmodel.inventory.FunctionRegistry;
	import com.voxelengine.worldmodel.inventory.ObjectAction;
	import com.voxelengine.worldmodel.inventory.ObjectInfo;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	import org.flashapi.swing.core.UIObject;
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.events.RegionEvent;
	import com.voxelengine.events.GUIEvent;
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.worldmodel.*;
	import com.voxelengine.worldmodel.models.VoxelModel;
	import com.voxelengine.worldmodel.animation.Animation;
	import com.voxelengine.worldmodel.weapons.Ammo;
	import com.voxelengine.worldmodel.weapons.Gun;

	// -----------------------------------------------------------
	//  WindowBeastControl.as
	// -----------------------------------------------------------

	/**
	 *  @author Robert Flesch
	 */
	
	public class WindowBeastControl extends ToolBar
	{
		static private var _s_currentInstance:WindowBeastControl = null;
		static public function get currentInstance():WindowBeastControl { return _s_currentInstance; }
		
		// the instance guid of the beast this window controls
		private var _beastInstanceGuid:String;
		private const TOOL_BAR_HEIGHT:int = 140;
		private const ITEM_COUNT:int = 10;
		private var _windowHeading:WindowHeading = null;
		
		static public function handleModelEvents( $me:ModelEvent ):void {
			if ( ModelEvent.TAKE_CONTROL == $me.type ) {
				var classCalled:String = $me.parentInstanceGuid;
				if ( classCalled != "com.voxelengine.worldmodel.models::Player" )
					new WindowBeastControl( $me.instanceGuid );
			}
			else if ( ModelEvent.RELEASE_CONTROL == $me.type ) {
				if ( _s_currentInstance ) {
					_s_currentInstance.remove();
					_s_currentInstance = null;
				}
			}
		}

		public function WindowBeastControl( $beastInstanceGuid:String ) 
		{ 
			_s_currentInstance = this;
			_beastInstanceGuid = $beastInstanceGuid;
			super( "beastToolbar.png" );
			
//			addEventListener(UIOEvent.REMOVED, onRemoved );
			
			_windowHeading = new WindowHeading( _beastInstanceGuid );
		
			if ( WindowBeastControlQuery.currentInstance )
				WindowBeastControlQuery.currentInstance.remove();
			
			// TODO An event is dispatched in a constructor. This is pointless, since event listeners cannot be attached to an object before it has been constructed, so nothing can ever hear the event	
			Globals.g_app.dispatchEvent(new GUIEvent(GUIEvent.TOOLBAR_HIDE));
			
			//visible = false;
			//_windowHeading.visible = false;
//			FunctionRegistry.functionAdd( loseControlBeastWindow, "loseControlBeastWindow" );
//			FunctionRegistry.functionAdd( fireBeastWindow, "fireBeastWindow" );
		} 
		/* THIS NEEDS TO BE REFACTORED SO THAT IT EXTENDS THE QUICKINVENTORY - THAT GIVES IT ALL OF THE DRAG AND DROP AND CLEANER INTERFACE 
		/* THIS NEEDS TO BE REFACTORED SO THAT IT EXTENDS THE QUICKINVENTORY - THAT GIVES IT ALL OF THE DRAG AND DROP AND CLEANER INTERFACE 
		/* THIS NEEDS TO BE REFACTORED SO THAT IT EXTENDS THE QUICKINVENTORY - THAT GIVES IT ALL OF THE DRAG AND DROP AND CLEANER INTERFACE 
		/* THIS NEEDS TO BE REFACTORED SO THAT IT EXTENDS THE QUICKINVENTORY - THAT GIVES IT ALL OF THE DRAG AND DROP AND CLEANER INTERFACE 
		/* THIS NEEDS TO BE REFACTORED SO THAT IT EXTENDS THE QUICKINVENTORY - THAT GIVES IT ALL OF THE DRAG AND DROP AND CLEANER INTERFACE 
		/* THIS NEEDS TO BE REFACTORED SO THAT IT EXTENDS THE QUICKINVENTORY - THAT GIVES IT ALL OF THE DRAG AND DROP AND CLEANER INTERFACE 
		/* THIS NEEDS TO BE REFACTORED SO THAT IT EXTENDS THE QUICKINVENTORY - THAT GIVES IT ALL OF THE DRAG AND DROP AND CLEANER INTERFACE 
		/* THIS NEEDS TO BE REFACTORED SO THAT IT EXTENDS THE QUICKINVENTORY - THAT GIVES IT ALL OF THE DRAG AND DROP AND CLEANER INTERFACE 
		// This function sets the underlying data to the selected info. But does not act on that info.
		override public function processItemSelection( box:UIObject ):void 	{
			
			if ( !box || !box.data )
				return;
				
			var actionItem:Object = box.data;
			if ( actionItem.callback == loseControlBeastWindow )
			{
				return;
			}
			else if ( actionItem.callback == fireBeastWindow )
			{
				var gun:Gun = Globals.modelGet( actionItem.modelGuid ) as Gun;
				gun.ammo = actionItem.ammo;
				//Log.out( "WindowBeastControl.processItemSelection - setting Ammo to: " + actionItem.ammo.name );
			}
		}
		
		override public function activateItemSelection( box:UIObject ):void 	{
			
			var actionItem:Object = box.data as Object;
			if ( actionItem )
			{
					if ( actionItem.callback == loseControlBeastWindow )
					{
						loseControlBeastWindow();
					}
					else if ( actionItem.callback == fireBeastWindow )
					{
						var gmInstanceGuid:String = actionItem.modelGuid;
						var gun:Gun = Globals.modelGet( gmInstanceGuid ) as Gun;
						if ( gun )
							gun.fire();
					}
			}
		}
		
		// This is called when the toolbar image is loaded.
		override public function buildActions():void {
			Log.out( "WindowBeastControl.buildActions" );
			_itemInventory.name = "ItemSelector";
			
			var box:Box = null;
			var count:int = 0;
			var dismountItem:ObjectAction = new ObjectAction( "loseControlBeast", "dismount.png", "Dismount" );
			box = buildAction( dismountItem, count++ );
			
			var beast:VoxelModel = Globals.modelGet( _beastInstanceGuid );
			if ( beast )
			{
				for each ( var cm:VoxelModel in beast.children )
				{
					if ( cm is Gun )
					{
						var gm:Gun = cm as Gun;
						for each ( var ammo:Ammo in gm.armory )
						{
							var actionItem:ObjectInfo = new ObjectAction( 
								"fireBeastWindow",
								ammo.name + ".png",
								"Fire " + ammo.name
							);
							actionItem["ammo"] = ammo;
							actionItem["modelGuid"] = gm.instanceInfo.guid;
							box = buildAction( actionItem, count++ );
						}
					}
				}
			}

			// fill in with blanks for now.
			for  ( ; count < ITEM_COUNT;  )
				buildAction( null, count++ );
			
			_itemInventory.addSelector();			
			
			_itemInventory.width = ITEM_COUNT * IMAGE_SIZE;
			_itemInventory.display();
			
			if ( box )
			{
				_itemInventory.moveSelector( box.x );
				processItemSelection( box );
			}
			else
			{
				throw new Error( "WindowBeastControl.buildActions - NO Actions built" );
				_lastItemSelection = 0;
			}
			
			VoxelVerseGUI.currentInstance.crossHairHide();
		}
		
		private function loseControlKey(e:KeyboardEvent):void {
			if ( Keyboard.F == e.keyCode )
				loseControlBeastWindow();
		}
		
		static private function fireBeastWindow():void {
			// placeholder ONLY
			// TODO will be used to act as reload timer

			//event.target.enabled = false;
			//var reloadTimer:DataTimer = new DataTimer( 5000, 1 );
			//reloadTimer.label = event.target.label;
			//reloadTimer.button = event.target as Button;
			//event.target.label = "Reloading";
			//reloadTimer.addEventListener(TimerEvent.TIMER, onRepeat);
			//reloadTimer.start();
		}
		
		static private function loseControlBeastWindow():void {
			var vm:VoxelModel = Globals.modelGet( Globals.controlledModel.instanceInfo.guid );
			if ( vm )
				vm.loseControl( Globals.player );
			else
				Log.out( "WindowBeastControl.loseControl - VM not found: " + Globals.controlledModel.instanceInfo.guid, Log.ERROR );
				
// TODO
Log.out( "WindowBeastControl.loseControl - NEED WAY TO REMOVE SUPPORT WINDOWS", Log.ERROR );
//			_windowHeading.remove();
//			remove();
		}
		
		// Window events
		private function onRemoved( event:UIOEvent ):void {
			removeEventListener(UIOEvent.REMOVED, onRemoved );
			if ( _windowHeading )
				_windowHeading.remove();
			_s_currentInstance = null;
		}
		*/
	}
	
}
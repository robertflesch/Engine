
package com.voxelengine.GUI
{
	import com.voxelengine.worldmodel.RegionManager;
	import flash.events.MouseEvent;
	import flash.geom.Vector3D;
	import org.flashapi.collector.EventCollector;
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.events.RegionEvent;
	import com.voxelengine.worldmodel.Region;
	import com.voxelengine.worldmodel.models.InstanceInfo;
	import com.voxelengine.worldmodel.models.VoxelModel;
	import com.voxelengine.GUI.components.*;

	
	public class WindowModelDetail extends VVPopup
	{
		static private var _s_inExistance:int = 0;
		static private var _s_currentInstance:WindowModelDetail = null;
		
		private var _eventCollector:EventCollector = new EventCollector();
		private var _panelAdvanced:Panel;
		
		private var _vm:VoxelModel = null;
		private var _ii:InstanceInfo = null;
		
		private static const BORDER_WIDTH:int = 4;
		private static const BORDER_WIDTH_2:int = BORDER_WIDTH * 2;
		private static const BORDER_WIDTH_3:int = BORDER_WIDTH * 3;
		private static const BORDER_WIDTH_4:int = BORDER_WIDTH * 4;
		private static const PANEL_HEIGHT:int = 115;
		
		private var _calculatedWidth:int = 300;
		private var _calculatedHeight:int = 20;

		static public function get inExistance():int { return _s_inExistance; }
		static public function get currentInstance():WindowModelDetail { return _s_currentInstance; }
		
		public function WindowModelDetail( $vm:VoxelModel )
		{
			super( "Model Details" );
			width = 300;
			padding = 0;

			_s_inExistance++;
			_s_currentInstance = this;
			
			_vm = $vm;
			_ii	= _vm.instanceInfo;
			
			onCloseFunction = closeFunction;
			defaultCloseOperation = ClosableProperties.CALL_CLOSE_FUNCTION;
			layout.orientation = LayoutOrientation.VERTICAL;
            autoSize = true;
			shadow = true;
			
			addElement( new ComponentSpacer( width ) );
			addElement( new ComponentTextInput( "Name"
			                                  , function ($e:TextEvent):void { _vm.metadata.name = $e.target.text; }
											  , _vm.metadata.name
											  , width ) );
			addElement( new ComponentTextArea( "Desc"
											 , function ($e:TextEvent):void { _vm.metadata.description = $e.target.text; }
											 , _vm.metadata.description ? _vm.metadata.description : "No Description"
											 , width ) );

			// TODO need to be able to handle an array of scipts.
			//addElement( new ComponentTextInput( "Script",  function ($e:TextEvent):void { _ii.scriptName = $e.target.text; }, _ii.scriptName, width ) );
			addElement( new ComponentLabel( "Grain Size", String(_ii.grainSize), width ) );
			addElement( new ComponentLabel( "Instance GUID",  _ii.guid, width ) );
			if ( _vm.anim )
				// TODO add a drop down of available states
				addElement( new ComponentLabel( "State", _vm.anim ? _vm.anim.name : "", width ) );
				
			if ( _ii.controllingModel )
				addElement( new ComponentLabel( "Parent GUID",  _ii.controllingModel ? _ii.controllingModel.instanceInfo.guid : "", width ) );
//
			addElement( new ComponentVector3D( "Position", "X: ", "Y: ", "Z: ",  _ii.positionGet, _ii ) );
			addElement( new ComponentVector3D( "Rotation", "X: ", "Y: ", "Z: ",  _ii.rotationGet, _ii ) );
			addElement( new ComponentVector3D( "Center", "X: ", "Y: ", "Z: ",  _ii.center, _ii ) );
			addElement( new ComponentVector3D( "Scale", "X: ", "Y: ", "Z: ",  _ii.scale, _ii, updateScaleVal, 5 ) );
			
//			if ( true == Globals.g_debug )
//			{
				var oxelUtils:Button = new Button( LanguageManager.localizedStringGet( "Oxel_Utils" ) );
				oxelUtils.addEventListener(UIMouseEvent.CLICK, oxelUtilsHandler );
				//oxelUtils.width = pbWidth - 2 * pbPadding;
				addElement( oxelUtils );
//			}
			
			display( 600, 20 );
        }
		
		static private function updateScaleVal( $e:SpinButtonEvent ):Number {
			var ival:Number = Number( $e.target.data.text );
			if ( SpinButtonEvent.CLICK_DOWN == $e.type ) 	ival = ival/2;
			else 											ival = ival*2;
			$e.target.data.text = ival.toString();
			return ival;
		}
		
		
		private function oxelUtilsHandler(event:UIMouseEvent):void  {

			if ( _vm )
				new WindowOxelUtils( _vm );
		}
		
		private function closeFunction():void
		{
			_s_inExistance--;
			_s_currentInstance = null;
			
			Globals.g_app.dispatchEvent( new ModelEvent( ModelEvent.MODEL_MODIFIED, _ii.guid ) );
			RegionManager.dispatch( new RegionEvent( RegionEvent.REGION_MODIFIED, "" ) );
		}
		

		private function changeStateHandler(event:TextEvent):void {
			var vm:VoxelModel = Globals.getModelInstance( _ii.guid )
			var state:String = event.target.text;
			vm.stateLock( false );
			vm.stateSet( state );
			vm.stateLock( true );
		}

		private function updateVal( $e:SpinButtonEvent ):int {
			var ival:int = int( $e.target.data.text );
			if ( "clickDown" == $e.type ) 	ival--;
			else 								ival++;
			$e.target.data.text = ival.toString();
			return ival;
		}

        private function close(e:MouseEvent):void { setHeight(0); }
        private function open():void { setHeight(20); }
  
        private function setHeight(height:Number):void {
			
			//_GrainSize.height = height;
			//_InstanceGUID.height = height;
			//_ModelGUID.height = height;
			//_Parent.height = height;
			//_Script.height = height;
			//_Texture.height = height;
			//_TextureScale.height = height;
			//_ModelClass.height = height;
			_panelAdvanced.height = 20;
            //_image.height = height;
            //_.label = height == 0 ? "Double click to open" : "Double click to close";
        }		
		
	}
}
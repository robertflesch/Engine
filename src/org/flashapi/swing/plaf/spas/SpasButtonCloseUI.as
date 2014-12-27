////////////////////////////////////////////////////////////////////////////////
//    
//    Swing Package for Actionscript 3.0 (SPAS 3.0)
//    Copyright (C) 2004-2011 BANANA TREE DESIGN & Pascal ECHEMANN.
//    
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//    
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//    GNU General Public License for more details.
//    
//    You should have received a copy of the GNU General Public License
//    along with this program. If not, see <http://www.gnu.org/licenses/>.
//    
////////////////////////////////////////////////////////////////////////////////

package org.flashapi.swing.plaf.spas {
	
	// -----------------------------------------------------------
	// SpasButtonCloseUI.as
	// -----------------------------------------------------------

	/**
	* @author Pascal ECHEMANN
	* @version 1.0.3, 20/05/2009 02:08
	* @see http://www.flashapi.org/
	*/
	
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Transform;
	import org.flashapi.swing.color.RGB;
	import org.flashapi.swing.constants.ButtonState;
	import org.flashapi.swing.constants.StateObjectValue;
	import org.flashapi.swing.constants.TextureType;
	import org.flashapi.swing.draw.Figure;
	import org.flashapi.swing.draw.MatrixUtil;
	import org.flashapi.swing.managers.TextureManager;
	import org.flashapi.swing.plaf.ButtonUI;
	import org.flashapi.swing.plaf.core.LafDTO;
	import org.flashapi.swing.plaf.core.LafDTOCornerUtil;
	import org.flashapi.swing.text.FontFormat;
	
	/**
	 * 	The <code>SpasButtonCloseUI</code> class is the SPAS 3.0 default look and feel
	 * 	for <code>Button</code> instances.
	 * 
	 * 	@see org.flashapi.swing.Button
	 * 	@see org.flashapi.swing.plaf.ButtonUI
	 * 
	 * 	@langversion ActionScript 3.0
	 * 	@playerversion Flash Player 9
	 * 	@productversion SPAS 3.0 alpha
	 */
	public class SpasButtonCloseUI extends SpasButtonUI implements ButtonUI {
		
		//--------------------------------------------------------------------------
		//
		//  Constructor
		//
		//--------------------------------------------------------------------------
		
		public function SpasButtonCloseUI(dto:LafDTO) {
			dto.width = 36;
			dto.height = 36;
			super(dto);
		}
		
		/**
		 *  @inheritDoc 
		 *  @copy http://www.google.com/design/spec/components/buttons.html#buttons-flat-raised-buttons
		 */
		override public function drawOutState():void {
			var bntColor:uint = 0xff0000;
			var lineColor1:uint = 0x888888;//0x969696
			var lineColor2:int = 0x505050;//0x505050
			if (dto.borderColors.up != StateObjectValue.NONE){
				lineColor1 = dto.borderColors.up;
				lineColor2 = -1;
			}
			drawButtonShape(ButtonState.UP, bntColor, lineColor1, lineColor2);
		}
		
		override protected function drawButtonShape(state:String, buttonColor:uint, lineColor1:uint, lineColor2:int = -1):void {
			var w:Number = dto.width;
			var h:Number = dto.height;
			var cu:LafDTOCornerUtil = new LafDTOCornerUtil(dto, 6);
			var tgt:Sprite = dto.currentTarget;
			
			var f:Figure = Figure.setFigure(tgt);
			f.clear();
			//f.lineStyle(bw, lineColor1, bdra, true);
			f.beginFill( buttonColor, 1 );
			f.drawRoundedBox(0, 0, w, h, cu.topLeft, cu.topRight, cu.bottomRight, cu.bottomLeft);
			// not sure how to make the mouse detect this shape and size
			// leave it for a later day - RSF 12.26.14
			//f.drawCircle( 0, 0, 20 )
			f.endFill();
		}
	}	
}
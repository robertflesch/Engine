﻿////////////////////////////////////////////////////////////////////////////////
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

package org.flashapi.swing.plaf.wireframe {
	
	// -----------------------------------------------------------
	// WFAccordionUI.as
	// -----------------------------------------------------------

	/**
	* @author Pascal ECHEMANN
	* @version 1.0.2, 26/04/2011 14:39
	* @see http://www.flashapi.org/
	*/

	import org.flashapi.swing.draw.Figure;
	import org.flashapi.swing.plaf.AccordionUI;
	import org.flashapi.swing.plaf.core.LafDTO;
	
	/**
	 * 	The <code>WFAccordionUI</code> class is the SPAS 3.0 wireframe-like look and feel
	 * 	for <code>Accordion</code> instances.
	 * 
	 * 	@see org.flashapi.swing.Accordion
	 * 	@see org.flashapi.swing.plaf.AccordionUI
	 * 
	 * 	@langversion ActionScript 3.0
	 * 	@playerversion Flash Player 9
	 * 	@productversion SPAS 3.0 alpha 5.5
	 */
	public class WFAccordionUI extends WFUI implements AccordionUI {
		
		//--------------------------------------------------------------------------
		//
		//  Constructor
		//
		//--------------------------------------------------------------------------
		
		/**
		 * 	@copy org.flashapi.swing.plaf.spas.SpasBoxHelpUI#SpasBoxHelpUI()
		 */
		public function WFAccordionUI(dto:LafDTO) {
			super(dto);
		}
		
		//--------------------------------------------------------------------------
		//
		//  Public methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 *  @inheritDoc 
		 */
		public function drawBackground():void {
			with (Figure.setFigure(dto.background)) {
				clear();
				beginFill(DEFAULT_BACKGROUND_COLOR);
				drawRectangle(0, 0, dto.width, dto.height);
				endFill();
			}
		}
		
		/**
		 *  @inheritDoc 
		 */
		public function drawBorder():void {
			with(Figure.setFigure(dto.border)) {
				clear();
				lineStyle(1, DEFAULT_BORDER_COLOR);
				drawRectangle(0, 0, dto.width, dto.height);
				endFill();
			}
		}
		
		/**
		 *  @inheritDoc 
		 */
		public function getButtonLaf():Class {
			return WFButtonUI;
		}
		
		/**
		 *  @inheritDoc 
		 */
		public function getColor():uint {
			return DEFAULT_BACKGROUND_COLOR;
		}
		
		/**
		 *  @inheritDoc 
		 */
		public function getBorderColor():uint {
			return DEFAULT_BORDER_COLOR;
		}
		
		/**
		 *  @inheritDoc 
		 */
		public function getBorderAlpha():Number {
			return 1;
		}
		
		/**
		 *  @inheritDoc 
		 */
		public function getScrollBarLaf():Class {
			return WFScrollableAreaUI;
		}
	}
}
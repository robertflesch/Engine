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

package org.flashapi.swing.plaf.spas {

	// -----------------------------------------------------------
	// SpasListBoxUI.as
	// -----------------------------------------------------------

	/**
	* @author Pascal ECHEMANN
	* @version 1.0.1, 11/01/2009 21:50
	* @see http://www.flashapi.org/
	*/
	
	import org.flashapi.swing.plaf.core.LafDTO;
	import org.flashapi.swing.plaf.ListBoxUI;
	
	/**
	 * 	The <code>SpasListBoxUI</code> class is the SPAS 3.0 default look and feel
	 * 	for <code>ListBox</code> instances.
	 * 
	 * 	@see org.flashapi.swing.ListBox
	 * 	@see org.flashapi.swing.plaf.ListBoxUI
	 * 
	 * 	@langversion ActionScript 3.0
	 * 	@playerversion Flash Player 9
	 * 	@productversion SPAS 3.0 alpha
	 */
	public class SpasListBoxUI extends VVUI implements ListBoxUI {
		
		//--------------------------------------------------------------------------
		//
		//  Constructor
		//
		//--------------------------------------------------------------------------
		
		/**
		 * 	@copy org.flashapi.swing.plaf.spas.SpasBoxHelpUI#SpasBoxHelpUI()
		 */
		public function SpasListBoxUI(dto:LafDTO) {
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
		public function getSelectableItemLaf():Class {
			return SpasSelectableItemUI;
		}
		
		/**
		 *  @inheritDoc 
		 */
		public function getScrollBarLaf():Class {
			return SpasScrollBarUI;
		}
		
		/**
		 *  @inheritDoc 
		 */
		public function getBackgroundColor():uint {
			return 0xFFFFFF;
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
	}
}
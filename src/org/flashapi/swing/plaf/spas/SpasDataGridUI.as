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
	// SpasDataGridUI.as
	// -----------------------------------------------------------

	/**
	* @author Pascal ECHEMANN
	* @version 1.0.0, 28/01/2009 00:48
	* @see http://www.flashapi.org/
	*/

	import org.flashapi.swing.plaf.core.LafDTO;
	import org.flashapi.swing.plaf.DataGridUI;
	import org.flashapi.swing.text.FontFormat;
	
	/**
	 * 	The <code>SpasDataGridUI</code> class is the SPAS 3.0 default look and feel
	 * 	for <code>DataGrid</code> instances.
	 * 
	 * 	@see org.flashapi.swing.DataGrid
	 * 	@see org.flashapi.swing.plaf.DataGridUI
	 * 
	 * 	@langversion ActionScript 3.0
	 * 	@playerversion Flash Player 9
	 * 	@productversion SPAS 3.0 alpha
	 */
	public class SpasDataGridUI extends VVUI implements DataGridUI {
		
		//--------------------------------------------------------------------------
		//
		//  Constructor
		//
		//--------------------------------------------------------------------------
		
		/**
		 * 	@copy org.flashapi.swing.plaf.spas.SpasBoxHelpUI#SpasBoxHelpUI()
		 */
		public function SpasDataGridUI(dto:LafDTO) {
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
		public function getRowBrightColor():uint {
			return 0xffffff;
		}
		
		/**
		 *  @inheritDoc 
		 */
		public function getRowDarkColor():uint {
			return 0xeeeeee;
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
		
		/**
		 *  @inheritDoc 
		 */
		public function getDefautFontFormat():FontFormat {
			return _fontFormat;
		}
		
		/**
		 *  @inheritDoc 
		 */
		public function getDefautHeaderFontFormat():FontFormat {
			return _headerFontFormat;
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
		public function getHeaderLaf():Class {
			return SpasDataGridHeaderUI;
		}
		
		//--------------------------------------------------------------------------
		//
		//  Private properties
		//
		//--------------------------------------------------------------------------
		
		private var _fontFormat:FontFormat =
			new FontFormat(DEFAULT_FONT_FACE, DEFAULT_FONT_SIZE, DEFAULT_FONT_COLOR,
			null, null, null, null, null, null, 4, 4);
		private var _headerFontFormat:FontFormat =
			new FontFormat(DEFAULT_FONT_FACE, DEFAULT_FONT_SIZE, DEFAULT_BUTTON_FONT_COLOR,
			true, null, null, null, null, null, 4, 4);
	}
}
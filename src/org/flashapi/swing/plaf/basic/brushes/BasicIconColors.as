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

package org.flashapi.swing.plaf.basic.brushes {
	
	// -----------------------------------------------------------
	// BasicIconColors.as
	// -----------------------------------------------------------

	/**
	* @author Pascal ECHEMANN
	* @version 1.0.1, 20/01/2009 00:14
	* @see http://www.flashapi.org/
	*/
	
	import org.flashapi.swing.core.DeniedConstructorAccess;
	
	/**
	 *  The <code>BasicIconColors</code> class provides constant values and static methods
	 * 	to manage colors of drawable icons for the "basic" Look and Feel.
	 * 
	 * 	<p>You cannot create a <code>BasicIconColors</code> object directly from ActionScript code.
	 * 	If you call <code>new BasicIconColors()</code>, an exception is thrown.</p>
	 * 
	 * 	@langversion ActionScript 3.0
	 * 	@playerversion Flash Player 9
	 * 	@productversion SPAS 3.0 alpha
	 */
	public class BasicIconColors {
		
		//--------------------------------------------------------------------------
		//
		//  Constructor
		//
		//--------------------------------------------------------------------------
		
		/**
		 * 	Constructor.
		 * 
		 *  @throws 	org.flashapi.swing.exceptions.DeniedConstructorAccess
		 * 				A <code>DeniedConstructorAccess</code> if you try to create
		 * 				a new <code>BasicIconColors</code> instance;
		 */
		public function BasicIconColors() {
			super();
			new DeniedConstructorAccess(this);
		}
		
		//--------------------------------------------------------------------------
		//
		//  Public constants
		//
		//--------------------------------------------------------------------------
		
		/**
		 * 	The basic LAF icon color for the "out" state.
		 */
		public static const OUT:uint = 0x3A414B;
		
		/**
		 * 	The basic LAF icon color for the "pressed" state.
		 */
		public static const PRESSED:uint = 0x216B9A;
		
		/**
		 * 	The basic LAF icon color for the "over" state.
		 */
		public static const OVER:uint = 0x216B9A;
		
		/**
		 * 	The basic LAF icon's color for the "selected" state.
		 */
		public static const SELECTED:uint = 0x216B9A;
		
		/**
		 * 	The basic LAF icon color for the "emphasized" state.
		 */
		public static const EMPHASIZED:uint = 0x216B9A;
		
		/**
		 * 	The basic LAF icon color for the "inactive" state.
		 */
		public static const INACTIVE:uint = 0xBBBBBB;
	}
}
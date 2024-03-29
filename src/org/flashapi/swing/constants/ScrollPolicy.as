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

package org.flashapi.swing.constants {
	
	// -----------------------------------------------------------
	// ScrollPolicy.as
	// -----------------------------------------------------------

	/**
	* @author Pascal ECHEMANN
	* @version 1.0.0, 13/03/2010 18:41
	* @see http://www.flashapi.org/
	*/
	import org.flashapi.swing.core.DeniedConstructorAccess;
	
	/**
	 * 	The <code>ScrollPolicy</code> class is an enumeration of constant values that
	 * 	you can use to set the <code>scrollPolicy</code> property of
	 * 	<code>ScrollableContainer</code> objects.
	 * 
	 * 	@see org.flashapi.swing.containers.ScrollableContainer#scrollPolicy
	 * 
	 * 	@langversion ActionScript 3.0
	 * 	@playerversion Flash Player 9
	 * 	@productversion SPAS 3.0 alpha
	 */	
	public class ScrollPolicy {
		
		//--------------------------------------------------------------------------
		//
		// Constructor
		//
		//--------------------------------------------------------------------------
		
		/**
		 * 	@private
		 * 
		 * 	Constructor.
		 * 
		 *  @throws 	org.flashapi.swing.exceptions.DeniedConstructorAccess
		 * 				A DeniedConstructorAccess if you try to create a new ScrollPolicy
		 * 				instance.
		 */
		public function ScrollPolicy() {
			super();
			new DeniedConstructorAccess(this);
		}
		
		//--------------------------------------------------------------------------
		//
		// Public constants
		//
		//--------------------------------------------------------------------------
		
		/**
		 * 	Both, vertical and horizontal scrollbars are displayed within the container
		 * 	object.
		 */
		public static const BOTH:String = "both";
		
		/**
		 * 	No scrollbar is displayed within the container object.
		 */
		public static const NONE:String = "none";
		
		/**
		 * 	Only the vertical scrollbar is displayed within the container object.
		 */
		public static const VERTICAL:String = "vertical";
		
		/**
		 * 	Only the horizontal scrollbar is displayed within the container object.
		 */
		public static const HORIZONTAL:String = "horizontal";
		
		/**
		 * 	Scrollbar are displayed within the container object if the children exceed
		 * 	the dimension of the owningModel.
		 */
		public static const AUTO:String = "auto";
	}
}
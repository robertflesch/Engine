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

package org.flashapi.swing.constants {
	
	// -----------------------------------------------------------
	// ButtonOrientation.as
	// -----------------------------------------------------------

	/**
	* @author Robert Flesch
	* @version 1.0.0, 1/20/2015 23:11
	* @see 
	*/
	
	import org.flashapi.swing.core.DeniedConstructorAccess;
	
	/**
	 * 	The <code>ButtonOrientation</code> class is an enumeration of constant 
	 * 	values that is passed to the button that make up the <code>orientation</code> property of the
	 * 	button bar objects.
	 * 
	 * 	@see org.flashapi.swing.button.core.AbstractButtonBar#orientation
	 * 
	 * 	@langversion ActionScript 3.0
	 * 	@playerversion Flash Player 9
	 * 	@productversion SPAS 3.0 alpha
	 */	
	public class ButtonOrientation {
		
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
		 * 				A DeniedConstructorAccess if you try to create a new ButtonOrientation
		 * 				instance.
		 */
		public function ButtonOrientation() {
			super();
			new DeniedConstructorAccess(this);
		}
		
		//--------------------------------------------------------------------------
		//
		// Public constants
		//
		//--------------------------------------------------------------------------
		
		/**
		 * 	Specifies that the button bar lays its buttons vertically.
		 */
		public static const VERTICAL:String = "vertical";
		
		/**
		 * 	Specifies that the button bar lays its buttons horizontally.
		 */
		public static const HORIZONTAL:String = "horizontal";
	}
}
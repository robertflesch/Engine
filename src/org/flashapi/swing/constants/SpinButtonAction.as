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
	// SpinButtonAction.as
	// -----------------------------------------------------------

	/**
	* @author Pascal ECHEMANN
	* @version 1.0.01, 15/02/2011 11:25
	* @see http://www.flashapi.org/
	*/

	import org.flashapi.swing.core.DeniedConstructorAccess;
	
	/**
	 * 	<strong>FOR DEVELOPERS ONLY.</strong>
	 * 
	 * 	The <code>SpinButtonAction</code> class is an enumeration of constant values 
	 * 	that are internally used by the SPAS 3.0 to detemine whether the current action
	 * 	of a spin button constists in increasing or decreasing the specified value.
	 * 
	 * 	@langversion ActionScript 3.0
	 * 	@playerversion Flash Player 9
	 * 	@productversion SPAS 3.0 alpha
	 */	
	public class SpinButtonAction {
		
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
		 *  @throws 	org.flashapi.swing.exceptions.DeniedConstructorAccessException
		 * 				A DeniedConstructorAccessException if you try to create a new 
		 * 				SpinButtonAction instance.
		 */
		public function SpinButtonAction() {
			super();
			new DeniedConstructorAccess(this);
		}
		
		//--------------------------------------------------------------------------
		//
		// Public constants
		//
		//--------------------------------------------------------------------------
		
		/**
		 * 	Value that indicates that a spin button currently decreases the specified
		 * 	value.
		 */
		public static const DECREASE:String = "decrease";
		
		/**
		 * 	Value that indicates that a spin button currently increases the specified
		 * 	value.
		 */
		public static const INCREASE:String = "increase";
	}
}
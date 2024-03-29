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

package org.flashapi.swing.exceptions {
	
	// -----------------------------------------------------------
	// InvalidArgumentException.as
	// -----------------------------------------------------------

	/**
	* @author Pascal ECHEMANN
	* @version 1.0.0, 06/01/2008 22:09
	* @see http://www.flashapi.org/
	*/
	
	/**
	 * 	An <code>InvalidArgumentException</code> is thrown  to indicate that type
	 * 	of argument passend in a method parameter is not valid. <code>InvalidArgumentException</code>
	 * 	errors are thrown for example by constructor function that support mutliple
	 * 	signatures.
	 * 
	 * 	@langversion ActionScript 3.0
	 * 	@playerversion Flash Player 9
	 * 	@productversion SPAS 3.0 alpha
	 */
	public class InvalidArgumentException extends Error {
		
		//--------------------------------------------------------------------------
		//
		// Constructor
		//
		//--------------------------------------------------------------------------
		
		/**
		 * 	Constructor. Creates a new <code>InvalidArgumentException</code> object with
		 * 	the specified detail message.
		 * 
		 * 	@param	message	The <code>String</code> containing a detail message.
		 */
		public function InvalidArgumentException(message:String = "") {
			super("InvalidArgumentException: " + message);
		}
	}
}

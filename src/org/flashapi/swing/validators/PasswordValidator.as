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

package org.flashapi.swing.validators {
	
	// -----------------------------------------------------------
	// PasswordValidator.as
	// -----------------------------------------------------------
	
	/**
	* @author Pascal ECHEMANN
	* @version 1.0.0, 30/11/2008 03:15
	* @see http://www.flashapi.org/
	*/
	
	import org.flashapi.swing.localization.validation.password.PasswordLocaleUs;
	import org.flashapi.swing.TextInput;
	
	/**
	 * 	The <code>PasswordValidator</code> class validates that the value of a
	 * 	<code>TextInput</code> object match a <code>String</code>.
	 * 
	 * 	@langversion ActionScript 3.0
	 * 	@playerversion Flash Player 9
	 * 	@productversion SPAS 3.0 alpha
	 */
	public class PasswordValidator extends AbstractValidator {
		
		//--------------------------------------------------------------------------
		//
		// Constructor
		//
		//--------------------------------------------------------------------------
		
		/**
		 * 	Constructor. Creates a new <code>PasswordValidator</code> instance with
		 * 	the specified parameters.
		 * 
		 * 	@param	input	A <code>TextInput</code> instance used as reference for
		 * 					the <code>String</code> validation
		 */
		public function PasswordValidator(input:TextInput) {
			super(PasswordLocaleUs);
			initObj(input);
		}
		
		//--------------------------------------------------------------------------
		//
		//  Public properties
		//
		//--------------------------------------------------------------------------
		
		/**
		 * 	Returns a reference to the <code>TextInput</code> instance used as 
		 * 	reference for the <code>String</code> validation.
		 */
		public var input:TextInput;
		
		//--------------------------------------------------------------------------
		//
		//  Public methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 *  @private
		 */
		override public function validate(value:String):Boolean {
			return (input.text == value);
		}
		
		//--------------------------------------------------------------------------
		//
		//  Private methods
		//
		//--------------------------------------------------------------------------
		
		private function initObj(input:TextInput):void {
			this.input = input;
		}
	}
}
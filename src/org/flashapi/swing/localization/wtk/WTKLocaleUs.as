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

package org.flashapi.swing.localization.wtk {
	
	// -----------------------------------------------------------
	// WTKLocaleUs.as
	// -----------------------------------------------------------

	/**
	* @author Pascal ECHEMANN
	* @version 1.0.1, 05/05/2011 00:31
	* @see http://www.flashapi.org/
	*/
	
	import org.flashapi.swing.localization.closable.ClosableLocaleUs;
	
	/**
	 * 	The <code>WTKLocaleUs</code> class is an enumeration of constant values
	 * 	that contains US english alternate text denominations to use with SPAS
	 * 	3.0 windows buttons.
	 * 
	 * 	<p>The <code>WTKLocaleUs</code> class is the default class for windows 
	 * 	buttons alternate text denominations within the SPAS 3.0 API.</p>
	 * 
	 * 	@langversion ActionScript 3.0
	 * 	@playerversion Flash Player 9
	 * 	@productversion SPAS 3.0 alpha
	 */
	public class WTKLocaleUs {
		
		//--------------------------------------------------------------------------
		//
		// Constructor
		//
		//--------------------------------------------------------------------------
		
		/**
		 * 	@private
		 * 
		 * 	Constructor.
		 */
		public function WTKLocaleUs() {
			super();
		}
		
		//--------------------------------------------------------------------------
		//
		// Public constants
		//
		//--------------------------------------------------------------------------
		
		/**
		 * 	The alternate text for windows closing buttons.
		 * 
		 * 	@see org.flashapi.swing.wtk.WTK#closeButtonAlt
		 */
		public static const CLOSE:String = ClosableLocaleUs.CLOSE;
		
		/**
		 * 	The alternate text for windows minimizing buttons.
		 * 
		 * 	@see org.flashapi.swing.Window#minimize
		 */
		public static const MINIMIZE:String = "Minimize";
		
		/**
		 * 	The alternate text for windows maximizing buttons.
		 * 
		 * 	@see org.flashapi.swing.Window#maximize
		 */
		public static const MAXIMIZE:String = "Maximize";
		
		/**
		 * 	The alternate text for windows restoring buttons.
		 * 
		 * 	@see org.flashapi.swing.Window#restore
		 */
		public static const RESTORE:String = "Restore";
	}
}
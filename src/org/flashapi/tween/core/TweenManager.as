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

package org.flashapi.tween.core {
	
	// -----------------------------------------------------------
	// TweenManager.as
	// -----------------------------------------------------------
	
	/**
	* @author Pascal ECHEMANN
	* @version 1.0.0, 27/05/2011 20:31
	* @see http://www.flashapi.org/
	*/
	
	import org.flashapi.tween.Tween;
	
	use namespace beetween;
	
	/**
	 * 	The <code>TweenManager</code> class is a utility class to allow <code>Tween</code>
	 * 	instances to be queued and fired off based on their registration order. You
	 * 	never should derectly use the <code>TweenManager</code> class.
	 * 
	 * 	@see org.flashapi.tween.Tween
	 * 	@see org.flashapi.tween.core.BTweenManager
	 * 	
	 * 	@langversion ActionScript 3.0
	 * 	@playerversion Flash Player 9
	 * 	@productversion SPAS 3.0 alpha
	 */
	public class TweenManager {
		
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
		public function TweenManager() {
			super();
		}
		
		//--------------------------------------------------------------------------
		//
		//  Internal scope static methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * 	@private 
		 */
		beetween static function getInterval():uint {
			return _manager.getInterval();
		}
		
		/**
		 * 	@private 
		 */
		beetween static function setInterval(value:uint):void {
			_manager.setInterval(value);
		}
		
		/**
		 * 	@private 
		 */
		beetween static function rescue():void {
			_manager.rescue();
		}
		
		/**
		 * 	@private 
		 */
		beetween static function removeTween(value:Tween):void {
			_manager.removeTween(value);
		}
		
		/**
		 * 	@private 
		 */
		beetween static function addTween(value:Tween):void {
			_manager.addTween(value);
		}
		
		/**
		 * 	@private 
		 */
		beetween static function getGlobalTime():Number {
			return _manager.getGlobalTime();
		}
		
		/**
		 * 	@private 
		 */
		beetween static function init():void {
			if (_manager == null) _manager = new AbstractTweenManager([]);
		}
		
		//--------------------------------------------------------------------------
		//
		//  Private static properties
		//
		//--------------------------------------------------------------------------
		
		/**
		 * 	@private 
		 */
		private static var _manager:AbstractTweenManager;
	}
}
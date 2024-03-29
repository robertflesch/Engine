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

package org.flashapi.swing.event {
	
	// -----------------------------------------------------------
	// ScrollEvent.as
	// -----------------------------------------------------------
	
	/**
	* @author Pascal ECHEMANN
	* @version 1.0.2, 12/05/2011 21:36
	* @see http://www.flashapi.org/
	*/
	
	import flash.events.Event;
	
	/**
	 *  The <code>ScrollEvent</code> class represents event objects specific to 
	 *  <code>Scrollable</code> objects.
	 * 
	 * 	@see org.flashapi.swing.scroll.Scrollable
	 *
	 * 	@langversion ActionScript 3.0
	 * 	@playerversion Flash Player 9
	 * 	@productversion SPAS 3.0 alpha
	 */
	public class ScrollEvent extends SpasEvent {
		
		//--------------------------------------------------------------------------
		//
		//  Constructor
		//
		//--------------------------------------------------------------------------
		
		/**
		 *  Constructor.	Creates a new <code>ScrollEvent</code> with the specified
		 * 	parameters.
		 *
		 *  @param type 	The event type; indicates the action that caused the event.
		 *  @param bubbles 	Specifies whether the event can bubble up the display list
		 * 					hierarchy.
		 *  @param cancelable 	Specifies whether the behavior associated with the event
		 * 						can be prevented.
		 */
		public function ScrollEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false) {
			super(type, bubbles, cancelable);
		}
		
		//--------------------------------------------------------------------------
		//
		//  Event types
		//
		//--------------------------------------------------------------------------
		
		/**
		 *  The <code>ScrollEvent.SCROLL</code> constant defines the value of the 
		 *  <code>type</code> property of the event object for a <code>scroll</code>
		 * 	event.
		 * 
		 *  <p>The properties of the event object have the following values:</p>
		 *  <table class="innertable">
		 * 		<tr>
		 * 			<th>Property</th><th>Value</th>
		 *		</tr>
		 *		<tr>
		 * 			<td><code>bubbles</code></td><td><code>false</code></td>
		 * 		</tr>
		 *		<tr>
		 * 			<td><code>cancelable</code></td><td><code>false</code></td>
		 * 		</tr>
		 *		<tr>
		 * 			<td><code>currentTarget</code></td><td>The <code>Object</code> that 
		 *      defines the event listener that handles the event.</td>
		 * 		</tr>
		 *		<tr>
		 * 			<td><code>target</code></td><td>The <code>Object</code> that dispatched
		 * 			the event; it is not always the <code>Object</code> listening for the
		 * 			event. Use the <code>currentTarget</code> property to always access the 
		 *			<code>Object</code> listening for the event.</td>
		 * 		</tr>
		 *  </table>
		 *
		 *  @eventType scroll
		 */
		public static const SCROLL:String = "scroll";
		
		/**
		 *  The <code>ScrollEvent.SCROLLABLE_CHANGED</code> constant defines the value of the 
		 *  <code>type</code> property of the event object for a <code>scrollableChanged</code>
		 * 	event.
		 * 
		 *  <p>The properties of the event object have the following values:</p>
		 *  <table class="innertable">
		 * 		<tr>
		 * 			<th>Property</th><th>Value</th>
		 *		</tr>
		 *		<tr>
		 * 			<td><code>bubbles</code></td><td><code>false</code></td>
		 * 		</tr>
		 *		<tr>
		 * 			<td><code>cancelable</code></td><td><code>false</code></td>
		 * 		</tr>
		 *		<tr>
		 * 			<td><code>currentTarget</code></td><td>The <code>Object</code> that 
		 *      defines the event listener that handles the event.</td>
		 * 		</tr>
		 *		<tr>
		 * 			<td><code>target</code></td><td>The <code>Object</code> that dispatched
		 * 			the event; it is not always the <code>Object</code> listening for the
		 * 			event. Use the <code>currentTarget</code> property to always access the 
		 *			<code>Object</code> listening for the event.</td>
		 * 		</tr>
		 *  </table>
		 *
		 *  @eventType scrollableChanged
		 */
		public static const SCROLLABLE_CHANGED:String = "scrollableChanged";
		
		/**
		 *  The <code>ScrollEvent.STOP_SCROLL</code> constant defines the value of the 
		 *  <code>type</code> property of the event object for a <code>stopScroll</code>
		 * 	event.
		 * 
		 *  <p>The properties of the event object have the following values:</p>
		 *  <table class="innertable">
		 * 		<tr>
		 * 			<th>Property</th><th>Value</th>
		 *		</tr>
		 *		<tr>
		 * 			<td><code>bubbles</code></td><td><code>false</code></td>
		 * 		</tr>
		 *		<tr>
		 * 			<td><code>cancelable</code></td><td><code>false</code></td>
		 * 		</tr>
		 *		<tr>
		 * 			<td><code>currentTarget</code></td><td>The <code>Object</code> that 
		 *      defines the event listener that handles the event.</td>
		 * 		</tr>
		 *		<tr>
		 * 			<td><code>target</code></td><td>The <code>Object</code> that dispatched
		 * 			the event; it is not always the <code>Object</code> listening for the
		 * 			event. Use the <code>currentTarget</code> property to always access the 
		 *			<code>Object</code> listening for the event.</td>
		 * 		</tr>
		 *  </table>
		 *
		 *  @eventType stopScroll
		 */
		public static const STOP_SCROLL:String = "stopScroll";
		
		/**
		 *  The <code>ScrollEvent.START_SCROLL</code> constant defines the value of the 
		 *  <code>type</code> property of the event object for a <code>startScroll</code>
		 * 	event.
		 * 
		 *  <p>The properties of the event object have the following values:</p>
		 *  <table class="innertable">
		 * 		<tr>
		 * 			<th>Property</th><th>Value</th>
		 *		</tr>
		 *		<tr>
		 * 			<td><code>bubbles</code></td><td><code>false</code></td>
		 * 		</tr>
		 *		<tr>
		 * 			<td><code>cancelable</code></td><td><code>false</code></td>
		 * 		</tr>
		 *		<tr>
		 * 			<td><code>currentTarget</code></td><td>The <code>Object</code> that 
		 *      defines the event listener that handles the event.</td>
		 * 		</tr>
		 *		<tr>
		 * 			<td><code>target</code></td><td>The <code>Object</code> that dispatched
		 * 			the event; it is not always the <code>Object</code> listening for the
		 * 			event. Use the <code>currentTarget</code> property to always access the 
		 *			<code>Object</code> listening for the event.</td>
		 * 		</tr>
		 *  </table>
		 *
		 *  @eventType startScroll
		 */
		public static const START_SCROLL:String = "startScroll";
		
		/**
		 *  The <code>ScrollEvent.THICKNESS_CHANGED</code> constant defines the value of the 
		 *  <code>type</code> property of the event object for a <code>thicknessChanged</code>
		 * 	event.
		 * 
		 *  <p>The properties of the event object have the following values:</p>
		 *  <table class="innertable">
		 * 		<tr>
		 * 			<th>Property</th><th>Value</th>
		 *		</tr>
		 *		<tr>
		 * 			<td><code>bubbles</code></td><td><code>false</code></td>
		 * 		</tr>
		 *		<tr>
		 * 			<td><code>cancelable</code></td><td><code>false</code></td>
		 * 		</tr>
		 *		<tr>
		 * 			<td><code>currentTarget</code></td><td>The <code>Object</code> that 
		 *      defines the event listener that handles the event.</td>
		 * 		</tr>
		 *		<tr>
		 * 			<td><code>target</code></td><td>The <code>Object</code> that dispatched
		 * 			the event; it is not always the <code>Object</code> listening for the
		 * 			event. Use the <code>currentTarget</code> property to always access the 
		 *			<code>Object</code> listening for the event.</td>
		 * 		</tr>
		 *  </table>
		 *
		 *  @eventType thicknessChanged
		 */
		public static const THICKNESS_CHANGED:String = "thicknessChanged";
		
		//--------------------------------------------------------------------------
		//
		//  Overridden Event methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 *	@private 
		 */
		override public function clone():Event {
			return new ScrollEvent(type, bubbles, cancelable);
		}
	}
}
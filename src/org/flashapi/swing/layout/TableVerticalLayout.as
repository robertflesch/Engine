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

package org.flashapi.swing.layout {

	// -----------------------------------------------------------
	// TableVerticalLayout.as
	// -----------------------------------------------------------

	/**
	* @author Pascal ECHEMANN
	* @version 1.0.0, 05/02/2009 23:03
	* @see http://www.flashapi.org/
	*/
	
	import flash.geom.Rectangle;
	import org.flashapi.swing.core.spas_internal;
	import org.flashapi.swing.layout.AbstractLayout;
	
	use namespace spas_internal;
	
	//--------------------------------------------------------------------------
	//
	//  Events
	//
	//--------------------------------------------------------------------------

	/**
	 *  The "finished" <code>LayoutEvent</code> occurs after child elements are added
	 * 	or removed, bounds of the <code>UIContainer</code> object change and after 
	 * 	all other changes that could affect the layout have been performed.
	 *
	 *  @eventType org.flashapi.swing.event.LayoutEvent.FINISHED
	 */
	[Event(name="finished", type="org.flashapi.swing.event.LayoutEvent")]
	
	/**
	 * 	<strong>FOR DEVELOPERS ONLY.</strong>
	 * 
	 * 	The <code>TableVerticalLayout</code> class creates layout objects specific to
	 * 	<code>Datagrid</code> columns.
	 * 
	 * 	@see org.flashapi.swing.Datagrid
	 * 
	 * 	@langversion ActionScript 3.0
	 * 	@playerversion Flash Player 9
	 * 	@productversion SPAS 3.0 alpha
	 */
	public class TableVerticalLayout extends AbstractLayout implements Layout {
		
		//--------------------------------------------------------------------------
		//
		//  Constructor
		//
		//--------------------------------------------------------------------------
		
		/**
		 * 	<strong>FOR DEVELOPERS ONLY.</strong>
		 * 
		 * 	Constructor. Creates a new <code>TableVerticalLayout</code> instance.
		 */	
		public function TableVerticalLayout() {
			super();
		}
		
		//--------------------------------------------------------------------------
		//
		//  Public methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * 	@private
		 */
		public function moveObjects(bounds:Rectangle, caller:* = null):void {
			spas_internal::bounds = bounds;
			if ($elementsList.length > 0) setVerticalLayout();
			dispatchFinishedEvent();
		}
		
		//--------------------------------------------------------------------------
		//
		//  Private methods
		//
		//--------------------------------------------------------------------------
		
		private function setVerticalLayout():void {
			var obj:*;
			var s:uint = $elementsList.length;
			var yPos:Number = spas_internal::bounds.y;
			var i:uint = 0;
			//var vg:Number = $target.verticalGap;
			for (; i < s; i++) {
				obj = $elementsList[i];
				obj.y = yPos;
				yPos += obj.height;
			}
		}
	}
}
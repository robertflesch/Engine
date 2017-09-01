/**
 * Copyright (c) 2011 Enjoy Mondays
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
package com.enjoymondays.i18n.providers {

import com.enjoymondays.i18n.LocalizationManager;
import com.enjoymondays.i18n.ResourceBundle;
import com.enjoymondays.i18n.core.ILocale;
import com.enjoymondays.i18n.core.ILocalizationManager;
import com.enjoymondays.i18n.core.IResourceBundle;
import com.enjoymondays.i18n.core.IResourceBundleProviderFactory;
import com.enjoymondays.i18n.core.IResourceBundleProviderManager;


import com.enjoymondays.i18n.ResourceBundleVO;
import com.enjoymondays.i18n.events.ResourceBundleLoaderEvent;
import com.enjoymondays.i18n.providers.strategy.AbstractProviderStrategy;
import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.events.PersistenceEvent;

import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.events.Event;

import flash.events.EventDispatcher;
import flash.events.IOErrorEvent;
import flash.net.URLLoader;
import flash.net.URLRequest;

import playerio.GameFS;

import playerio.PlayerIO;


/**
	 * <code class="prettyprint">DefaultProviderManager</code>.
	 *
	 *	@langversion ActionScript 3.0
	 *	@Flash 		 Player 9.0.28.0
	 *	@author 	 Emiliano Burgos
	 *	@url		 http://www.enjoy-mondays.com
	 * @version 	 1.0
	 */
	public class DefaultProviderManager extends EventDispatcher implements IResourceBundleProviderManager {
		
		//private var _logger											:Logger = Logger.instance( DefaultProviderManager );
		
		/** @private **/
		protected var _owner										:LocalizationManager;
		
		/** @private **/
		protected var _factory										:IResourceBundleProviderFactory;
		
		/** @private **/
		protected var _provider										:AbstractProviderStrategy;
		
		/** @private **/
		protected var _baseUrl										:String;
		
		/**
		 * <code class="prettyprint">DefaultProviderManager</code>
		 * com.enjoymondays.i18n.providers.DefaultProviderManager
		 */
		public function DefaultProviderManager( baseUrl:String = '' ) {
			_baseUrl = baseUrl;
		}
		
		/** @inheritDoc */
		public function setOwner( owner:ILocalizationManager ):void {
			_owner = owner as LocalizationManager;
		}
		
		/** @inheritDoc */
		public function setFactory( factory:IResourceBundleProviderFactory ):void {
			_factory = factory;
		}
		
		/** @inheritDoc */
		public function loadResourceBundle( locale:ILocale ):void {
			_provider = _factory.buildProvider( locale ) as AbstractProviderStrategy;
			
			var vo:ResourceBundleVO = _factory.buildBundleVO( locale, _baseUrl );
			Log.out( "DefaultProviderManager.loadResourceBundle Globals.appPath: " + Globals.appPath , Log.WARN);
//			if ( "/" == Globals.appPath ) {
				var fs:GameFS = PlayerIO.gameFS(Globals.GAME_ID);
				var resolvedFilePath:String = fs.getUrl( vo.url );
				var loader:URLLoader = new URLLoader();
				loader.addEventListener(Event.COMPLETE, onResourceLoadComplete );
				loader.addEventListener(IOErrorEvent.IO_ERROR, onResourceLoadError);
				loader.load(new URLRequest(resolvedFilePath));
//			}
//			else {
//                _provider.addEventListener(ResourceBundleLoaderEvent.LOADED, _handleProvider);
//                _provider.addEventListener(ResourceBundleLoaderEvent.ERROR, _handleProvider);
//
//                _provider.load(vo);
//            }

            function onResourceLoadComplete (event:Event):void {
				var externalXML:XML = new XML(loader.data);
                var rb:IResourceBundle = _provider.parse(externalXML );
                _owner.addBundle( vo.locale.code, rb );
            }

            function onResourceLoadError (event:Event):void {
				Log.out( "DefaultProviderManager.onResourceLoadError - unable to load language", Log.WARN );
            }
		}


		
		/** @private */
		private function _handleProvider( e:ResourceBundleLoaderEvent ):void {
			
			_provider.removeEventListener( ResourceBundleLoaderEvent.LOADED, _handleProvider );
			_provider.removeEventListener( ResourceBundleLoaderEvent.ERROR, _handleProvider );
			
			switch( e.type ) {
				case ResourceBundleLoaderEvent.LOADED:
					//_logger.warn("resource loaded: %0", e.data );
					_owner.onBundleLoaderResult( e );
				break;
				
				case ResourceBundleLoaderEvent.ERROR:
					_owner.onBundleLoaderError( e );
				break;
				
				if( hasEventListener( e.type ) ) dispatchEvent( e );
			}
		}
		
		
		/** @inheritDoc */
		public function getResourceBundle( parse:Boolean = false ):IResourceBundle {
			return _provider.parse( _provider.getRawdata( ) );
		}
		
		/** @inheritDoc */
		public function setBaseUrl( baseUrl:String ):void {
			_baseUrl = baseUrl;
		}
	}
}
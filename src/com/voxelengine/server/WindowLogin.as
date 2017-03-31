/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.server
{
	import com.voxelengine.events.LoadingImageEvent;
	import com.voxelengine.events.RegionEvent;
	import com.voxelengine.events.WindowSplashEvent;
	import com.voxelengine.GUI.components.VVTextInput;
	import com.voxelengine.GUI.VoxelVerseGUI;
import com.voxelengine.renderer.Renderer;

//import com.voxelengine.GUI.WindowSplash;
	import flash.display.Bitmap;
	import flash.events.KeyboardEvent;
	import flash.events.Event;
	import flash.ui.Keyboard;
	import flash.net.SharedObject;
	
	import org.flashapi.swing.*;
	import org.flashapi.swing.button.ButtonGroup;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	import org.flashapi.swing.plaf.spas.SpasUI;
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.events.LoginEvent;
	import com.voxelengine.server.Network;
	
	import com.voxelengine.GUI.VVPopup;
	import com.voxelengine.GUI.WindowSandboxList;
	
	
	public class WindowLogin extends VVPopup
	{
		private var _emailInput:LabelInput;
		//private var _passwordInput:LabelInput;
		private var _passwordInput:TextInput;
		private var _errorText:Label;
		private var _userInfo:SharedObject;
		private var _savePW:CheckBox;
		private var _loginButton:Button

		private var _topImage:Bitmap;
		[Embed(source='../../../../embed/textures/loginImage.png')]
		private var _topImageClass:Class;
		
		public function WindowLogin( $email:String, $password:String )
		{
			super( "Login" );
			width = 309;
			height = 336;
			tabEnabled = false;
			tabIndex = -1;
			layout.orientation = LayoutOrientation.VERTICAL;

			try {
				_userInfo = SharedObject.getLocal( "voxelverse" );
			}
			catch ( error:Error )
			{
				Log.out( "WindowLogin.constructor - unable to open local shared object", Log.ERROR );
			}

			if ( Globals.isDebug ) {
				defaultCloseOperation = ClosableProperties.CALL_CLOSE_FUNCTION;
				// calls the close function when window shuts down, which closes the splash screen in debug.
				onCloseFunction = closeFunction;
			}
			else {
				showCloseButton = false;
			}

			_topImage = (new _topImageClass() as Bitmap);
			var pic:Image = new Image( _topImage, width, 189 );
			addElement(pic);
			
			var infoPanel:Container = new Container( width, 80 );
			infoPanel.autoSize = false;
			infoPanel.tabEnabled = false;
			infoPanel.layout.orientation = LayoutOrientation.VERTICAL;
			infoPanel.addElement( new Spacer( width, 15 ) );
			
			
			// is if the shared object has been loaded
			// if so, get the email address from that
			// otherwise use empty
				
			var emailAddy:String = _userInfo.data.email ?  _userInfo.data.email : $email;
			_emailInput = new LabelInput( " Email", emailAddy, width );
			_emailInput.labelControl.width = 80;
			_emailInput.tabIndex = 0;
			infoPanel.addElement( _emailInput );
			
			infoPanel.addElement( new Spacer( width, 10 ) );
			
			var pwContainer:Container = new Container( width, 20 );
			pwContainer.padding = 0;
			infoPanel.addElement( pwContainer );
			var labelPW:Label = new Label( " Password", 110 );
			labelPW.fontColor = SpasUI.LABEL_FONT_COLOR;
			labelPW.boldFace = true;
			pwContainer.addElement( labelPW );
			
			var password:String = _userInfo.data.password ?  _userInfo.data.password : $password;
			//_passwordInput = new LabelInput( " Password", password, width );
			_passwordInput = new VVTextInput( password, width );
			_passwordInput.displayAsPassword = true;
			_passwordInput.tabIndex = 1;
			
			//_passwordInput.labelControl.width = 80;
			pwContainer.addElement( _passwordInput );
			
			addElement( infoPanel );
			
			var otherPanel:Container = new Container( width, 10 );
			otherPanel.autoSize = false;
			otherPanel.padding = 0;
			otherPanel.layout.orientation = LayoutOrientation.HORIZONTAL;
			
			_errorText = new Label( "", width - 120 );
			_errorText.tabEnabled = false;
			_errorText.textAlign = TextAlign.CENTER;
			_errorText.backgroundColor = SpasUI.DEFAULT_COLOR;
			_errorText.fontColor = 0xff0000; // Red
			otherPanel.addElement( _errorText );
			
			_savePW = new CheckBox( "Save Password", 110, 20 );
			if ( "" != password )
				_savePW.selected = true;
			_savePW.tabIndex = 2;
			otherPanel.addElement( _savePW );
			
			addElement( otherPanel );
			
			const buttonWidth:int = 97;
			const buttonHeight:int = 45;
			var buttonPanel:Container = new Container( width, buttonHeight );
			buttonPanel.padding = 7.5;
			_loginButton = new Button( "Login", buttonWidth, buttonHeight - 15 );
			_loginButton.tabIndex = 4;
			$evtColl.addEvent( _loginButton, UIMouseEvent.CLICK, loginButtonHandler );

//			_loginButton.shadow = true;
			buttonPanel.addElement( _loginButton );
			
			var registerButton:Button = new Button( "Register..", buttonWidth, buttonHeight - 15 );
			$evtColl.addEvent( registerButton, UIMouseEvent.CLICK, registerButtonHandler );
			registerButton.shadow = true;
			registerButton.tabIndex = 5;
			buttonPanel.addElement( registerButton );
			
			var lostPasswordButton:Button = new Button( "Lost Password", buttonWidth, buttonHeight - 15 );
			lostPasswordButton.padding = 0
			lostPasswordButton.fontSize = 9;
			lostPasswordButton.shadow = true;
			$evtColl.addEvent( lostPasswordButton, UIMouseEvent.CLICK, lostPasswordHandler );
			lostPasswordButton.tabIndex = 6;
			buttonPanel.addElement( lostPasswordButton );
			
			addElement( buttonPanel );
			
			display( Renderer.renderer.width / 2 - (((width + 10) / 2) + x ), Renderer.renderer.height / 2 - (((height + 10) / 2) + y) );

			Globals.g_app.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPressed);
		}
		
		private function closeFunction():void {
			// This forces the shutdown of the spalsh screen.
			WindowSplashEvent.dispatch( new WindowSplashEvent( WindowSplashEvent.ANNIHILATE ) );
		}
		
		// Allows the enter key to activate the login key.
		private function onKeyPressed( e : KeyboardEvent) : void {
			if ( Keyboard.ENTER == e.keyCode ) {
				Globals.g_app.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPressed);
				loginButtonHandler(null);
			}
		}
		
		////////////////////////////////////////////////////////////////////////////////
		// recovery password
		////////////////////////////////////////////////////////////////////////////////
		private function lostPasswordHandler(event:UIMouseEvent):void {
			addRecoveryEventHandlers();
			Network.recoverPassword( _emailInput.label );
		}

		private function addRecoveryEventHandlers():void {
			LoginEvent.addListener( LoginEvent.PASSWORD_RECOVERY_SUCCESS, recoverySuccess );
			LoginEvent.addListener( LoginEvent.PASSWORD_RECOVERY_FAILURE, recoveryFailure );
		}
		
		private function removeRecoveryEventHandlers():void {
			LoginEvent.removeListener( LoginEvent.PASSWORD_RECOVERY_SUCCESS, recoverySuccess );
			LoginEvent.removeListener( LoginEvent.PASSWORD_RECOVERY_FAILURE, recoveryFailure );
		}
		
		private function recoverySuccess( $e:LoginEvent ):void 
		{ 
			removeRecoveryEventHandlers();
			(new Alert( "An email has been sent to " + _emailInput.label, 450 )).display();
		}

		private function recoveryFailure( $e:LoginEvent ):void 
		{ 
			removeRecoveryEventHandlers();
			(new Alert( "No account has been found for " + _emailInput.label, 450 )).display();
		}

		////////////////////////////////////////////////////////////////////////////////
		// register new account
		////////////////////////////////////////////////////////////////////////////////
		private function registerButtonHandler(event:UIMouseEvent):void 
		{
			new WindowRegister();
			remove();
		}
		
		////////////////////////////////////////////////////////////////////////////////
		// login
		////////////////////////////////////////////////////////////////////////////////
		private function loginButtonHandler(event:UIMouseEvent):void 
		{
			_loginButton.enabled = false;
			LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.CREATE ) );
			_errorText.text = "";
			_emailInput.glow = false;
			_passwordInput.glow = false;
			addLoginEventHandlers();
			//Log.out("WindowLogin.loginButtonHandler - Trying to establish connection to server", Log.DEBUG );
			Network.login( _emailInput.label, _passwordInput.text );
//			Globals.active = true;
		}
		
		private function addLoginEventHandlers():void {
			LoginEvent.addListener( LoginEvent.LOGIN_SUCCESS, loginSuccess );
			LoginEvent.addListener( LoginEvent.LOGIN_FAILURE, onUnknownFailure );
			LoginEvent.addListener( LoginEvent.LOGIN_FAILURE_PASSWORD, onPasswordFailure );
			LoginEvent.addListener( LoginEvent.LOGIN_FAILURE_EMAIL, onEmailFailure );
		}
		
		private function removeLoginEventHandlers():void {
			LoginEvent.removeListener( LoginEvent.LOGIN_SUCCESS, loginSuccess );
			LoginEvent.removeListener( LoginEvent.LOGIN_FAILURE, onUnknownFailure );
			LoginEvent.removeListener( LoginEvent.LOGIN_FAILURE_PASSWORD, onPasswordFailure );
			LoginEvent.removeListener( LoginEvent.LOGIN_FAILURE_EMAIL, onEmailFailure );
			//LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.ANNIHILATE ) );
			_loginButton.enabled = true;
		}
		
		private const BAD_EMAIL_PASSWORD:String = "Bad email or password";
		private function onPasswordFailure( $e:LoginEvent ):void {
			removeLoginEventHandlers();
			LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.ANNIHILATE ) );

			Log.out("WindowLogin.onPasswordFailure" + $e.guid );
			//_passwordInput.glow = true;
			//_errorText.text = $e.guid;
			_errorText.text = BAD_EMAIL_PASSWORD;
		}
		
		private function onEmailFailure( $e:LoginEvent ):void {
			removeLoginEventHandlers()
			LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.ANNIHILATE ) );
			Log.out("WindowLogin.onEmailFailure" + $e.guid );
//			_emailInput.glow = true;
//			_errorText.text = $e.guid;
			_errorText.text = BAD_EMAIL_PASSWORD;
		}
		
		private function onUnknownFailure( $e:LoginEvent ):void {
			removeLoginEventHandlers()
			LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.DESTROY ) );
			Log.out("WindowLogin.onUnknownFailure: " + $e.guid, Log.ERROR );
			_errorText.text = "Server error, try again later";
		}
		
		private function loginSuccess( $e:LoginEvent ):void {
			removeLoginEventHandlers();
			if ( _userInfo ) {
				_userInfo.data.email = _emailInput.label;
				if ( _savePW.selected )
					_userInfo.data.password = _passwordInput.text;
				else
					_userInfo.data.password = null;
				_userInfo.flush();

				//TODO use encrypted local storage instead
				//EncryptedLocalStorage.setItem('key', byteArray);

			}
			else
				Log.out("WindowLogin.loginSuccess - Unable to save user email", Log.WARN );
				
			//Log.out("WindowLogin.loginSuccess - Closing Login Window" );
			LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.DESTROY ) );

			remove();
		}
		
		override protected function onRemoved( event:UIOEvent ):void {
			Globals.g_app.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPressed);
			super.onRemoved( event );
			VoxelVerseGUI.currentInstance.showGUI();
		}

	}
}
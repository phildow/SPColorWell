//
//  SPColorWell.m
//  SPColorWell
//
//  Created by Philip Dow on 11/16/11.
//  Copyright 2011 Philip Dow / Sprouted. All rights reserved.
//

/*

	Redistribution and use in source and binary forms, with or without modification, 
	are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice, this list 
	of conditions and the following disclaimer.

	* Redistributions in binary form must reproduce the above copyright notice, this 
	list of conditions and the following disclaimer in the documentation and/or other 
	materials provided with the distribution.

	* Neither the name of the author nor the names of its contributors may be used to 
	endorse or promote products derived from this software without specific prior 
	written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND ANY 
	EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
	OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
	SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
	TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
	BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
	ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH 
	DAMAGE.

*/

/*
	For non-attribution licensing options refer to http://phildow.net/licensing/
*/

//
//  When the user selects a color in an NSColorPanel object, the panel sends a changeColor: 
//  action message to the first responder. You can override this method in any responder 
//  that needs to respond to a color change.

//  - (void)changeColor:(id)sender
//  sender -- The control that sent the message. NSTextView’s implementation sends a color 
//  message to sender to get the new color.

//  NSColorPanelColorDidChangeNotification
//  Posted when the color of the NSColorPanel is set, as when setColor: is invoked.
//  The notification object is the notifying NSColorPanel. This notification does not contain 
//  a userInfo dictionary.

//  A difficulty with checking color equality is that the API checks the color space. An RGB 
//  color at 0,0,0 is not equivalent to a white color at 0. Black != black!

//  Moreover, color will appear black when no explicit color has been set for the text using
//  NSAttributedString's NSForegroundColorAttributeName, but it will show up as the shared
//  color panel's default color, which is white (NSCachedWhiteColor)!

//  To solve this problem, explicitly set a color on the text, which seems to be what the iWork
//  applications do, because the shared color panel is correctly set on the first show.

//  Correction: make sure the shared color panel has been initialized before the user has a
//  chance to click on the color well. This insures that the color panel has been updated with
//  the last initial color (in a text view, for example), before the user takes an action which
//  explicitly sets it.


//  Working on appropriate target/action behavior for the Color Well. How do you handle a color
//  well that changes the background color? The trouble is that NSColorPanel sends the changeColor:
//  message to the first responder no matter what. Even though you can specify different 
//  target/action behavior, you can't override sending the changeColor: method.

//  You could change the firstResponder, but normal behavior retains the text view as the first
//  responder, even when changing the background color.


#import "SPColorWell.h"
#import "SPColorPicker.h"
#import "SPColorWellMenuView.h"
#import "HighlightingView.h"

@interface SPColorWell()

- (void) colorPickerDidChoseRemoveColor:(id)sender;
- (void) updateColorFromColorPicker:(id)sender;
- (void) setUpColorPickerMenu;

@end

#pragma mark -

@implementation SPColorWell

@synthesize title;
@synthesize canRemoveColor;

@synthesize borderType;

@synthesize removeColorAction;
@synthesize removeColorTarget;

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        // Initialization code here.
        self.color = [NSColor colorWithCalibratedWhite:0. alpha:1.];
		self.borderType = NSBezelBorder;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.color = [NSColor colorWithCalibratedWhite:0. alpha:1.];
		self.borderType = NSBezelBorder;
    }
    
    return self;
}

- (void)dealloc
{
    [_colorPickerMenu release], _colorPickerMenu = nil;
    [_colorPicker release], _colorPicker = nil;
    [self.color release];
    self.title = nil;
    
    [super dealloc];
}

#pragma mark -

- (void)drawRect:(NSRect)dirtyRect 
{
    NSRect bds = [self bounds];
    NSRect colorArea = bds;
    
	if ( self.borderType != NSNoBorder )  {
        // frame and internal gradient
        
        NSRect frameArea = bds;
        NSRect gradientArea = NSInsetRect(bds, 1, 1);
        
		if ( self.borderType == NSBezelBorder ) {
			// make room for single pixel shadow
			frameArea.size.height-=1;
			frameArea.origin.y+=1;
			
			gradientArea.origin.y += 1;
			gradientArea.size.height-=1;
			
			NSShadow *inset = [[[NSShadow alloc] init] autorelease];
			[inset setShadowColor:[NSColor colorWithCalibratedWhite:0.78 alpha:1.]];
			[inset setShadowOffset:NSMakeSize(0,-1)];
			[inset setShadowBlurRadius:0.];
			
			
			[[NSGraphicsContext currentContext] saveGraphicsState];
			[inset set];
        
			// frame
			[[NSColor colorWithCalibratedWhite:0.45 alpha:1.0] set];
			NSRectFill(frameArea);
			
			[[NSGraphicsContext currentContext] restoreGraphicsState];
        }
		else {
			// frame
			[[NSColor colorWithCalibratedWhite:0.45 alpha:1.0] set];
			NSRectFill(frameArea);
		}
		
        // background fill with single pixel bottom shadow
        NSGradient *background = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.94 alpha:1.0] 
                endingColor:[NSColor colorWithCalibratedWhite:0.7 alpha:1.0]] autorelease];
    
        [background drawInRect:gradientArea angle:270.];
        
        // adjust the color area
        colorArea = NSInsetRect(gradientArea, 1., 1.);
    }
    
    [self drawWellInside:colorArea];
    if ( self.title ) [self drawTitleInside:colorArea];
}

- (void)drawWellInside:(NSRect)insideRect 
{
    // NSAssert(self.color!=nil, @"color must not be nil");
    
    [self.color set];
    NSRectFill(insideRect);
}

- (void)drawTitleInside:(NSRect)insideRect
{
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]], NSFontAttributeName,
            [NSColor blackColor], NSForegroundColorAttributeName, 
            nil];
    
    NSSize size = [self.title sizeWithAttributes:attrs];
    NSPoint origin = NSMakePoint(NSMidX(insideRect)-size.width/2, 1+(NSMidY(insideRect)-size.height/2));
    
    [self.title drawAtPoint:origin withAttributes:attrs];
}

#pragma mark -

- (void)takeColorFrom:(id)sender
{
    if ([sender respondsToSelector: @selector(color)])
        self.color = [sender color];
    
    [_colorPicker takeColorFrom:sender];
}

- (void) updateColorFromColorPicker:(id)sender
{
    // Send the color to the shared color panel which passes the changeColor: method
    // to the first responder. I am unable send the changeColor: method directly
    // TextView's don't ask me for the color
    
    //id target = [NSApp targetForAction:@selector(changeColor:)];
    //[NSApp sendAction:@selector(changeColor:) to:target from:self];
    
    // #warning we don't necessarily want to do this, instead send our target/action?
    [[NSColorPanel sharedColorPanel] setColor:[_colorPicker color]];
    self.color = [_colorPicker color];
}

- (void) colorPickerDidChoseRemoveColor:(id)sender
{    
    if ( !self.removeColorTarget || !self.removeColorTarget )
        return;
    
    [self.removeColorTarget performSelector:self.removeColorAction withObject:self];
}

#pragma mark -

- (void)mouseDown:(NSEvent *)theEvent
{
    // when the menu is already popped and I double-click outside it,
    // the menu disappears but then I receive a mouseDown event again,
    // so check where the mouse down occurred.
    
    NSPoint eventLocation = [theEvent locationInWindow];
    NSPoint localPoint = [[self superview] convertPoint:eventLocation fromView:nil];
    
    if ( ![[self superview] mouse:localPoint inRect:[self frame]] )
        return;
    
    if ( _colorPickerMenu == nil ) {
        [self setUpColorPickerMenu];
    }
    
    // Unfortunately, doing so also displays the color panel, which isn't what we want
    // thuse the necessity for the glue code you see in the app delegate
    // [self activate:NO];
    
    // pop it
    [_colorPickerMenu popUpMenuPositioningItem:[_colorPickerMenu itemAtIndex:0]
            atLocation:NSMakePoint(0,-4) // don't care for hardcoding this value
            inView:self];
}

- (void) setUpColorPickerMenu
{
    NSSize pickerDims = [SPColorPicker proposedFrameSizeForAreaDimension:13];
    static NSInteger kHighlightHeight = 22;
    static NSInteger kTextHeight = 14;
    static NSInteger kImageDim = 18;
    static NSInteger kPadding = 4;
       
    _colorPickerMenu = [[NSMenu alloc] initWithTitle:@""];
    _colorPicker = [[SPColorPicker alloc] initWithFrame:
            NSMakeRect( kPadding,kHighlightHeight+kPadding,
            pickerDims.width,pickerDims.height)];
    
    // normal action for selecting a color
    _colorPicker.action = @selector(updateColorFromColorPicker:);
    _colorPicker.target = self;
    
    SPColorWellMenuView *menuView = [[[SPColorWellMenuView alloc] 
            initWithFrame:NSMakeRect(0,0,pickerDims.width+(kPadding*2),
            pickerDims.height+kHighlightHeight+kPadding)] autorelease];
    [menuView addSubview:_colorPicker];
    
    NSMenuItem *pickerItem = [[[NSMenuItem alloc] initWithTitle:@"" action:nil 
            keyEquivalent:@""] autorelease];
    
    [pickerItem setView:menuView];
    
    // set up a view with image and text subviews
    // size must be adjusted for longest localized "show colors"
    
    HighlightingView *showParent = [[[HighlightingView alloc] initWithFrame:
            NSMakeRect(0,0,pickerDims.width+(kPadding*2),kHighlightHeight)] 
            autorelease];
    
    [menuView addSubview:showParent];
    
    // image and text belong in the parent
    
    NSImageView *imageView = [[[NSImageView alloc] initWithFrame:
            NSMakeRect(kPadding,kPadding/2,kImageDim,kImageDim)] 
            autorelease];
    
    NSTextField *textField = [[[NSTextField alloc] initWithFrame:
            NSMakeRect(kImageDim+kPadding*3/2,kPadding,
            pickerDims.width-(kImageDim+(kPadding*3/2)),kTextHeight)]
            autorelease];
    
    [showParent addSubview:imageView];
    [showParent addSubview:textField];
    
    NSImage *colorImage = [NSImage imageNamed:NSImageNameColorPanel];
    [imageView setImageScaling:NSScaleProportionally];
    [imageView setImageFrameStyle:NSImageFrameNone];
    [imageView setImage:colorImage];
    
    [textField setStringValue:NSLocalizedString(@"Show Colors", @"")];
    [textField setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
    [textField setDrawsBackground:NO];
    [textField setSelectable:NO];
    [textField setEditable:NO];
    [textField setBordered:NO];
    
    menuView.colorPickerView = _colorPicker;
    menuView.showColorsView = showParent;
    menuView.colorWell = self;
    
    [_colorPickerMenu addItem:pickerItem];
    [_colorPickerMenu setDelegate:self];

}

- (void)menuWillOpen:(NSMenu *)menu
{
    //NSLog(@"%s",__PRETTY_FUNCTION__);
    
    // An item which can change its color automatically updates the shared color panel,
    // so we query it for the current color: there is no shared protocol which various
    // objects adopt to indicate they have a color or can change it
    
    // the HighlightView handles underlying text colors
    [(HighlightingView*)[(SPColorWellMenuView*)[_colorPicker superview] showColorsView] 
            setHighlighted:NO];
    
    // update the color picker from the color well, coordinated with the system color panel
    // originally we were updating self from the color panel, but we don't want to do this
    // when there is more than one color well and ours hasn't been activated yet
    // [self takeColorFrom:[NSColorPanel sharedColorPanel]];
    [_colorPicker takeColorFrom:self];
    
    // remember the picker's current selection
    // this is recalled when the mouse moves out of the picker from the 
    // color well menu view mouse tracking methods
    
    [_colorPicker pushCurrentSelection];
    
    // update the remove color option and target/action
    _colorPicker.canRemoveColor = self.canRemoveColor;
    _colorPicker.removeColorAction = @selector(colorPickerDidChoseRemoveColor:);
    _colorPicker.removeColorTarget = self;
}

@end

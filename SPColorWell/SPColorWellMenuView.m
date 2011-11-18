//
//  SPColorWellMenuView.m
//  SPColorWell
//
//  Created by Philip Dow on 11/17/11.
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

#import "SPColorWellMenuView.h"
#import "SPColorPicker.h"
#import "HighlightingView.h"

static NSString *kColorWellMenuViewTrackerKey = @"SPColorWellMenuViewTrackerKey";
static NSInteger kColorPickerView = 0;
static NSInteger kHighlightView = 1;

@interface SPColorWellMenuView()

- (NSTrackingArea*) trackingAreaForView:(NSView*)aView identifier:(NSInteger)viewId;
- (void) sendShowColorsAction;

@end

#pragma mark -

@implementation SPColorWellMenuView

@synthesize showColorsView;
@synthesize colorPickerView;
@synthesize colorWell;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [_colorPickerTrackingArea release], _colorPickerTrackingArea = nil;
    [_highlightTrackingArea release], _highlightTrackingArea = nil;
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}

#pragma mark -

- (void)updateTrackingAreas {
    
    if ( _highlightTrackingArea ) { 
        [self removeTrackingArea:_highlightTrackingArea];
        [_highlightTrackingArea release], _highlightTrackingArea = nil;
    }
    if ( _colorPickerTrackingArea ) { 
        [self removeTrackingArea:_colorPickerTrackingArea];
        [_colorPickerTrackingArea release], _colorPickerTrackingArea = nil;
    }
    
    _highlightTrackingArea = [[self trackingAreaForView:showColorsView identifier:kHighlightView] retain];
    [self addTrackingArea: _highlightTrackingArea];
    
    _colorPickerTrackingArea = [[self trackingAreaForView:colorPickerView identifier:kColorPickerView] retain];
    [self addTrackingArea: _colorPickerTrackingArea];

}

- (NSTrackingArea*) trackingAreaForView:(NSView*)aView identifier:(NSInteger)viewId {
    
    NSRect trackingRect = [aView frame];
    NSTrackingAreaOptions trackingOptions = NSTrackingEnabledDuringMouseDrag | NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp;
    NSDictionary *trackerData = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:viewId], kColorWellMenuViewTrackerKey, nil];
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:trackingRect 
            options:trackingOptions owner:self userInfo:trackerData];
    
    return [trackingArea autorelease];
}

- (void) mouseEntered:(NSEvent *)theEvent {
    //NSLog(@"%s",__PRETTY_FUNCTION__);
    
    // on the first mouse entered message, we must also clear the old selection area
    
    NSInteger view =[[(NSDictionary*)[theEvent userData] 
            objectForKey:kColorWellMenuViewTrackerKey] 
            integerValue];
    
    if ( view == kHighlightView ) {
        self.showColorsView.highlighted = YES;
    }
    else if ( view == kColorPickerView ) {
        // retain the original color selection - do this when the menu is popped
        ; //[self.colorPickerView pushCurrentSelection];
    }
}

- (void) mouseExited:(NSEvent *)theEvent {
    //NSLog(@"%s",__PRETTY_FUNCTION__);
    
    NSInteger view =[[(NSDictionary*)[theEvent userData] 
            objectForKey:kColorWellMenuViewTrackerKey] 
            integerValue];
            
    if ( view == kHighlightView ) {
        self.showColorsView.highlighted = NO;
    }
    else if ( view == kColorPickerView ) {
        // reset the color selection to the original color
        [self.colorPickerView popCurrentSelection];
    }
}

- (void)mouseUp:(NSEvent*)theEvent {
    
    // if we're inside the highlight view, send the Show Colors menu action
    
    NSPoint eventLocation = [theEvent locationInWindow];
    NSPoint localPoint = [self convertPoint:eventLocation fromView:nil];
    
    if ( [self mouse:localPoint inRect:[self.showColorsView frame]] )
        [self sendShowColorsAction];
}

- (void) sendShowColorsAction {
    
    // I prefer to decouple this and send the message to the color well itself
    // By activating the color well we allow the color well to handle a great
    // deal of the coordinating logic between the well and the color panel,
    // including when it is dismissed or when a different color well becomes
    // active
    
    [self.colorWell activate:NO]; // YES for exclusivity
    [NSApp orderFrontColorPanel:self.colorWell];
    
    // dismiss the menu being tracked
    NSMenuItem *actualMenuItem = [self enclosingMenuItem];
    NSMenu *menu = [actualMenuItem menu];
    [menu cancelTracking];
    
    [self setNeedsDisplay:YES];
}

@end

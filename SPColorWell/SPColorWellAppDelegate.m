//
//  SPColorWellAppDelagate.m
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


#import "SPColorWellAppDelegate.h"
#import "SPColorPicker.h"
#import "SPColorWell.h"

@implementation SPColorWellAppDelagate

@synthesize window;
@synthesize textView;
@synthesize bgColorWell;
@synthesize colorWell;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    // Make sure the shared color panel is available from the git go so that it will
    // reflect the initial color in our text view
    [NSColorPanel sharedColorPanel];
    
    [self.window setBackgroundColor:[NSColor colorWithCalibratedWhite:0.64 alpha:1.]];
    self.bgColorWell.title = NSLocalizedString(@"a", @"");
    
    // A means is required to coordinate the color at the insertion point of the text view
    // with the color displayed in the color well.
    
    // Normally color wells manage this automatically if they are active, SPColorWell does
    // too. But it is also possible that we need to update the color even when the
    // well is not active, as the well only becomes active when we show the color panel.
    // Why? Activating the well automatically shows the panel, and we don't want this when
    // the menu is popped
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
            selector:@selector(updateColorWell:) 
            name:NSTextViewDidChangeSelectionNotification 
            object:self.textView];
    [[NSNotificationCenter defaultCenter] addObserver:self 
            selector:@selector(updateColorWell:) 
            name:NSTextViewDidChangeTypingAttributesNotification 
            object:self.textView];
    
    // if you'd like the color well to be able to remove the color selection, enable
    // the logic for actually doing so is not yet implemented
    
    /* self.colorWell.removeColorAction = @selector(removeColorSelection:);
    self.colorWell.removeColorTarget = self;
    self.colorWell.canRemoveColor = YES; */
}

- (void) updateColorWell:(NSNotification*)aNotification
{
    NSDictionary *attrs = [[aNotification object] typingAttributes];
    NSColor *color = [attrs objectForKey:NSForegroundColorAttributeName];
    if ( color == nil ) color = [NSColor blackColor];
    colorWell.color = color;
    [colorWell setNeedsDisplay:YES];
}

- (IBAction) removeColorSelection:(id)sender
{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    // do something here like remove NSBackgroundColorAttributeName from an
    // attributed string
}

@end

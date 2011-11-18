//
//  SPColorPicker.m
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


#import "SPColorPicker.h"
#import "NSColor+CSSRGB.h"
#import "NSColor+ColorspaceEquality.h"

static NSString *kTrackerKey = @"SPColorPickerTrackerKey";
static CGFloat kColorPickerPadding = 2.; 

static NSArray * SPColorPickerDefaultColorsInCSSRGB() 
{
    // Would prefer to have the values derived from a single row of initial values
    // requires a nonlinear equation: hue and brightness values change at a changing pace
    
    // The color picker expects 120 colors for drawing. The first color represents
    // a "remove color" option
   
    static NSArray *cssColors = nil;
    if ( cssColors == nil ) {
        cssColors = [[NSArray alloc] initWithObjects:
                        
                @"rgb(255,255,255)", @"rgb(255,255,255)", @"rgb(235,235,235)", @"rgb(214,214,214)", @"rgb(192,192,192)", @"rgb(170,170,170)",
                @"rgb(146,146,146)", @"rgb(122,122,122)", @"rgb(96,96,96)", @"rgb(68,68,68)", @"rgb(35,35,35)", @"rgb(0,0,0)",
                
                @"rgb(0,55,72)", @"rgb(0,31,84)", @"rgb(18,7,57)", @"rgb(47,8,59)", @"rgb(61,6,27)", @"rgb(95,5,3)", 
                @"rgb(92,27,6)", @"rgb(89,51,12)", @"rgb(86,61,14)", @"rgb(102,97,27)", @"rgb(78,85,24)", @"rgb(36,61,23)",
                
                @"rgb(0,78,99)", @"rgb(0,48,118)", @"rgb(27,13,79)", @"rgb(70,17,85)", @"rgb(88,16,40)", @"rgb(134,12,7)",
                @"rgb(126,40,11)", @"rgb(124,73,20)", @"rgb(121,87,24)", @"rgb(141,133,40)", @"rgb(110,118,37)", @"rgb(53,87,36)",
                
                @"rgb(0,110,140)", @"rgb(0,69,163)", @"rgb(45,23,113)", @"rgb(99,27,119)", @"rgb(123,25,60)", @"rgb(185,22,14)",
                @"rgb(176,60,20)", @"rgb(171,103,32)", @"rgb(168,122,38)", @"rgb(196,187,60)", @"rgb(154,165,55)", @"rgb(75,121,53)",
                
                @"rgb(0,141,177)", @"rgb(0,90,206)", @"rgb(57,32,142)", @"rgb(126,37,152)", @"rgb(157,35,77)", @"rgb(232,30,20)",
                @"rgb(222,78,28)", @"rgb(216,131,43)", @"rgb(213,156,51)", @"rgb(246,234,78)", @"rgb(194,207,73)", @"rgb(98,156,70)",
                
                @"rgb(0,164,211)", @"rgb(0,102,245)", @"rgb(79,41,172)", @"rgb(156,46,182)", @"rgb(189,44,92)", @"rgb(255,60,38)",
                @"rgb(255,104,40)", @"rgb(255,168,57)", @"rgb(255,197,66)", @"rgb(255,250,104)", @"rgb(216,234,94)", @"rgb(113,186,85)",
                
                @"rgb(0,200,247)", @"rgb(51,139,246)", @"rgb(96,57,226)", @"rgb(194,62,234)", @"rgb(235,58,120)", @"rgb(255,96,86)",
                @"rgb(255,132,83)", @"rgb(255,178,85)", @"rgb(255,201,90)", @"rgb(255,246,129)", @"rgb(227,238,123)", @"rgb(146,210,112)",
                
                @"rgb(68,215,249)", @"rgb(113,169,248)", @"rgb(137,84,244)", @"rgb(215,91,245)", @"rgb(241,112,156)", @"rgb(255,139,133)",
                @"rgb(255,164,131)", @"rgb(255,197,130)", @"rgb(255,215,133)", @"rgb(255,247,162)", @"rgb(234,242,156)",  @"rgb(174,221,149)",
                
                @"rgb(142,228,251)", @"rgb(166,199,250)", @"rgb(179,142,246)", @"rgb(230,148,247)", @"rgb(247,163,191)", @"rgb(255,180,176)",
                @"rgb(255,196,174)", @"rgb(255,216,174)",  @"rgb(255,227,175)",  @"rgb(255,250,193)", @"rgb(242,246,190)", @"rgb(203,232,186)",
                
                @"rgb(200,241,253)", @"rgb(211,227,252)", @"rgb(217,202,250)", @"rgb(243,202,250)", @"rgb(251,211,223)", @"rgb(255,218,217)",
                @"rgb(255,226,216)", @"rgb(255,236,215)", @"rgb(255,241,216)", @"rgb(254,252,224)", @"rgb(248,250,222)", @"rgb(223,237,214)",
                
                nil];
    } 
    
    return cssColors;
}

#pragma mark -

@interface SPColorPicker()

- (NSRect) frameForAreaAtRow:(NSInteger)rowIndex column:(NSInteger)columnIndex;
- (NSTrackingArea*) trackingAreaForIndex:(NSInteger)index;
- (NSColor*) selectionColorForAreaColor:(NSColor*)aColor;
- (void) sendAction;

@end

#pragma mark -

@implementation SPColorPicker

@synthesize colors;
@synthesize canRemoveColor;
@synthesize selectionIndex;

@synthesize target;
@synthesize action;

@synthesize removeColorAction;
@synthesize removeColorTarget;

- (id)initWithFrame:(NSRect)frame
{
    // ideal frame width is factor of 12 + 12
    // ideal frame height is this factor + 10
    // eg 228x190 factor 18
    
    // see proposedFrameSizeForAreaDimension
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        
        _trackingAreas = [[NSMutableArray alloc] init];
        self.selectionIndex = [NSIndexSet indexSetWithIndex:22];
        self.canRemoveColor = NO;
        
        // default colors
        
        NSMutableArray *defaultColors = [NSMutableArray array];
        
        for ( NSString *cssColor in SPColorPickerDefaultColorsInCSSRGB() ) {
            NSColor *color = [NSColor colorWithCSSRGB:cssColor];
            if ( color == nil ) {
                NSLog(@"%s - There was a problem parsing the default text colors", __PRETTY_FUNCTION__);
                defaultColors = nil;
                break;
            }
            
            [defaultColors addObject:color];
        }
        
        if ( defaultColors != nil ) self.colors = defaultColors;
    }
    
    return self;
}

- (void)dealloc
{
    self.colors = nil;
    self.selectionIndex = nil;
    
    [_originalSelection release], _originalSelection = nil;
    [_trackingAreas release], _trackingAreas = nil;
    
    [super dealloc];
}

#pragma mark -

- (BOOL) isFlipped {
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    // NSAssert([self.colors count] == 120, @"Expected 120 colors for drawing");
    
    NSRect bds = [self bounds];
    NSRect paddedBds = NSInsetRect(bds, kColorPickerPadding, kColorPickerPadding);
        
    // background fill
    NSGradient *background = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] 
            endingColor:[NSColor colorWithCalibratedWhite:0.4 alpha:1.0]] autorelease];
    
    [background drawInRect:paddedBds angle:90.];
    
    // inset effect (shade the top, highlight the bottom)
    
    for ( NSInteger j = 0; j < 10; j++ ) {
        for ( NSInteger i = 0; i < 12; i++ ) {
            
            if ( j*12+i >= [self.colors count] ) break;
            NSColor *targetColor = [self.colors objectAtIndex:j*12+i];
            
            NSRect area = [self frameForAreaAtRow:i column:j];
            [targetColor set];
            NSRectFill(area);
        }
    }
    
    // no color option: enabled or disabled
    // strike it out faded or full
    
    NSRect area = [self frameForAreaAtRow:0 column:0];
    NSColor *strikeColor = [NSColor colorWithCalibratedRed:1. green:0. blue:0. 
            alpha:(self.canRemoveColor?1.:.5)];
    
    NSBezierPath *line = [NSBezierPath bezierPath];
    [line moveToPoint:NSMakePoint(NSMaxX(area),NSMinY(area))];
    [line lineToPoint:NSMakePoint(NSMinX(area),NSMaxY(area))];
    [line setLineWidth:1.];
    
    [strikeColor set];
    [line stroke];
    
     // frame
    [[NSColor colorWithCalibratedWhite:0.4 alpha:1.0] set];
    NSFrameRect(paddedBds);
    
    // selection
    // do not draw at 0 index if canRemoveColor = NO
    
    if ( [self.selectionIndex count] == 1 && ( [self.selectionIndex firstIndex] > 0 
            || self.canRemoveColor == YES ) ) {
        NSInteger index = [self.selectionIndex firstIndex];
        NSInteger col = floor(index / 12);
        NSInteger row = floor(index % 12);
        
        NSRect area = [self frameForAreaAtRow:row column:col];
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSInsetRect(area, -1, -1)];
        
        // the selection color depends on the color at the index
        NSColor *selectionColor = [self selectionColorForAreaColor:[self.colors 
                objectAtIndex:[self.selectionIndex firstIndex]]];
        
        [selectionColor set];
        [path setLineWidth:2.];
        [path stroke];
    }
    
}

- (NSColor*) selectionColorForAreaColor:(NSColor*)aColor {
    static CGFloat kColorLimit = 144.; // adjust to preference
    
    NSColor *rgbColor = [aColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    if ( !rgbColor ) return [NSColor colorWithCalibratedWhite:1. alpha:1.];
    
    CGFloat red,green,blue,alpha;
    [rgbColor getRed:&red green:&green blue:&blue alpha:&alpha];
    
    // given RGB values all approaching white, invert the selection color
    if ( red >= kColorLimit/255. && blue >= kColorLimit/255. && green >= kColorLimit/255. )
        return [NSColor colorWithCalibratedWhite:0.1 alpha:1.];
    
    return [NSColor colorWithCalibratedWhite:1. alpha:1.];
    
    NSLog(@"%@",rgbColor);
    return nil;
}

- (NSRect) frameForAreaAtRow:(NSInteger)rowIndex column:(NSInteger)columnIndex {
    
    CGFloat rowWidth = floor ( (NSWidth([self bounds]) - 12) / 12 );
    CGFloat rowHeight = floor ( (NSHeight([self bounds]) - 10) / 10 );
    
    NSRect area = NSMakeRect(kColorPickerPadding + rowIndex*rowWidth + rowIndex, 
            kColorPickerPadding + columnIndex*rowHeight + columnIndex, rowWidth, rowHeight);
    return area;
}

+ (NSSize) proposedFrameSizeForAreaDimension:(CGFloat)dimension {
    // ideal frame width is factor of 12 + 12
    // ideal frame height is this factor + 10
    // eg 228x190 factor 18
    
    return NSMakeSize((dimension+1)*12+(kColorPickerPadding*2),
            (dimension+1)*10+(kColorPickerPadding*2));
}

#pragma mark -

- (void) pushCurrentSelection {
    // remember the current selection
    [_originalSelection release], _originalSelection = nil;
     _originalSelection = [self.selectionIndex retain];
}   

- (void) popCurrentSelection {
    self.selectionIndex = _originalSelection;
    [self setNeedsDisplay:YES];
}

#pragma mark -

// See sample code CustomMenus. One tracking area for every subsection in the view.
// It seems that mouseEntered and -Exited events don't register with NSTrackingEnabledDuringMouseDrag
// when NSTrackingMouseMoved is also specified, but mouseMoved events don't register with just
// NSTrackingEnabledDuringMouseDrag, at least in a popup menu.

- (void)updateTrackingAreas {
    
    for ( NSTrackingArea *anArea in _trackingAreas ) {
        [self removeTrackingArea:anArea];
    }
    
    [_trackingAreas removeAllObjects];
    
    for (NSInteger index = 0; index < self.colors.count; index++) {
        NSTrackingArea *trackingArea = [self trackingAreaForIndex:index];
        [_trackingAreas addObject:trackingArea];
        [self addTrackingArea: trackingArea];
    }
    
}

- (NSTrackingArea*) trackingAreaForIndex:(NSInteger)index {
    
    NSDictionary *trackerData = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:index], kTrackerKey, nil];
    NSInteger col = floor(index / 12);
    NSInteger row = floor(index % 12);
    
    // Expand the drawing area rect by a single pixel to the right and down,
    // taking into acount the dividing line between each color box
    
    NSRect trackingRect = [self frameForAreaAtRow:row column:col];
    trackingRect.size.width+=1, trackingRect.size.height+=1;
    
    NSTrackingAreaOptions trackingOptions = NSTrackingEnabledDuringMouseDrag | NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp;
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:trackingRect 
            options:trackingOptions owner:self userInfo:trackerData];
    
    return [trackingArea autorelease];
}

- (void) mouseEntered:(NSEvent *)theEvent {
    //NSLog(@"%s",__PRETTY_FUNCTION__);
    
    // on the first mouse entered message, we must also clear the old selection area
    
    // mark the view as needing display in the old selection area
    if ( self.selectionIndex.count > 0 ) {
        NSInteger col = floor([self.selectionIndex firstIndex] / 12);
        NSInteger row = floor([self.selectionIndex firstIndex] % 12);
        [self setNeedsDisplayInRect:NSInsetRect([self frameForAreaAtRow:row column:col], -3, -3)];
    }
    
    // new selection index
    self.selectionIndex = [NSIndexSet indexSetWithIndex:[[(NSDictionary*)[theEvent userData] 
            objectForKey:kTrackerKey] integerValue]];
    
    // mark the receiver as needing display in the new selection area
    NSInteger col = floor([self.selectionIndex firstIndex] / 12);
    NSInteger row = floor([self.selectionIndex firstIndex] % 12);
    [self setNeedsDisplayInRect:NSInsetRect([self frameForAreaAtRow:row column:col], -3, -3)];
}

- (void) mouseExited:(NSEvent *)theEvent {
    //NSLog(@"%s",__PRETTY_FUNCTION__);
    
    // when the cursor completely leaves the view, we need to reset to the original value
    // this is handled by the enclosing color well menu view; don't like that coupling,
    // would rather handle it here
    
//  self.selectionIndex = [NSIndexSet indexSet];
}

- (void)mouseUp:(NSEvent*)event {
    [self sendAction];
}

- (void)sendAction {
    
    // The action depends on the selection. At index 0 we want to remove the color,
    // which requires a separate action
    
    if ( [self.selectionIndex count] > 0 ) {
    
        if ( [self.selectionIndex firstIndex] > 0 )
            // Send the action set on the actualMenuItem to the target set on the actualMenuItem, and make come from the actualMenuItem.
            [self.target performSelector:self.action withObject:self];
        else if ( self.canRemoveColor )
            // separate action for remove color
            [self.removeColorTarget performSelector:self.removeColorAction withObject:self];
    }
    
    // dismiss the menu being tracked
    NSMenuItem *actualMenuItem = [self enclosingMenuItem];
    NSMenu *menu = [actualMenuItem menu];
    [menu cancelTracking];
    
    [self setNeedsDisplay:YES];
}

#pragma mark -

- (NSColor*) color {
    if ( self.selectionIndex.count == 0 ) return nil;
    return [self.colors objectAtIndex:[self.selectionIndex firstIndex]];
}

- (void) takeColorFrom:(id)sender {
    if ([sender respondsToSelector: @selector(color)])
       [self updateSelectionIndexWithColor:[sender color]];
}

- (BOOL) updateSelectionIndexWithColor:(NSColor*)aColor {
    
    // try equalivency comparison first
    NSInteger index = [self.colors indexOfObject:aColor];
    NSIndexSet *newSelection = ( index==NSNotFound ? [NSIndexSet indexSet] 
            : [NSIndexSet indexSetWithIndex:index] );
            
    // "identical" colors in different color spaces will not be equal so compare in shared color space
    // black in NSCalibratedWhiteColorSpace != black in NSCalibratedRGBColorSpace
    
    if ( newSelection.count == 0 ) {
        NSInteger i = 0;
        for ( NSColor *indexColor in self.colors ) {
            if ( [indexColor isEqualToColor:aColor colorSpace:NSCalibratedRGBColorSpace] ) {
                newSelection = [NSIndexSet indexSetWithIndex:i];
                break;
            } i++;
        }
    }
    
    [self setSelectionIndex:newSelection];
    [self setNeedsDisplay:YES];
    
    return (BOOL)[newSelection count];
 }

@end

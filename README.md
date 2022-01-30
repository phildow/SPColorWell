# SPColorWell
<img width="215" alt="Screenshot 2022-01-30 at 10 05 05 PM" src="https://user-images.githubusercontent.com/23420208/151703148-ee65b8f1-f9db-48c3-b036-e1d732e31484.png">

SPColorWell implements an iWork-esque color well and pop-up color picker for
changing the color of an arbitrary selection. Drop the source files into your
project and add a custom NSView to your NIB file, changing its class to SPColorWell.

The only glue work you need to worry about is mediating the color displayed
in the color well and the color of the current selection in the view with which
it is associated. The app delegate demonstrates how to do this with an NSTextView.

# LICENSING
Refer to [LICENSE](/LICENSE.md) for licensing.

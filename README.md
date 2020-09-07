# Lefty VRMod
A modified version of VRMod for GMod that allows you to use your left hand for weapons and tools.  
*This now also includes improvements not directly related to left-handed support*  

## Improvements over original
* Left-handed support
* Responsive keyboard (the keys now go darker when pressed like actual UI buttons, so you know if a keypress is registered)
* Hand positions and angles are no longer overrided when holding a weapon, mainly fixing issues where your hand would be behind your back when using the crossbow (I beleive this was used in the original version to avoid having to precisely configure offsets for each weapon to match your IRL hand's position)

## Known bugs
* Using world models is no longer supported (you can still enable it from console, but it won't work properly) as the code that positions the viewmodel when using them interfered with my new left-handed code.  
This isn't too bad as world models don't work 100% in the original version either.  

## Untested
* I have no idea if this will work in multiplayer, looking at the net code I cant see an immediate problem, but I'm unable to actually test it.  

## Installation
Perform the same steps as installing normal VRMod [here](https://steamcommunity.com/sharedfiles/filedetails/?id=1678408548#highlightContent "Steam Workshop Page") except subscribing to the addon itself.  
Then download, unzip, and drag my addon to your GMod's addon folder.  
**WARNING:** Make sure you don't have the original version of VRMod running along side this.

Also, if you're using left-handed mode, you'll want to remap the binding for fire to your left hand  
The existing bindings, and instructions on how to change them, can be found at [VRMod's workshop page](https://steamcommunity.com/sharedfiles/filedetails/?id=1678408548 "Steam Workshop Page")
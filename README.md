# manickyoj's fork of GodotOceanWaves
This fork aims to combining the best of the Godot ocean work from 2Retr0, krautdev, and Lucactus22.
- From [2Retr0's repo](https://github.com/2Retr0/GodotOceanWaves) we take the original, beautiful FFT ocean wave implementation
- From [krautdev](https://github.com/krautdev/GodotOceanWaves), I tried to take the depth-sampling work, but ran into issues getting it to run. Rather, I just took the depth color absorption addition to the filter
- From [Lucatatus22](https://github.com/Lucactus22/GodotOceanWaves_bouyancy), I integrated the depth-sampling I have here as well as an 8km clipmap (which extends to the visual horizon from a decent height off the waves), but scrapped parts that were unnecessary and caused poor performance.

In addition, I've improved on the Lucatatus22 solution for buoyancy. Luctatus22's simulation relied on points on a mesh as 'sprung' from the water's surface. That can simulate some reasonable results but does not at all account for the submerged volume and so only works you tune the forces and masses quite precisely for each object. My simulation uses BoxShape2D cells as buoyant 'cells' with independent densities that apply approximated forces for gravity and buoyancy at the cell's center and determine forces automatically based on the cells' volume.

This solution is robust and flexible: by fitting cells to an arbitrary model (eg. a ship), the water will provide forces appropriate to its shape. Moreover, the variable densities of the cells let you simulate some pretty cool things. You can add ballast to a ship to keep it upright without relying on eg. angle locking. Moreover, you can accurately simulate a ship sinking by altering the density of some of the buoyant cells as they take on water.

## TIPS for using
 - **Cell geometry:** Several cells will give more accurate results. I'd suggest 4 cells minimum aligned on the XZ plane: if the cells are all stacked on the same X or Z axis, your floating body will have all forces applied to the center and won't roll with the waves as well. If your boat has a narrow axis (most do have one), setting the boxes a bit outside the nominal 'sides' of the ship will help it simulate rolling with the waves better. I set up my boat for the demo with 8 cells. 6 in a very narrow 'hexagon' for the main body of the boat to simulate the parts that float well and 2 ballast cells fore and aft to help right the boat and keep it from getting too 'floaty'
 - **Rigidbody physics:** For an accurate physical simulation, let the code do the work of setting the rigidbody's mass and moments of inertia by adding all the cells to the cells array of the mass_calcultion script on the parent rigidbody. Turn off gravity on the rigidbody by setting the gravity scale to 0 and let the cells calculate gravity for you. Lastly, the simulation doesn't yet account for drag (which helps prevent inaccurate rolling etc). I've found good results with an angular damp on rigidbodies of 0.5 and linear damp of about 0.1. Play around and find what feels right to you
 - **Setting cell density:** For cells that should float, start around 100-300 kg/m^2. Water is 1000 kg/m^2, air is ~1.5 kg/m^2, solid wood is ~400-700 kg/m^2, solid steel is 7000 kg/m^2. A cell matching the weight of water would be neutrally buoyant, with just enough force to fully immerse itself. I'd suggest ballast should be about 1000-1200 kg/m^2
 - Because I messed up an axis on the model I'm using, the engine thrust, if you use it, is inverted. Sorry ¯\_(ツ)_/¯ Will fix at some point


https://github.com/user-attachments/assets/fe37fde5-51bf-4512-9cba-7e3bb36739da

Above: A box floating with an octet of equal sized, equal density cells

https://github.com/user-attachments/assets/3068c10b-b781-465f-a093-fd14d6cd6dd0

Above: Had some fun with shaders too. Boat is a hex of floation cells with a fore and aft ballast cell underneath

### TODO:
- [x] Calculate the volume of the submerged object and use that to determine the resultant buoyant force, rather than approximating at vertices based on a constant, volume independent force as it does now
- [x] Automatically sum the weights of buoyancy cells to the rigidbody to save manual config. Consider using something other than colliders to better preserve performance
- [ ] Fix engine thrust to be the correct direction and fix the ferry model to face the right way while I'm at it
- [ ] Add an option to automatically subdivide one big cell into quadrants or octets to minimize the amount of manual cell creation needed to set up a boat
- [ ] Make a $1CK demo of a ship taking damage and starting to list and sink
- [ ] Simulate hydrodynamic drag as a way to resist linear and angular forces as a function of area and , rather than Godot's physically inaccurate damping on rigidbodies
- [ ] Keep the water out of boats, perhaps. Water washing over the boats is a little cool, but water welling up within a boat or disappearing to nothing is less cool. Luctatus22's README has some ideas here
- [ ] See if I can figure out the same thing krautdev and Luctatus22 were working on: reading displacement textures from the GPU more efficiently. Luctatus22's README has some ideas here
- [ ] Add some nice VFX for wakes and splashes when a hull slaps down on water


# manickyoj's fork of GodotOceanWaves
This fork aims to combining the best of the Godot ocean work from 2Retr0, krautdev, and Lucactus22.
- From [2Retr0's repo](https://github.com/2Retr0/GodotOceanWaves) we take the original, beautiful FFT ocean wave implementation
- From [krautdev](https://github.com/krautdev/GodotOceanWaves), I tried to take the depth-sampling work, but ran into issues getting it to run. Rather, I just took the depth color absorption addition to the filter
- From [Lucatatus22](https://github.com/Lucactus22/GodotOceanWaves_bouyancy), I integrated the depth-sampling I have here as well as an 8km clipmap (which extends to the visual horizon from a decent height off the waves), but scrapped parts that were unnecessary and caused poor performance.

In addition, I've improved on the Lucatatus22 solution for buoyancy. Luctatus22's simulation relied on points on a mesh as 'sprung' from the water's surface. That can simulate some reasonable results but does not at all account for the submerged volume and so only works you tune the forces and masses quite precisely for each object. My simulation uses BoxShape2D cells as buoyant 'cells' with independent densities that apply approximated forces for gravity and buoyancy at the cell's center and determine forces automatically based on the cells' volume.

This solution is robust and flexible: by fitting cells to an arbitrary model (eg. a ship), the water will provide forces appropriate to its shape. Moreover, the variable densities of the cells let you simulate some pretty cool things. You can add ballast to a ship to keep it upright without relying on eg. angle locking. Moreover, you can accurately simulate a ship sinking by altering the density of some of the buoyant cells as they take on water.

## TIPS
 - The closer to cubical the box cells are, the better the simulation. More cells will also give more accurate results at the cost of quality. I'd suggest 4 cells minimum aligned on the XZ plane: if the cells are all stacked on the same X or Z axis, your floating body will have all forces applied to the center and won't roll with the waves as well.
 - For the most accurate physical simulation, make sure the parent rigidbody mass matches the constituent box cell volumes * densities.
 - The buoyancy simulation doesn't yet account for drag (which helps prevent inaccurate rolling etc). I've found good results with an angular damp on rigidbodies of 2-3 and linear damp of about 0.1

https://github.com/user-attachments/assets/fe37fde5-51bf-4512-9cba-7e3bb36739da


### TODO:
- [x] Calculate the volume of the submerged object and use that to determine the resultant buoyant force, rather than approximating at vertices based on a constant, volume independent force as it does now
- [ ] Automatically sum the weights of buoyancy cells to the rigidbody to save manual config. Consider using something other than colliders to better preserve performance.
- [ ] Simulate hydrodynamic drag as a way to resist linear and angular forces as a function of area and , rather than Godot's physically inaccurate damping on rigidbodies
- [ ] See if I can figure out the same thing krautdev and Luctatus22 were working on: reading displacement textures from the GPU more efficiently. Luctatus22's README has some ideas here
- [ ] Add some nice VFX for wakes and splashes when a hull slaps down on water
- [ ] Keeping the water out of boats, perhaps. Water washing over the boats is a little cool, but water welling up within a boat or disappearing to nothing is less cool. Luctatus22's README has some ideas here

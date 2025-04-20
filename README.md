# manickyoj's fork of GodotOceanWaves
This fork aims to combining the best of the Godot ocean work from 2Retr0, krautdev, and Lucactus22.
- From [2Retr0's repo](https://github.com/2Retr0/GodotOceanWaves) we take the original, beautiful FFT ocean wave implementation
- From [krautdev](https://github.com/krautdev/GodotOceanWaves), I tried to take the depth-sampling work, but ran into issues getting it to run. Rather, I just took the depth color absorption addition to the filter
- From [Lucatatus22](https://github.com/Lucactus22/GodotOceanWaves_bouyancy), I integrated the depth-sampling I have here as well as an 8km clipmap (which extends to the visual horizon from a decent height off the waves), but scrapped some parts that were both unnecessary and caused poor performance.

I've also implemented my own buoyancy simulation which takes in a mesh and samples the depth at all vertices, applying resultant forces at that vertex. Resultant forces include not just the buoyant force, but also hydrodynamic drag (that is, water resistance).

https://github.com/user-attachments/assets/fe37fde5-51bf-4512-9cba-7e3bb36739da


TODO:
- [ ] Calculate the volume of the submerged object and use that to determine the resultant buoyant force, rather than approximating at vertices based on a constant, volume independent force as it does now
- [ ] See if I can figure out the same thing krautdev and Luctatus22 were working on: reading displacement textures from the GPU more efficiently. Luctatus22's README has some ideas here
- [ ] Keeping the water out of boats, perhaps. Water washing over the boats is a little cool, but water welling up within a boat or disappearing to nothing is less cool. Luctatus22's README has some ideas here


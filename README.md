This fork fixes two sets of errors I was confronted with when opening this wonderful project in Godot 4.7. According to my research, one of the errors might go back to 4.5, but I can not confirm.
I'm not a graphics programmer so I'm not 100% sure theses fixes are top notch, they did however remove the errors for me and I was able to run the project fine.

## Error 1 Readonly Uniforms

```
ERROR: Uniforms supplied for set (0):
ERROR: Set: 0 Binding: 0 Type: Image Writable: Y Length: 1
ERROR: are not the same format as required by the pipeline shader. Pipeline shader requires the following bindings:
ERROR: Set: 0 Binding: 0 Type: Image Writable: N Length: 1
ERROR: Set: 1 Binding: 0 Type: StorageBuffer Writable: Y Length: 0
```

This error apparantly comes from heaving the uniforms in the shaders set to readonly. I came across this forum post which pointed me in this direction:
https://forum.godotengine.org/t/what-causes-the-error-uniforms-supplied-for-set-0/123044
Removing all "readonly" attributes for the uniforms in the shaders seems to have fixed this.

## Error 2 Push Constant padding

```
This compute pipeline requires (8) bytes of push constant data, supplied: (16)
```

Learned about push constants! Apparantly the padding requirements have changed in 4.7 according to this:
https://github.com/godotengine/godot/issues/120097

I changed to multiplying by 2 for 2 bytes, as suggested here: https://github.com/godotengine/godot/pull/114075); not sure this is the correct value as I don't understand entirely what is happening here, but again, fixed the error for me and project runs fine.

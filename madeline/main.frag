// Replaces colors, based on the paletteImage.

#version 120
uniform sampler2D iChannel0;

uniform sampler2D paletteImage;
uniform float currentPalette;

uniform vec4 tintColor;


#define COLOR_COUNT 1
#define PALETTE_COUNT 1


#include "shaders/logic.glsl"


float colorsAreCloseEnough(vec4 a, vec4 b)
{
	return le(abs(a.r - b.r) + abs(a.g - b.g) + abs(a.b - b.b) + abs(a.a - b.a), 0.01);
}


void main()
{
	vec4 original = texture2D(iChannel0, gl_TexCoord[0].xy);
	vec4 c = original;

	float y = (currentPalette + 0.1)/PALETTE_COUNT;

	for (float i = 0; i < COLOR_COUNT; i++) {
		float x = (i + 0.1)/COLOR_COUNT;

		vec4 colorHere       = texture2D(paletteImage, vec2(x,0.0));
		vec4 replacementHere = texture2D(paletteImage, vec2(x,y));

		c = mix(c,replacementHere, colorsAreCloseEnough(original,colorHere));
	}

	// Apply tint
	c *= tintColor;
	
	gl_FragColor = c*gl_Color;
}
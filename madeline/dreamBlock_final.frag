#version 120
uniform sampler2D iChannel0;

uniform sampler2D particleBuffer;

uniform vec4 outlineColor;

uniform vec2 bufferSize;


#define OUTLINE_THICKNESS 0
#define PIXEL_SIZE 1


#include "shaders/logic.glsl"


float findIsOutline(float isOutline,vec2 xy, vec2 dir)
{
	for (float i = 1.0; i <= OUTLINE_THICKNESS/PIXEL_SIZE; i++)
	{
		vec2 xyHere = xy + (dir*i*PIXEL_SIZE)/bufferSize;
		vec4 colorHere = texture2D(iChannel0,xyHere);

		isOutline = max(isOutline,1.0 - colorHere.a);
	}

	return isOutline;
}


void main()
{
	vec2 xy = gl_TexCoord[0].xy;

	vec4 mask = texture2D(iChannel0,xy);

	// Find if it's an outline
	vec4 c = texture2D(particleBuffer,xy);

	#if OUTLINE_THICKNESS > 0.0
		float isOutline = 0.0;

		isOutline = findIsOutline(isOutline,xy,vec2(0.0,-1.0)); // up
		isOutline = findIsOutline(isOutline,xy,vec2(1.0,0.0));  // right
		isOutline = findIsOutline(isOutline,xy,vec2(0.0,1.0));  // down
		isOutline = findIsOutline(isOutline,xy,vec2(-1.0,0.0)); // left

		c = mix(c,outlineColor,isOutline);
	#endif

	c *= mask.a;

	
	gl_FragColor = c*gl_Color;
}
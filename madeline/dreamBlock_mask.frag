// The shader applied to the box being drawn to the mask.
// Just randomnly removes some of the pixels off of the edges.

#version 120
uniform sampler2D iChannel0;

uniform sampler2D perlinTexture;

uniform float time;

uniform vec2 size;

uniform float rippleSize;

uniform float pixelSize;

uniform vec2 cameraPos;


#include "shaders/logic.glsl"


vec2 shorterVec(vec2 a,vec2 b)
{
	return mix(a,b, gt(length(a),length(b)));
}

vec2 getDistToEdge(vec2 xy)
{
	vec2 distToLeft   = vec2(xy.x,0.0);
	vec2 distToTop    = vec2(0.0,xy.y);
	vec2 distToRight  = vec2(xy.x - size.x,0.0);
	vec2 distToBottom = vec2(0.0,xy.y - size.y);
	
	return shorterVec(distToLeft,shorterVec(distToTop,shorterVec(distToRight,distToBottom)));
}


float getPerlinValue(vec2 pos)
{
	vec2 baseXY = floor(pos/pixelSize)*pixelSize/vec2(400.0);

	vec2 xyA = mod(baseXY - time*0.0008,1.0);
	vec2 xyB = mod(baseXY + time*0.0005,1.0);

	vec4 colorA = texture2D(perlinTexture,xyA);
	vec4 colorB = texture2D(perlinTexture,xyB);

	return (colorA.r + colorB.r)*0.5;
}


void main()
{
	vec2 xy = floor(gl_TexCoord[0].xy*size/pixelSize)*pixelSize;

	vec2 distToEdge = getDistToEdge(xy);
	vec2 edgeWorldPos = gl_FragCoord.xy + cameraPos - distToEdge;

	float edgeRemoved = floor(getPerlinValue(edgeWorldPos)*2.0*rippleSize/pixelSize + 0.5)*pixelSize;

	float alpha = ge(length(distToEdge),edgeRemoved);
	//float alpha = getPerlinValue(edgeWorldPos);

	gl_FragColor = vec4(alpha)*gl_Color;
	//gl_FragColor = vec4(vec3(getPerlinValue(edgeWorldPos)),1.0);
}
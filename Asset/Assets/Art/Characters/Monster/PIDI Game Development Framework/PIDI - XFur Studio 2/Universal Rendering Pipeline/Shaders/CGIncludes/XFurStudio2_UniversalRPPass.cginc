
#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED

UNITY_INSTANCING_BUFFER_START(XFurProps)
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles
UNITY_DEFINE_INSTANCED_PROP(float, _XFurInstancedCurrentPass)
UNITY_INSTANCING_BUFFER_END(XFurProps)


sampler2D _XFurSelfStrandsPattern;

half4 _XFurVFX1Color;

half4 _XFurVFX2Color;

half4 _XFurVFX3Color;

half4 _XFurVFX4Color;

half _XFurVFX1Penetration;

half _XFurVFX2Penetration;

half _XFurVFX3Penetration;

half _XFurVFX1Smoothness;

half _XFurVFX2Smoothness;

half _XFurVFX3Smoothness;


float _XFurForceNonInstanced;

//The absolute length of the fur
half _XFurLength[4];

//THe absolute thickness of the fur strands
half _XFurThickness[4];

//The curve used to control the ratio of the fur strand from the root to the tip
half _XFurThicknessCurve[4];

//The strength of the self-shadowing / occlusion applied to the fur
half _XFurOcclusion[4];

//The curve that controls how the shadowing goes from the roots to the tips of the fur
half _XFurOcclusionCurve[4];

half _XFurSelfSmoothness;

//Tint to be applied to the fur self-shadowing
half4 _XFurShadowsTint[4];

half _XFurSelfCurlAmountX;

half _XFurSelfCurlAmountY;

half _XFurSelfCurlSizeX;

half _XFurSelfCurlSizeY;

half _XFurSelfUnderColorMod, _XFurSelfOverColorMod;

half _XFurSelfRimBoost;

half4 _XFurSelfRimColor;

half4 _XFurSelfSpecularTint;

float _XFurLODArea;

float _XFurLODStrength;

float _XFurSelfTransmission;



float3 CalculateHighlights(float3 worldPos, float3 viewDir, float3 normal, float3 albedo, float occlusion, float smoothness, float3 anisoTan, float anisoOffsetA, float anisoOffsetB, float3 lightDir, float3 attenuatedLightColor) {
	float3 specFinal = 0;

	viewDir = normalize(viewDir);

	float3 h = normalize( lightDir + viewDir);
	float NdotL = saturate(dot( normal, lightDir));
	float HdotA = dot(normalize(normal + anisoTan), h);
	float aniso = max(0, sin(radians((HdotA + anisoOffsetA) * 180)));

	specFinal = pow(aniso, 128 * pow(smoothness, 5)) * 3 * pow( smoothness, 3 ) * lerp(_XFurSelfSpecularTint, albedo, 0.35);

	aniso = max(0, sin(radians((HdotA + anisoOffsetB) * 180)));

	specFinal += pow(aniso, 64 * pow(smoothness, 5)) * 1.5 * pow( smoothness, 3 ) * lerp(_XFurSelfSpecularTint, albedo, 0.75);

	specFinal *= attenuatedLightColor * NdotL* occlusion;

	specFinal = saturate(specFinal);

	return specFinal;

}




float3 CalculateTranslucency(float3 worldPos, float3 viewDir, float3 normal, float3 albedo, float occlusion, float3 lightDir, float3 attenuatedLightColor, float fakePoints = 0 ) {

	float3 finalLight = 0;

	viewDir = normalize(viewDir);

	//normal = mul(unity_WorldToObject, normal);

	//viewDir = mul(unity_ObjectToWorld, viewDir);

	float rim = 1.0 - saturate(dot( viewDir, normal));

	finalLight = saturate( pow( lerp( albedo, half4(0.75, 0.6, 0.4, 1), 0.8 ), 2.5 ) * pow(rim, 5 )* max(pow(occlusion, 2), 0.15) * saturate(dot( normal, -lightDir ) ) );

	//finalLight *=  1 - pow( rim, 6 );

	return finalLight * 3 * attenuatedLightColor * _XFurSelfTransmission;

}




void XFurLighting_half(float3 worldPos, float3 viewDir, float3 normal, float3 anisoTan, float anisoOffsetA, float anisoOffsetB, float3 albedo, float occlusion, float smoothness, out float3 finalColor ) {
#if SHADERGRAPH_PREVIEW

	finalColor = 0;

#else

#if SHADOWS_SCREEN
	half4 clipPos = TransformWorldToHClip(worldPos);
	half4 shadowCoord = ComputeScreenPos(clipPos);
#else
	half4 shadowCoord = TransformWorldToShadowCoord(worldPos);
#endif



	Light light = GetMainLight(shadowCoord);


	half3 attenuatedLightColor = light.color * light.distanceAttenuation * light.shadowAttenuation;
	finalColor = CalculateHighlights(worldPos, viewDir, normal, albedo, occlusion, smoothness, anisoTan, anisoOffsetA, anisoOffsetB, normalize(light.direction), attenuatedLightColor);
	finalColor += CalculateTranslucency(worldPos, viewDir, normal, albedo, occlusion, light.direction, attenuatedLightColor );

	int pixelLightCount = GetAdditionalLightsCount();


	for (int i = 0; i < pixelLightCount; i++) {
		light = GetAdditionalLight(i, worldPos);
		attenuatedLightColor = light.color * light.distanceAttenuation * light.shadowAttenuation;
		finalColor += CalculateHighlights(worldPos, viewDir, normal, albedo, occlusion, smoothness, anisoTan, anisoOffsetA, anisoOffsetB, normalize(light.direction), attenuatedLightColor);
		//finalColor += CalculateTranslucency(worldPos, viewDir, normal, albedo, occlusion, light.direction, attenuatedLightColor, 1 );
	}

	finalColor = saturate(finalColor);

#endif

}




float2 hash2D2D(float2 s)
{
	//magic numbers
	return frac(sin(fmod(float2(dot(s, float2(127.1, 311.7)), dot(s, float2(269.5, 183.3))), 3.14159)) * 43758.5453);
}

//stochastic sampling
float4 tex2DStochastic(sampler2D tex, float2 UV)
{
	//triangle vertices and blend weights
	//BW_vx[0...2].xyz = triangle verts
	//BW_vx[3].xy = blend weights (z is unused)
	float4x3 BW_vx;

	//uv transformed into triangular grid space with UV scaled by approximation of 2*sqrt(3)
	float2 skewUV = mul(float2x2 (1.0, 0.0, -0.57735027, 1.15470054), UV * 3.464);

	//vertex IDs and barycentric coords
	float2 vxID = float2 (floor(skewUV));
	float3 barry = float3 (frac(skewUV), 0);
	barry.z = 1.0 - barry.x - barry.y;

	BW_vx = ((barry.z > 0) ?
		float4x3(float3(vxID, 0), float3(vxID + float2(0, 1), 0), float3(vxID + float2(1, 0), 0), barry.zyx) :
		float4x3(float3(vxID + float2 (1, 1), 0), float3(vxID + float2 (1, 0), 0), float3(vxID + float2 (0, 1), 0), float3(-barry.z, 1.0 - barry.y, 1.0 - barry.x)));

	//calculate derivatives to avoid triangular grid artifacts
	float2 dx = ddx(UV);
	float2 dy = ddy(UV);

	//blend samples with calculated weights
	return mul(tex2D(tex, UV + hash2D2D(BW_vx[0].xy), dx, dy), BW_vx[3].x) +
		mul(tex2D(tex, UV + hash2D2D(BW_vx[1].xy), dx, dy), BW_vx[3].y) +
		mul(tex2D(tex, UV + hash2D2D(BW_vx[2].xy), dx, dy), BW_vx[3].z);
}


float3 tangentNormal(float3 normal, float4 tangent, float3 worldNormal, float3 worldPos) {

	float3 worldTangent = mul(unity_ObjectToWorld, tangent.xyz);
	float3 worldBinormal = cross(worldNormal, worldTangent) * tangent.w;

	float4 TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
	float4 TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
	float4 TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

	return float3(dot(TtoW0.xyz, normal), dot(TtoW1.xyz, normal), dot(TtoW2.xyz, normal));

}


void BasicShellVert_float(float3 vertexPos, float3 vertexNormal, float4 vertexTangent, float3 worldNormal, float4 texcoord1, float4 furData, float4 groomData, float4 physicsData, float4 vfxData, float4 profilesSplat, out float3 finalPos, out float3 finalDir, out float3 anisoTangent ) {
#if SHADERGRAPH_PREVIEW
	finalPos = vertexPos;
	finalDir = vertexPos;
	anisoTangent = anisoTangent = mul(unity_ObjectToWorld, finalDir);
#endif

	//o.xfurUVs = float4(v.texcoord.xy, texcoord1.xy);

#ifdef INSTANCING_ON
	uint fPass = UNITY_ACCESS_INSTANCED_PROP(XFurProps, _XFurInstancedCurrentPass);
	fPass = lerp(fPass, _XFurCurrentPass, _XFurForceNonInstanced);
#else
	uint fPass = _XFurCurrentPass;
#endif


	groomData.xyz = groomData.xyz * 2 - 1;

	

#if FURPROFILES_BLENDED

	half baseLength = _XFurSelfLength * (1 - saturate(length(profilesSplat)));
	half redLength = _XFurLength[0] * profilesSplat.r * (1 - saturate(length(profilesSplat.gba)));
	half greenLength = _XFurLength[1] * profilesSplat.g * (1 - saturate(length(profilesSplat.ba)));
	half blueLength = _XFurLength[2] * profilesSplat.b * (1 - saturate(length(profilesSplat.a)));
	half alphaLength = _XFurLength[3] * profilesSplat.a;

	half totalLength = (baseLength + redLength + greenLength + blueLength + alphaLength) * furData.g;
#else			
	half totalLength = _XFurSelfLength * furData.g;
#endif

	half3 wPos = mul(unity_ObjectToWorld, vertexPos);

	float3 windSim = float3(0, 0, 0);
	float windFreq = sin(8 * ((wPos.x % 1) + (wPos.z % 1)) + _Time.y * _XFurWindDirectionFreq.w);

	windSim = _XFurWindDirectionFreq.xyz * 2;

	windSim.x += lerp(dot(vertexNormal, float3(0, 1, 0)), 1, abs(_XFurWindDirectionFreq.x)) * lerp(windFreq, sign(_XFurWindDirectionFreq.x) * saturate(abs(windFreq)), abs(_XFurWindDirectionFreq.x));
	windSim.y += lerp(dot(vertexNormal, float3(1, 0, 0)), 1, abs(_XFurWindDirectionFreq.y)) * lerp(windFreq, sign(_XFurWindDirectionFreq.y) * saturate(abs(windFreq)), abs(_XFurWindDirectionFreq.y));
	windSim.z += lerp(dot(vertexNormal, float3(0, 0, 1)), 1, abs(_XFurWindDirectionFreq.z)) * lerp(windFreq, sign(_XFurWindDirectionFreq.z) * saturate(abs(windFreq)), abs(_XFurWindDirectionFreq.z));


	windSim *= _XFurSelfWindStrength * _XFurWindStrength * pow((totalLength / _XFurTotalPasses) * (1 + fPass), 1.5);


	half3 furDir = lerp(0, tangentNormal(groomData.xyz, vertexTangent, worldNormal, mul(unity_ObjectToWorld, vertexPos.xyz)), _XFurHasGroomData);

	float3 physDir = physicsData.xyz + float3(0, -0.35 * vfxData.b, 0);

	furDir = mul(unity_WorldToObject, furDir);

	physDir = mul(UNITY_MATRIX_I_M, physDir) * 10 * pow((totalLength / _XFurTotalPasses) * (1 + fPass), 2);

	windSim *= 1 - saturate(dot(normalize(furDir + physDir), windSim));

	furDir += mul(unity_WorldToObject, windSim.xyz) * _XFurWindStrength;
	physDir += furDir;

	physDir *= lerp(1, 0.5, vfxData.g) * lerp(1, groomData.w, _XFurHasGroomData);

	finalDir = vertexPos;

	vertexPos += 0.5 * normalize(vertexNormal + physDir) * (totalLength / _XFurTotalPasses) * (1 + fPass);

	finalDir = normalize(vertexPos - finalDir);

	anisoTangent = cross(mul(unity_WorldToObject, float3(0, 1, 0)), finalDir);

	//finalDir = normalize(vertexPos);

	//anisoTangent = mul(unity_ObjectToWorld, finalDir);

	finalPos = vertexPos;
}






void ShellSurfacePass_float(float4 furColor, float4 furData, float2 furUV, float4 colorVariation, float4 vfxMap, float3 normal, float3 viewDir, float4 profilesSplat, out float3 albedo, out float metallic, out float smoothness, out float occlusion, out float alpha )
{

#ifdef INSTANCING_ON
	uint fPass = UNITY_ACCESS_INSTANCED_PROP(XFurProps, _XFurInstancedCurrentPass) + 1;
	fPass = lerp(fPass, _XFurCurrentPass, _XFurForceNonInstanced) + 1;
#else
	uint fPass = _XFurCurrentPass + 1;
#endif



#if FEATURESET_MOBILE

	half4 mixedColors = half4(0, 0, 0, 0);

#else


	half4 rColor = _XFurSelfColorA * colorVariation.r;
	half4 gColor = _XFurSelfColorB * saturate(colorVariation.g * (1 - colorVariation.r));
	half4 bColor = _XFurSelfColorC * saturate(colorVariation.b * (1 - colorVariation.r - colorVariation.g));
	half4 aColor = _XFurSelfColorD * saturate(colorVariation.a * (1 - colorVariation.r - colorVariation.g - colorVariation.b));

	half4 mixedColors = rColor + gColor + bColor + aColor;

#endif

	float2 curl = float2(sin((fPass / _XFurTotalPasses) * 16 * _XFurSelfCurlAmountX) * abs(furUV.x) * (_XFurSelfCurlSizeX / (_XFurUVTiling)), sin((fPass / _XFurTotalPasses) * 16 * _XFurSelfCurlAmountY) * abs(furUV.y) * (_XFurSelfCurlSizeY / (_XFurUVTiling)));

	half4 furStrands = tex2DStochastic(_XFurSelfStrandsPattern, _XFurUVTiling * (furUV + curl));

	furColor *= (1 - saturate(colorVariation.r + colorVariation.g + colorVariation.b + colorVariation.a)) + furColor * mixedColors;


	half underOver = saturate(ceil(furStrands.g * 2));
	half furClip = lerp(furStrands.r, furStrands.g, underOver);



#if FURPROFILES_BLENDED

	half baseThickness = _XFurSelfThickness * (1 - saturate(length(profilesSplat)));
	half redThickness = _XFurThickness[0] * profilesSplat.r * (1 - saturate(length(profilesSplat.gba)));
	half greenThickness = _XFurThickness[1] * profilesSplat.g * (1 - saturate(length(profilesSplat.ba)));
	half blueThickness = _XFurThickness[2] * profilesSplat.b * (1 - saturate(length(profilesSplat.a)));
	half alphaThickness = _XFurThickness[3] * profilesSplat.a;

	half totalThickness = (baseThickness + redThickness + greenThickness + blueThickness + alphaThickness) * furData.a * (1 + 0.6 * vfxMap.g * (1 - vfxMap.r));

	half baseThicknessC = _XFurSelfThicknessCurve * (1 - saturate(length(profilesSplat)));
	half redThicknessC = _XFurThicknessCurve[0] * profilesSplat.r * (1 - saturate(length(profilesSplat.gba)));
	half greenThicknessC = _XFurThicknessCurve[1] * profilesSplat.g * (1 - saturate(length(profilesSplat.ba)));
	half blueThicknessC = _XFurThicknessCurve[2] * profilesSplat.b * (1 - saturate(length(profilesSplat.a)));
	half alphaThicknessC = _XFurThicknessCurve[3] * profilesSplat.a;

	half thicknessCurve = (baseThicknessC + redThicknessC + greenThicknessC + blueThicknessC + alphaThicknessC);

	thicknessCurve = pow(furClip, lerp(8, 2, totalThickness) * pow(fPass / _XFurTotalPasses, 8 * thicknessCurve));
#else
	half totalThickness = _XFurSelfThickness * furData.a * (1 + 0.25 * vfxMap.g * (1 - vfxMap.r));

	half thicknessCurve = pow(furClip, lerp(8, 2, totalThickness) * pow(fPass / _XFurTotalPasses, 8 * _XFurSelfThicknessCurve));
#endif

	alpha = furData.r * thicknessCurve - lerp(0.05, 0.025, underOver) * _XFurSelfLength * (fPass / _XFurTotalPasses);

	int mod = ceil(_XFurTotalPasses / _XFurLODStrength);

	float aValue = fPass % mod < 0.1 ? 1 : 0;

	//alpha *= ceil( (fPass % 1) - 0.005 );

	aValue = lerp(aValue, 1, pow(1.0 - saturate(dot(normalize(viewDir), normal)), _XFurLODArea));

	//alpha = lerp(aValue, 1, pow(1.0 - saturate(dot(normalize(viewDir), normal)), 12));


	if (aValue < 0.1) {
		clip(-1);
		metallic = albedo = smoothness = occlusion = 0;
	}
	else {

		clip(alpha - 0.005);
		half4 occlusionColor = half4(0, 0, 0, 0);

#if FURPROFILES_BLENDED

		half furIndex = profilesSplat.g + (2 * profilesSplat.b - profilesSplat.g) + (3 * profilesSplat.a - 2 * profilesSplat.b - profilesSplat.g);

		half baseOcclusion = _XFurSelfOcclusion * (1 - saturate(length(profilesSplat)));
		half redOcclusion = _XFurOcclusion[0] * profilesSplat.r * (1 - saturate(length(profilesSplat.gba)));
		half greenOcclusion = _XFurOcclusion[1] * profilesSplat.g * (1 - saturate(length(profilesSplat.ba)));
		half blueOcclusion = _XFurOcclusion[2] * profilesSplat.b * (1 - saturate(length(profilesSplat.a)));
		half alphaOcclusion = _XFurOcclusion[3] * profilesSplat.a;

		half totalOcclusion = (baseOcclusion + redOcclusion + greenOcclusion + blueOcclusion + alphaOcclusion) * furData.b;

		half baseOcclusionC = _XFurSelfOcclusionCurve * (1 - saturate(length(profilesSplat)));
		half redOcclusionC = _XFurOcclusionCurve[0] * profilesSplat.r * (1 - saturate(length(profilesSplat.gba)));
		half greenOcclusionC = _XFurOcclusionCurve[1] * profilesSplat.g * (1 - saturate(length(profilesSplat.ba)));
		half blueOcclusionC = _XFurOcclusionCurve[2] * profilesSplat.b * (1 - saturate(length(profilesSplat.a)));
		half alphaOcclusionC = _XFurOcclusionCurve[3] * profilesSplat.a;

		half occlusionCurve = (baseOcclusionC + redOcclusionC + greenOcclusionC + blueOcclusionC + alphaOcclusionC);


		half furOcclusion = lerp(1, (pow((fPass / _XFurTotalPasses), 12 * occlusionCurve)), totalOcclusion * furData.b);
		occlusionColor = lerp(_XFurSelfShadowsTint, _XFurShadowsTint[furIndex], length(profilesSplat));
#else
		half furOcclusion = lerp(1, (pow((fPass / _XFurTotalPasses), 12 * _XFurSelfOcclusionCurve)), _XFurSelfOcclusion * furData.b);
		occlusionColor = _XFurSelfShadowsTint;
#endif


		occlusion = furOcclusion;


		half4 fColor = lerp(occlusionColor, furColor * lerp(1.0 - _XFurSelfUnderColorMod, 1.0 + _XFurSelfOverColorMod, underOver), furOcclusion);

		half4 blood = lerp(_XFurVFX1Color * 0.75 * fColor, saturate(_XFurVFX1Color * 1.5 * fColor), vfxMap.r) * saturate(occlusion * 2) * vfxMap.r * saturate(lerp(1, (pow((fPass / _XFurTotalPasses), 12 * _XFurVFX1Penetration)), 1) * 2);

		half4 snow = _XFurVFX2Color * saturate(lerp(1, (pow((fPass / _XFurTotalPasses), 12 * _XFurVFX2Penetration)), 1) * 2) * vfxMap.g * (1 - vfxMap.r);

		half4 fxColor = blood + snow;

		metallic = max(blood * 0.25, vfxMap.b * 0.5);



		smoothness = saturate(_XFurSelfSmoothness + saturate(blood * _XFurVFX1Smoothness + vfxMap.b * _XFurVFX3Smoothness));

		smoothness *= lerp(occlusion * saturate( pow( furClip * 4, 2 )), 1, _XFurURPRenderingMode);

		fColor *= lerp(1, 0.55, vfxMap.b * saturate(lerp(1, (pow((fPass / _XFurTotalPasses), 2 * _XFurVFX3Penetration)), 1) * 4));


		albedo = lerp(fColor, fxColor, saturate(vfxMap.r + vfxMap.g + vfxMap.a));




		half rim = 1 - saturate(dot(normalize(viewDir), normal));
		albedo += lerp(_XFurSelfRimColor * saturate(lerp(fColor * 2, 1, saturate(_XFurSelfRimBoost - 1) * 0.65)), saturate(albedo * 2), 0.25) * _XFurSelfRimBoost * pow(rim, _XFurSelfRimPower);
		albedo = saturate(albedo);

	}
}
#endif
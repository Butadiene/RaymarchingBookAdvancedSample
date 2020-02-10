Shader "Butadiene/raymarchReflectionSample"
{
	Properties
	{
		
	}
	SubShader
	{
		Tags { "RenderType"="TransparentCutout" "Queue" = "AlphaTest" }
		LOD 100
		Cull Front
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			
			#include "UnityCG.cginc"


			float2 rot(float2 p,float r) {
				float2x2 m = float2x2(cos(r),sin(r),-sin(r),cos(r));
				return mul(m,p);
			}

			float cube(float3 p,float3 s) {
				float3 q = abs(p);
				float3 m = max(s - q,0.0);
				return length(max(q - s,0.0)) - min(min(m.x,m.y),m.z);
			}

			float smin(float a, float b, float k)
			{
				float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
				return lerp(b, a, h) - k * h * (1.0 - h);
			}

			float rand(float2 co) {
				return frac(sin(dot(co.xy, float2(12.9898,78.233))) * 43758.5453);
			}


			float noise(float2 st) {
				float2 i = floor(st);
				float2 f = frac(st);
		
				float a = rand(i);
				float b = rand(i + float2(1.0, 0.0));
				float c = rand(i + float2(0.0, 1.0));
				float d = rand(i + float2(1.0, 1.0));


				float2 u = f * f * (3.0 - 2.0 * f);

				return lerp(a, b, u.x) +(c - a) * u.y * (1.0 - u.x) +(d - b) * u.x * u.y;
			}


			float dist(float3 p) {
				float3 pcube = p;

				float rk = rand(sign(p.xz)+0.1);
				float rk2 = rand(sign(p.xz) + 0.2);

				p.xz = float2(0.2,0.2)-abs(p.xz);

				p.y += 0.1*sin(0.5 * _Time.y * (rk2 + 0.1));

				float d2 = length(p) - 0.08-0.08*rk*sin(_Time.y*(rk+0.1));

				pcube.y = -abs(pcube.y);

				float d1 = cube(pcube+float3(0,0.2,0),float3(0.5,0.04,0.5));
				
				return  smin(d1, d2,0.1);
			}

		

			float3 gn(float3 p) {

				const float h = 0.001;
				const float2 k = float2(1, -1);
				return normalize(k.xyy * dist(p + k.xyy * h) +
					k.yyx * dist(p + k.yyx * h) +
					k.yxy * dist(p + k.yxy * h) +
					k.xxx * dist(p + k.xxx * h));

			}
			//Copyright 2019 Jasper Flick
			//Released under the MIT license
			//https://opensource.org/licenses/mit-license.php
			////////////////////////////////////////////////////////////////////////////
			float3 BoxProjection(
				float3 direction, float3 position,
				float4 cubemapPosition, float3 boxMin, float3 boxMax
			) {
				#if UNITY_SPECCUBE_BOX_PROJECTION
				if (cubemapPosition.w > 0) {
					float3 factors =
						((direction > 0 ? boxMax : boxMin) - position) / direction;
					float scalar = min(min(factors.x, factors.y), factors.z);
					direction = direction * scalar + (position - cubemapPosition);
				}
				#endif
				return direction;
			}
			////////////////////////////////////////////////////////////////////////


			float3 light(float3 p,float3 view) {
				float3 normal = gn(p);
				float nv = noise(100.0*(p.xz + p.yz + p.xy));
				nv = nv * 2.0 - 1.0;
				normal += 0.3 * nv;
				float3 ld = -normalize(p);
				float NdotL = max(dot(ld,normal),0.0);
				float3 R = normalize(-ld + NdotL * normal *2.0);
				float spec = pow(max(dot(-view,R),0.0),11.0)*saturate(sign(NdotL));
				float3 col = float3(1,1,1)*(NdotL + spec);

				float3 reflectionDir = reflect(view, normal);
				reflectionDir = BoxProjection(reflectionDir, p, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
				float4  refcol= UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflectionDir);
				refcol.xyz = DecodeHDR(refcol, unity_SpecCube0_HDR);
				


				return col*0.01+refcol ;
			}



			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float3 pos: TEXCOORD1;
				float4 vertex : SV_POSITION;
			};

	
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.pos = v.vertex;
				o.uv = v.uv;

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float3 ro = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1)).xyz;
				float3 rd = normalize(i.pos.xyz - mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1)).xyz);

				float d = 0;
				float t = 0.001;
				float far = 10.;
				float near = 0.001;
				[unroll]
				for (int i = 0; i < 60; ++i) { 
					d = dist(ro + rd * t);
					t += d;
					if (t > far||near>d) break;
				}
				if (t > far) {
					discard;
				}

				float tk = 0.0;
				float dk = 0.0;

				float3 bcol = float3(0.1, 0.4, 0.8);
				float3 col = light(ro + rd * t, rd);
				
				col = clamp(col, 0.0, 1.0);

				return float4(col,1.0);
			}
			ENDCG
		}
	}
}

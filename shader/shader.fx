
float4x4	m_mtWld;		// World Matrix
float4x4	m_mtViw;		// View Matrix
float4x4	m_mtPrj;		// Projection Matrix
float3x3	m_mtRot;		// Rotation Matrix
float3		m_vcCam;		// Camera Position
float		m_fShrp;		// Sharpness (스펙큐라 강도)
float		m_fRef;		// Sharpness (리플렉션 강도)
float4		m_Ambient;		// Constant Ambient Color
float3 		m_LgtDir;		// Lighting Direction
float4 		m_LgtDiffuse = {1.f, 1.f, 1.f, 1.f };		// Diffuse Lighting 
int			m_bTexture;		// Use Diffuse Texture
int			m_bSpecTexture; // Use Specular mask texture

//float4		m_TextureFactor;

texture m_TxDif;
texture m_TxSpecMask;
texture m_SkyboxTexture; 

samplerCUBE SkyboxSampler = 
sampler_state 
{ 
   texture = <m_SkyboxTexture>; 
   MinFilter = LINEAR;
   MagFilter = LINEAR;
   MipFilter = NONE;
   
   AddressU = Clamp;
   AddressV = Clamp;
};

sampler SampDif =
sampler_state
{
    Texture = <m_TxDif>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;

    AddressU = WRAP;
    AddressV = WRAP;
};

sampler SampSpecMask = 
sampler_state
{
	Texture = <m_TxSpecMask>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
	
	AddressU = WRAP;
	AddressV = WRAP;
};

struct SVsOut
{
	float4 Pos	: POSITION0;
	float2 Tex	: TEXCOORD0;


	float3 Nor	: TEXCOORD1;	// Normal Vector
	float3 Eye	: TEXCOORD2;	// Eye Direction Vector
};

SVsOut VtxPrc(	float3 Pos : POSITION0,	// Local Position
				float3 Nor : NORMAL0,	// Normal Vector
				float2 Tex : TEXCOORD0	// Texture Coordinate
)
{
	SVsOut Out = (SVsOut)0;							// Initialize to Zero

	float4 P = float4(Pos, 1);						// Position
	P = mul(P, m_mtWld);

	float3 N = mul(Nor, (float3x3)m_mtRot);			// Rotation Normal Vector
	float3 E = (m_vcCam - P);						// Eye Vector = Camera Position - Transform World Vertex Position

	P = mul(P, m_mtViw);
	P = mul(P, m_mtPrj);

	Out.Pos = P;									// Output Position
	Out.Tex = Tex;									// Diffuse Map Coordinate
	Out.Nor = N;
	Out.Eye = E;

	return Out;
}

float4 PxlPrc(SVsOut In) : COLOR0
{
	int i=0;
	float4 Out = 0;
 	float3 N = normalize(In.Nor);
 	float3 E = normalize(In.Eye);
 	float3 L; 
 	float3 H; 
 	float3 R;
	
	float4	Lam = 0;
	float4	Spc = 0;
	float4	Rfc = 0;
	float4	Dif = 0;
		
 	L = normalize(-m_LgtDir); 
 	H = normalize(L + E); 
 	R = reflect(L, N);    
	Lam = (0.5 * dot(N, L) + 0.5) * m_LgtDiffuse; // Lambert reflect

	Spc = pow(max(0.0001, dot(N, H)), m_fShrp);
	
	Out = m_Ambient + saturate(Lam); 
 	if(1 == m_bTexture)
  		Out *= tex2D( SampDif, In.Tex );
 	if(1 == m_bSpecTexture)				
 		Spc *= tex2D( SampSpecMask, In.Tex );
 	
 	Rfc = ( texCUBE( SkyboxSampler, R ) * m_fRef );
	
	//Out += lerp( Spc, Rfc, m_fRef );
	Out += Spc * Rfc;
  	
	return saturate(Out);}

float4 PxlPrc3(SVsOut In) : COLOR0
{
	int i=0;
	float4 Out = 0;
 	float3 N = normalize(In.Nor);
 	float3 E = normalize(In.Eye);
 	float3 L; 
 	float3 H; 
 	float3 R;
	
	float4	Lam = 0;
	float4	Spc = 0;
	float4	Rfc = 0;
		
 	L = normalize(-m_LgtDir); 
 	H = normalize(L + E); 
 	R = reflect(L, N);    
	Lam = (0.5 * dot(N, L) + 0.5) * m_LgtDiffuse; // Lambert reflect

	Spc = pow(max(0.0001, dot(N, H)), m_fShrp);
	
	Out = m_Ambient + saturate(Lam); 
 	if(1 == m_bTexture)
  		Out *= tex2D( SampDif, In.Tex );
 	if(1 == m_bSpecTexture)				
 		Spc *= tex2D( SampSpecMask, In.Tex );
 	
  	Out += Spc;
 
	return saturate(Out);}


float4 PxlPrc2(SVsOut In) : COLOR0
{
	float3 L;
	float3 N = normalize(In.Nor);
	float4	Rfc = 0;
	
	L = normalize(-m_LgtDir); 
	float3 R = reflect(-L, N);    

	Rfc = (texCUBE( SkyboxSampler, R ) * m_fRef );

 		
	return Rfc;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
technique Tech0
{
	pass P0
	{
		VertexShader = compile vs_1_1 VtxPrc();
		PixelShader = compile ps_2_0 PxlPrc();
 	}
}

technique Tech1
{
	pass P0
	{
		VertexShader = compile vs_1_1 VtxPrc();
		PixelShader = compile ps_2_0 PxlPrc3();
 	}
   	pass P1
    {
       	VertexShader = compile vs_1_1 VtxPrc();
		PixelShader = compile ps_2_0 PxlPrc2();
    }
}

technique Tech2
{
	pass P0
	{
		VertexShader = compile vs_1_1 VtxPrc();
		PixelShader = compile ps_2_0 PxlPrc3();
 	}
}




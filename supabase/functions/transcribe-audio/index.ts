import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai@0.16.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { audioUrl } = await req.json()
    if (!audioUrl) {
      throw new Error('Missing audioUrl')
    }

    // 1. Download the Audio File
    const audioResponse = await fetch(audioUrl)
    if (!audioResponse.ok) throw new Error(`Failed to download audio: ${audioResponse.statusText}`)

    const arrayBuffer = await audioResponse.arrayBuffer()
    const base64Audio = btoa(String.fromCharCode(...new Uint8Array(arrayBuffer)))

    // 2. Initialize Gemini (using the newer SDK version)
    const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY') || '')
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" })

    // 3. Generate Content (Transcribe)
    const result = await model.generateContent([
      {
        inlineData: {
          mimeType: "audio/mp4",
          data: base64Audio
        }
      },
      { text: "Transcribe this audio exactly as spoken. Detect the language and return the language code/name at the start like [Language: Tamil] then the text." },
    ])

    const responseText = result.response.text()

    // Simple parsing
    let language = "Unknown"
    let transcript = responseText

    const langMatch = responseText.match(/^\[Language: (.+?)\]/)
    if (langMatch) {
      language = langMatch[1]
      transcript = responseText.replace(langMatch[0], "").trim()
    }

    return new Response(
      JSON.stringify({
        transcript,
        language,
        originalResponse: responseText
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})

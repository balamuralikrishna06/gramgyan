import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
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
        const { report_id, original_text, type, translated_text } = await req.json()

        // Initialize Clients
        const supabase = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )
        const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY') || '')
        const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" })
        const embeddingModel = genAI.getGenerativeModel({ model: "embedding-001" })

        // 1. Translate to English (if not provided)
        let englishText = translated_text;

        if (!englishText) {
            const translationPrompt = `Translate the following agricultural text to clear English. Return ONLY the English translation.\n\n${original_text}`
            const translationResult = await model.generateContent(translationPrompt)
            englishText = translationResult.response.text().trim()
        }

        // 2. Generate Embedding
        const embeddingResult = await embeddingModel.embedContent(englishText)
        const embedding = embeddingResult.embedding.values

        // 3. Update Report with English Text & Embedding
        await supabase
            .from('knowledge_posts')
            .update({
                english_text: englishText,
                embedding: embedding,
                status: 'open'
            })
            .eq('id', report_id)

        // 4. If Question: Search or Generate Solution
        if (type === 'question') {
            // Semantic Search
            const { data: similarReports, error: searchError } = await supabase.rpc('match_reports', {
                query_embedding: embedding,
                match_threshold: 0.8, // 80% similarity
                match_count: 1
            })

            if (similarReports && similarReports.length > 0) {
                // Found existing solution!
                const match = similarReports[0]
                await supabase.from('solutions').insert({
                    report_id: report_id,
                    user_id: null, // System/AI
                    solution_text: `(Use Validated Answer) ${match.solution_text}`,
                    ai_generated: true
                })
            } else {
                // No match? Generate AI Solution
                const solutionPrompt = `You are an expert agriculturalist. A farmer has asked: "${englishText}". Provide a short, practical, and helpful solution in simple language.`
                const solutionResult = await model.generateContent(solutionPrompt)
                const solutionText = solutionResult.response.text().trim()

                await supabase.from('solutions').insert({
                    report_id: report_id,
                    user_id: null,
                    solution_text: solutionText,
                    ai_generated: true
                })
            }
        }
        // 5. If Knowledge: Extract Structure (Optional enhancement)
        else if (type === 'knowledge') {
            // Could extract crop/disease tags here and update report
        }

        return new Response(
            JSON.stringify({ success: true, englishText }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )

    } catch (error) {
        return new Response(
            JSON.stringify({ error: error.message }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
        )
    }
})

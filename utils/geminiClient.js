export const askGemini = async (prompt, context = '') => {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY is not configured in environment variables');
  }

  // Allow switching models via environment variable, e.g. GEMINI_MODEL=gemini-2.5-flash
  const model = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
  const url = `https://generativelanguage.googleapis.com/v1/models/${model}:generateContent?key=${apiKey}`;

  const systemContext = `You are an agricultural assistant specialized in Sri Lankan paddy farming. Answer in complete, coherent English sentences. Do not use markdown formatting. Do not provide bullet points or numbered lists unless the user asks for them explicitly. Finish with a complete concluding sentence. Provide the full answer in a single response.`;
  const fullPrompt = context 
    ? `${systemContext}\n\nFarm Context: ${context}\n\nFarmer's Question: ${prompt}`
    : `${systemContext}\n\nFarmer's Question: ${prompt}`;

  const makeUrl = (name) => `https://generativelanguage.googleapis.com/v1/models/${name}:generateContent?key=${apiKey}`;

  const bodyBase = {
    contents: [
      {
        parts: [
          {
            text: fullPrompt,
          },
        ],
      },
    ],
    generationConfig: {
      temperature: 0.0,
      topP: 0.95,
      topK: 40,
      maxOutputTokens: 1400,
    },
  };

  const extractResponse = (data) => {
    if (!data) {
      return { text: '', finishReason: undefined };
    }

    const candidates = data.candidates;
    if (Array.isArray(candidates) && candidates.length > 0) {
      const text = candidates
        .map((candidate) => {
          const parts = candidate?.content?.parts;
          if (Array.isArray(parts) && parts.length > 0) {
            return parts.map((part) => part?.text ?? '').join('');
          }
          return candidate?.output?.text ?? '';
        })
        .join('\n');
      return { text, finishReason: candidates[0]?.finishReason ?? data.finishReason };
    }

    const outputs = data.output;
    if (Array.isArray(outputs) && outputs.length > 0) {
      const text = outputs
        .map((entry) => {
          if (Array.isArray(entry?.content)) {
            return entry.content.map((contentItem) => contentItem?.text ?? '').join('');
          }
          return entry?.text ?? '';
        })
        .join('\n');
      return { text, finishReason: data.finishReason };
    }

    return { text: data.text ?? '', finishReason: data.finishReason };
  };

  const requestModel = async (modelName) => {
    const urlModel = makeUrl(modelName);
    console.log('🤖 Calling Gemini API with model:', modelName);
    console.log('URL:', urlModel);
    console.log('Request body:', JSON.stringify(bodyBase, null, 2));

    const response = await fetch(urlModel, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(bodyBase),
    });

    console.log('Response Status:', response.status);
    if (!response.ok) {
      const responseText = await response.text();
      let errorMessage = `HTTP ${response.status}`;

      if (responseText) {
        try {
          const errorData = JSON.parse(responseText);
          errorMessage = errorData.error?.message || errorData.message || responseText;
        } catch (e) {
          errorMessage = responseText;
        }
      }

      throw new Error(`Gemini API Error: ${errorMessage}`);
    }

    const data = await response.json();
    console.log('✅ Gemini raw response:', JSON.stringify(data, null, 2));

    const { text, finishReason } = extractResponse(data);
    console.log('✅ Extracted text length:', text.length);
    console.log('✅ Extracted text preview:', text.substring(0, 400));
    console.log('✅ Finish reason:', finishReason);

    if (text && text.length > 0) {
      return { text, finishReason };
    }

    throw new Error('Invalid response format from Gemini API - no content returned');
  };

  try {
    const firstResult = await requestModel(model);
    if (
      firstResult.finishReason === 'MAX_TOKENS' &&
      model === 'gemini-2.5-flash'
    ) {
      const fallbackModel = process.env.GEMINI_FALLBACK_MODEL || 'gemini-2.5-flash-lite';
      console.warn(`Gemini model ${model} truncated; retrying with ${fallbackModel}`);
      const fallbackResult = await requestModel(fallbackModel);
      return fallbackResult.text;
    }

    return firstResult.text;
  } catch (error) {
    console.error('❌ Gemini API Error:', error.message);

    // Check if it's a quota exceeded error
    if (error.message.includes('RESOURCE_EXHAUSTED') || error.message.includes('quota')) {
      console.warn('⚠️ Gemini API quota exceeded, falling back to simple responses');
      throw new Error('API_QUOTA_EXCEEDED');
    }

    throw new Error(`Gemini API Error: ${error.message}`);
  }
};
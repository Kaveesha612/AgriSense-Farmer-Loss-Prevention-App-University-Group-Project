export const askGemini = async (prompt, context = '') => {
  const apiKey = process.env.GEMINI_API_KEY;
  
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY is not configured in environment variables');
  }

  const url = `https://generativelanguage.googleapis.com/v1p1beta1/models/gemini-1.5-flash:generateText?key=${apiKey}`;

  const systemContext = `You are an agricultural assistant specialized in Sri Lankan paddy farming. Provide concise, practical advice.`;
  const fullPrompt = context 
    ? `${systemContext}\n\nFarm Context: ${context}\n\nFarmer's Question: ${prompt}`
    : `${systemContext}\n\nFarmer's Question: ${prompt}`;

  const body = {
    prompt: {
      text: fullPrompt,
    },
    temperature: 0.7,
    topK: 40,
    topP: 0.95,
    maxOutputTokens: 1024,
  };

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify(body),
    });

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
    
    // Extract text from response for multiple possible Gemini response shapes
    const candidate = data.candidates?.[0];
    const text = candidate?.output?.text
      || candidate?.content?.parts?.[0]?.text
      || data.output?.[0]?.content?.[0]?.text;

    if (text && text.toString().trim().length > 0) {
      return text.toString().trim();
    }

    throw new Error('Invalid response format from Gemini API - no content returned');
  } catch (error) {
    throw new Error(`Gemini API Error: ${error.message}`);
  }
};
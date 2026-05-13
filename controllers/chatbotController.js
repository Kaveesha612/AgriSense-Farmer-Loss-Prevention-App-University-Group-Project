import asyncHandler from 'express-async-handler';
import { askGemini } from '../utils/geminiClient.js';
import ChatMessage from '../models/ChatMessage.js';

// @desc    Send message to AI assistant
// @route   POST /api/chatbot
// @access  Private
// Simple keyword-based response system for common farming questions
const getSimpleResponse = (message) => {
  const lowerMessage = message.toLowerCase();
  
  if (lowerMessage.includes('rice') && lowerMessage.includes('fertilizer')) {
    return "For rice farming, use a balanced NPK fertilizer (like 14-14-14) at 50-100 kg per hectare during planting. Apply urea in splits for better absorption. Always test your soil first.";
  }
  
  if (lowerMessage.includes('paddy') || lowerMessage.includes('rice')) {
    return "Rice (paddy) requires flooded fields and warm temperatures (25-35°C). Plant during monsoon season, ensure proper water management, and watch for pests like stem borers.";
  }
  
  if (lowerMessage.includes('fertilizer')) {
    return "Choose fertilizers based on soil tests. Organic options include compost and manure. Chemical fertilizers provide quick nutrients but use sparingly to avoid soil degradation.";
  }
  
  if (lowerMessage.includes('water') || lowerMessage.includes('irrigation')) {
    return "Rice needs 1-2 meters of water throughout the growing season. Use efficient irrigation methods like drip systems to conserve water and reduce costs.";
  }
  
  if (lowerMessage.includes('pest') || lowerMessage.includes('disease')) {
    return "Common rice pests include brown plant hoppers and leaf folders. Use integrated pest management: biological control, resistant varieties, and minimal chemical pesticides.";
  }
  
  if (lowerMessage.includes('weather') || lowerMessage.includes('rain')) {
    return "Monitor weather forecasts for optimal planting and harvesting times. Rice thrives in humid, rainy conditions but can suffer from drought or excessive flooding.";
  }
  
  // Default response
  return "I'm here to help with your farming questions! Ask me about rice cultivation, fertilizers, irrigation, pests, or weather-related farming advice.";
};

export const chatWithAssistant = asyncHandler(async (req, res) => {
  const { message } = req.body;
  if (!message) {
    res.status(400);
    throw new Error('Message is required');
  }

  const user = req.user;
  let context = '';
  if (user.farmLocations && user.farmLocations.length > 0) {
    const farm = user.farmLocations[0];
    context = `Farmer has a farm named "${farm.name}" at coordinates (${farm.coordinates.lat}, ${farm.coordinates.lng}). Crop stage: ${farm.cropStage || 'unknown'}.`;
  }

  let aiResponse;
  try {
    aiResponse = await askGemini(message, context);
  } catch (error) {
    console.error('Gemini API Error:', error);
    
    // Check if it's a quota exceeded error
    if (error.message.includes('API_QUOTA_EXCEEDED')) {
      aiResponse = "I'm currently experiencing high demand and my AI capabilities are temporarily limited. However, I can still help with your farming questions using my knowledge base. " + getSimpleResponse(message);
    } else {
      // Fallback to simple keyword-based response
      aiResponse = getSimpleResponse(message);
    }
  }

  await ChatMessage.create({
    userId: user._id,
    message,
    response: aiResponse,
  });
  res.json({ response: aiResponse });
});

// @desc    Get chat history for current user
// @route   GET /api/chatbot/history
// @access  Private
export const getChatHistory = asyncHandler(async (req, res) => {
  const history = await ChatMessage.find({ userId: req.user._id })
    .sort({ timestamp: -1 })
    .limit(50);
  res.json(history);
});
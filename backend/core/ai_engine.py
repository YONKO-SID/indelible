from google import genai
from google.genai import types
import os
import json
from dotenv import load_dotenv

# Loading environment variables from .env file
load_dotenv()

class IndelibleAIEngine:
    def __init__(self):
        # google-genai automatically picks up GEMINI_API_KEY from environment
        self.client = genai.Client()
        
    def detect_piracy(self, file_path: str) -> dict:
        """
        Uses Gemini 2.5 Flash multimodal capabilities to perform zero-shot classification
        on a video frame to determine if it contains pirated sports content.
        """
        try:
            # Upload the file to Gemini's File API for multimodal processing
            uploaded_file = self.client.files.upload(file=file_path)
            
            prompt = """
            You are an expert copyright and forensic analyst for a major sports broadcasting network.
            Analyze this image (which is a frame extracted from a video stream).
            Does this image appear to be recorded or pirated sports content? 
            Look for indicators like: TV channel logos, scoreboard overlays, professional stadium lighting, 
            or camera angles typical of professional broadcasts, especially if the footage looks like it was 
            recorded off a screen or re-streamed illegally.
            
            Respond strictly in JSON format with the following keys:
            - "is_pirated" (boolean)
            - "confidence_score" (float between 0.0 and 1.0)
            - "reasoning" (string, max 2 sentences)
            """
            
            response = self.client.models.generate_content(
                model='gemini-2.5-flash',
                contents=[uploaded_file, prompt],
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                )
            )
            
            # Clean up the file from Google's servers
            self.client.files.delete(name=uploaded_file.name)
            
            try:
                result = json.loads(response.text)
                return result
            except json.JSONDecodeError:
                return {
                    "is_pirated": False, 
                    "confidence_score": 0.0, 
                    "reasoning": "Failed to parse AI response."
                }
                
        except Exception as e:
            return {
                "is_pirated": False,
                "confidence_score": 0.0,
                "error": str(e)
            }

    def generate_takedown_notice(self, creator_id: str, platform_url: str, proof_hash: str) -> str:
        """
        Generates a legally-sound DMCA Cease and Desist notice.
        """
        prompt = f"""
        Generate a highly professional, legally-sound DMCA Cease and Desist notice.
        
        Details to include:
        - The copyright owner is: {creator_id}
        - The infringing content is located at: {platform_url}
        - Forensic Evidence Hash proving ownership: {proof_hash}
        - The technology used to prove ownership is: INDELIBLE DWT-DCT + QIM invisible watermarking.
        
        Keep it concise, threatening but professional, and ready to be emailed to a platform's legal team.
        Do not include placeholders like [Your Name] if they aren't provided, just use the Creator ID.
        """
        
        try:
            response = self.client.models.generate_content(
                model='gemini-2.5-flash',
                contents=prompt
            )
            return response.text
        except Exception as e:
            return f"Failed to generate legal notice: {str(e)}"

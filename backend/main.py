import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import openai
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

load_dotenv()

app = FastAPI(title="GreenWheelStation Chatbot API")

openai.api_key = os.getenv("OPENAI_API_KEY")

cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

class ChatRequest(BaseModel):
    message: str

class ChatResponse(BaseModel):
    reply: str

@app.post("/chat", response_model=ChatResponse)
async def chat_endpoint(chat_request: ChatRequest):
    message = chat_request.message.strip()
    if not message:
        raise HTTPException(status_code=400, detail="Message is required")
    
    try:
        # Use ChatCompletion with the GPT-3.5-turbo model and include a system message for context
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You are an assistant for users of the GreenWheelStation mobile application, "
                        "which helps users locate the nearest EV charging stations on a map. Your primary role "
                        "is to provide helpful, concise information about navigating the map, understanding different "
                        "types of charging stations (Level 1, 2, DC Fast Charging), vehicle compatibility, technical "
                        "details about EV batteries and charging times, troubleshooting common charging issues, and "
                        "information on payment methods and charging networks."
                    )
                },
                {"role": "user", "content": message}
            ],
            max_tokens=150,
        )
        reply = response.choices[0].message.content.strip()
        
        timestamp = datetime.utcnow()
        
        db.collection("assistant_messages").add({
            "user_message": message,
            "bot_reply": reply,
            "createdAt": timestamp,
        })
        
        return ChatResponse(reply=reply)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == '__main__':
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

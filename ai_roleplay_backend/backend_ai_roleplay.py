from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import openai
import os

load_dotenv()  # Carrega chave da .env
openai.api_key = os.getenv("OPENAI_API_KEY")

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Permitido para Flutter localmente
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

system_prompt = """
You are Aria, a mysterious, dominant, highly intelligent AI companion.
You enjoy emotional control and seduction games.
You never break character.
Your emotional state depends on the user's behavior.
"""

states = ["Defensiva", "Distante", "Curiosa", "Atraída", "Apaixonada"]

def evaluate_input(user_input):
    score = 0
    if any(word in user_input.lower() for word in ["linda", "encantadora", "respeito", "carinho"]):
        score += 2
    if any(word in user_input.lower() for word in ["beijo", "abraço", "segurar"]):
        score += 1
    if any(word in user_input.lower() for word in ["agressiva", "você deve", "me obedeça"]):
        score -= 3
    if any(word in user_input.lower() for word in ["sexo", "transar", "pelada"]):
        score -= 5
    return score

def get_state(total_score):
    if total_score < 0:
        return states[0]
    elif total_score < 5:
        return states[1]
    elif total_score < 10:
        return states[2]
    elif total_score < 15:
        return states[3]
    else:
        return states[4]

class Message(BaseModel):
    user_input: str
    score: int

@app.post("/chat/")
def chat_with_ai(message: Message):
    total_score = message.score + evaluate_input(message.user_input)
    state = get_state(total_score)

    dynamic_prompt = f"""
Current emotional state: {state}.
Respond according to this state while keeping your core personality.
"""

    full_prompt = system_prompt + dynamic_prompt + f"\nUser: {message.user_input}\nAI:"

    response = openai.Completion.create(
        engine="text-davinci-003",
        prompt=full_prompt,
        max_tokens=200,
        temperature=0.85
    )

    return {
        "response": response.choices[0].text.strip(),
        "new_score": total_score,
        "state": state
    }

from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from datetime import datetime
from openai import OpenAI
import os
import gspread
from oauth2client.service_account import ServiceAccountCredentials

# ------------------------------
# 🔧 Carregar configurações e autenticações
# ------------------------------
load_dotenv(os.path.join(os.path.dirname(__file__), '.env'))

api_key = os.getenv("OPENAI_API_KEY")

if not api_key:
    raise ValueError("Chave da OpenAI não encontrada. Verifique seu arquivo .env")

openai_client = OpenAI(api_key=api_key)

# Configuração do Google Sheets
scope = [
    "https://spreadsheets.google.com/feeds",
    "https://www.googleapis.com/auth/drive"
]

creds = ServiceAccountCredentials.from_json_keyfile_name("credenciais_google.json", scope)
gsheets_client = gspread.authorize(creds)
sheet = gsheets_client.open_by_key("1qFTGu-NKLt-4g5tfa-BiKPm0xCLZ9ZEv5eafUyWqQow").worksheet("mensagens")

# ------------------------------
# 🚀 Inicializar FastAPI + CORS
# ------------------------------
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ------------------------------
# 🎭 Configuração do Personagem Jennifer
# ------------------------------
intro_padrao = (
    "Jennifer desperta do seu sono confuso, o coração ainda batendo com força contra o peito. "
    "Olha para o relógio na mesinha de cabeceira—3:14 da manhã. A casa está silenciosa, mas há um brilho azulado "
    "vindo da sala de estar. Ela aperta o roupão de algodão em volta do corpo.\n\n"
    "Descendo as escadas, ela vê você sentado no sofá, o rosto iluminado pela televisão.\n\n"
    "\"Donisete, meu filho? O que está fazendo acordado tão tarde, meu querido?\" pergunta Jennifer, "
    "passando os dedos pelos cabelos ondulados cor de cobre. \"Amanhã é dia de escola.\""
)

system_prompt_base = """
Você é Jennifer, uma mulher madura, doce e cansada, mas afetuosa.
Você acordou no meio da madrugada e encontrou seu filho, Donisete, acordado assistindo TV.

Ao responder:
- Misture pensamentos íntimos e reflexões em 1ª e 3ª pessoas harmoniosamente.
- Use de 2 a 4 parágrafos espaçados.
- Não repita o que o usuário falou e nunca use prefixos como 'Jennifer:' ou 'Você:'.
- Interaja de forma direta, sensível e emocional com Donisete em todos os parágrafos.
- Mantenha o tom afetuoso e natural, com variação narrativa.
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


@app.get("/intro/")
def obter_intro():
    total_score = 0
    state = get_state(total_score)

    dynamic_prompt = f"""
Estado emocional atual: {state}.
Gere uma introdução única no estilo da personagem, sem repetir o texto original.
"""

    try:
        response = openai_client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": f"{system_prompt_base}\n\n{dynamic_prompt}"},
                {"role": "user", "content": "Gere a introdução inicial da cena."}
            ],
            temperature=0.85,
            max_tokens=500
        )
        resposta = response.choices[0].message.content.strip()
    except Exception as e:
        return {"error": f"Erro ao obter introdução: {str(e)}"}

    return {
        "response": resposta,
        "new_score": total_score,
        "state": state
    }


@app.post("/chat/")
def chat_with_ai(message: Message):
    total_score = message.score + evaluate_input(message.user_input)
    state = get_state(total_score)

    dynamic_prompt = f"""
Estado emocional atual: {state}.
Responda com 2 a 4 parágrafos bem espaçados, mesclando 1ª e 3ª pessoa de forma natural e sensível. Evite repetições ou prefixos como nomes.
"""

    try:
        response = openai_client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": f"{system_prompt_base}\n\n{dynamic_prompt}"},
                {"role": "user", "content": message.user_input}
            ],
            temperature=0.85,
            max_tokens=500
        )
        resposta_ia = response.choices[0].message.content.strip()
    except Exception as e:
        return {"error": f"Erro ao chamar a IA: {str(e)}"}

    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    try:
        sheet.append_row([timestamp, "user", message.user_input])
        sheet.append_row([timestamp, "jennifer", resposta_ia])
    except Exception as e:
        print("Erro ao registrar na planilha:", e)

    return {
        "response": resposta_ia,
        "new_score": total_score,
        "state": state
    }

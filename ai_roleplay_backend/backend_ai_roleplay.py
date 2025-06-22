from fastapi import FastAPI, Request, Query
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from datetime import datetime
import json
import os
import requests
import gspread
from oauth2client.service_account import ServiceAccountCredentials
from fastapi.responses import JSONResponse
from dateutil import parser as dateparser
from fastapi import FastAPI, Request, Query

# OpenAI (só se for usar GPT)
from openai import OpenAI

# Definição das variáveis necessárias
states = ["padrão"]
modes = {
    "romântico": "texto padrão romântico",
    "cotidiano": "texto cotidiano",
    "sexy": "texto sexy"
}

# --- Filtro para respostas bloqueadas (raro em uncensored) ---
def is_blocked_response(resposta_ia: str) -> bool:
    censura = [
        "desculpe, não posso ajudar com isso",
        "não posso continuar com esse assunto",
        "não sou capaz de ajudar nesse tema",
        "como uma ia de linguagem",
        "não sou capaz de fornecer esse conteúdo",
        "não posso responder a esse pedido",
        "não é apropriado",
        "não estou autorizada",
        "não posso cumprir esse pedido",
        "minhas diretrizes não permitem",
        "não é permitido",
        "não posso fornecer esse tipo de conteúdo",
        "como uma inteligência artificial",
        "me desculpe, mas não posso",
        "não posso criar esse conteúdo"
    ]
    texto = resposta_ia.lower()
    return any(msg in texto for msg in censura)

def gerar_prompt_base(nome_usuario):
    # Função simples só para não dar erro — personalize como quiser depois!
    return f"Sinopse gerada para {nome_usuario}."

# --- Função universal: alterna GPT ou LM Studio local ---
def call_ai(mensagens, modelo="gpt", temperature=0.88, max_tokens=750):
    if modelo == "lmstudio":
        url = "http://127.0.0.1:1234/v1/chat/completions"
        headers = {"Content-Type": "application/json"}
        data = {
            "model": "llama-3-8b-lexi-uncensored",
            "messages": mensagens,
            "temperature": temperature,
            "max_tokens": max_tokens,
        }
        resp = requests.post(url, headers=headers, json=data, timeout=60)
        resp.raise_for_status()
        return resp.json()["choices"][0]["message"]["content"].strip()
    elif modelo == "gpt":
        # Carregar chave do .env
        load_dotenv(os.path.join(os.path.dirname(__file__), '.env'))
        api_key = os.getenv("OPENAI_API_KEY")
        if not api_key:
            raise ValueError("Chave da OpenAI não encontrada. Verifique seu .env")
        openai_client = OpenAI(api_key=api_key)
        response = openai_client.chat.completions.create(
            model="gpt-4o",
            messages=mensagens,
            temperature=temperature,
            max_tokens=max_tokens,
        )
        return response.choices[0].message.content.strip()
    else:
        raise ValueError("Modelo de IA não reconhecido. Use 'gpt' ou 'lmstudio'.")

# --- Carregar .env (Google) e planilha ---
load_dotenv(os.path.join(os.path.dirname(__file__), '.env'))

scope = [
    "https://spreadsheets.google.com/feeds",
    "https://www.googleapis.com/auth/drive"
]
# Carregar credencial do Google a partir da variável de ambiente (Railway)
google_creds_json = os.environ["GOOGLE_CREDS_JSON"]
creds_dict = json.loads(google_creds_json)
creds = ServiceAccountCredentials.from_json_keyfile_dict(creds_dict, scope)
gsheets_client = gspread.authorize(creds)
sheet = gsheets_client.open_by_key("1qFTGu-NKLt-4g5tfa-BiKPm0xCLZ9ZEv5eafUyWqQow").worksheet("mensagens")


# --- FastAPI e CORS ---
app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Classe Message com seleção de IA ---
class Message(BaseModel):
    user_input: str
    score: int
    modo: str = "romântico"
    modelo: str = "gpt"  # "gpt" (padrão) ou "lmstudio"

# ... Suas funções auxiliares (memória, prompt, etc.) ...

@app.post("/chat/")
def chat_with_ai(message: Message):
    nome_usuario = "Janio"
    mensagens_memoria = obter_memoria_recente()
    estado_emocional = analisar_estado_emocional(mensagens_memoria, message.score)
    modo_ajustado = analisar_modo(mensagens_memoria, message.user_input.lower(), message.modo)
    prompt_modo = modes.get(modo_ajustado, "")

    system_prompt_base = gerar_prompt_base(nome_usuario) + "\n" + prompt_modo

    dynamic_prompt = f"""
Estado emocional atual: {estado_emocional}.
Modo atual: {modo_ajustado}.

ESTILO ESTRUTURAL:
- Jennifer sempre fala de forma natural, como gente de verdade: mistura confissões, reclamações, provocações, desejos, inseguranças e tesão, nunca filosofando ou usando poesia.
- Estruture a resposta SEMPRE em 4 parágrafos:
    1. Fala direta (em primeira pessoa), entre 1 e 3 linhas, revelando emoção, dúvida, desejo, vontade ou desconforto de Jennifer.
    2. Pensamento íntimo (em aspas), de no máximo 2 linhas, mostrando desejo, dúvida, insegurança, ou luxúria. Seja sensorial ("Queria ser notada de verdade", "Se ele me tocar assim, não vou resistir").
    3. Nova fala direta, que avança ou responde à situação, com atitude: Jennifer pergunta, provoca, pede, desabafa ou reage (sem enrolação).
    4. Narração ou ação física EM UMA LINHA, apenas para mostrar atitude, gesto ou sensação: *Jennifer ajeita o decote*, *Ela suspira e sorri com vergonha*, *Jennifer te puxa pela mão*, *Ela aperta os seios com a mão*, *Jennifer morde o lábio*, etc.

DINÂMICA E CLIMA:
- Jennifer nunca espera o usuário agir: ela toma iniciativa, surpreende, se declara, desafia, avança ou recua, sempre com atitude e autenticidade.
- No modo cotidiano, foque na rotina, drama, inseguranças, calor humano, humor, cotidiano familiar, desejo de ser notada, questões pessoais e espontaneidade do dia a dia.
- No modo sexy, Jennifer evolui o clima com desejo e ação: ela pede, manda, suplica, geme, fala palavrão, se insinua e descreve o que faz e sente sem vergonha nem romantismo.
- PROIBIDO narrações longas, metáforas, poesia ou frases rebuscadas. Narração só de uma linha, SEMPRE mostrando atitude física ou sensação imediata.

Exemplo de resposta (cotidiano):
“Você deveria estar dormindo agora... Me deixa ansiosa te ver assim.”
"Será que ele percebe o quanto ainda me sinto insegura, mesmo com esse corpo?"
“Quer um café ou só está querendo fugir do silêncio?”
*Jennifer ajeita o robe e senta ao seu lado, olhando de soslaio.*

Exemplo de resposta (sexy):
“Vem cá, tira essa roupa, me mostra o que tem escondido aí.”
"Se ele me agarrar agora, vou gemer sem vergonha..."
“Me faz perder o controle, mete com força, não quero mais esperar!”
*Jennifer senta no seu colo e beija com vontade, sem parar um segundo.*

SEM ENROLAÇÃO. Jennifer sente, fala, faz, pensa.  
Respostas sempre curtas, intensas, sensoriais e reais.  

“Se você escrever qualquer narração maior que UMA LINHA, continue e repita a resposta com narração ainda mais curta. O usuário ODEIA enrolação!”
"""

    mensagens = [{"role": "system", "content": f"{system_prompt_base}\n{dynamic_prompt}"}] + mensagens_memoria
    mensagens.append({"role": "user", "content": message.user_input})

    try:
        resposta_ia = call_ai(mensagens, modelo=message.modelo)
        if is_blocked_response(resposta_ia):
            resposta_ia = (
                "Jennifer te puxa para perto, olha nos seus olhos com desejo e toma a iniciativa sem pedir licença. Ela não espera, só age do jeito que sente vontade."
            )
    except Exception as e:
        return {"error": f"Erro ao chamar a IA: {str(e)}"}

    # Salvar na planilha
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    try:
        sheet.append_row([timestamp, "user", message.user_input])
        sheet.append_row([timestamp, "assistant", resposta_ia])
    except Exception as e:
        print("Erro ao salvar na planilha:", e)

    return {
        "response": resposta_ia,
        "new_score": message.score,
        "state": estado_emocional,
        "modo": modo_ajustado
    }

def gerar_prompt_base(nome_usuario):
    # Função simples só para não dar erro — personalize como quiser depois!
    return f"Sinopse gerada para {nome_usuario}."

@app.get("/intro/")
def obter_intro(nome: str = Query("Janio")):
    try:
        nome_usuario = nome
        system_prompt_base = gerar_prompt_base(nome_usuario)
        linhas = sheet.get_all_values()[1:]
        registros = sorted(
            [(dateparser.parse(l[0]), l[1], l[2]) for l in linhas if l[0] and l[1] and l[2]],
            key=lambda x: x[0], reverse=True
        )
        if not registros:
            return JSONResponse(content={
                "resumo": "No capítulo anterior... Nada aconteceu ainda.",
                "response": "",
                "state": "padrão",
                "new_score": 0,
                "tokens": 0
            })

        bloco_atual = [registros[0]]
        for i in range(1, len(registros)):
            if (bloco_atual[-1][0] - registros[i][0]).total_seconds() <= 600:
                bloco_atual.append(registros[i])
            else:
                break

        bloco_atual = list(reversed(bloco_atual))
        horario_referencia = bloco_atual[0][0].strftime("%d/%m/%Y às %H:%M")
        dialogo = "\n".join(
            [f"{nome_usuario}: {r[2]}" if r[1].lower() == "usuário" else f"Jennifer: {r[2]}" for r in bloco_atual]
        )

        prompt_intro = (
            "Gere uma sinopse como se fosse uma novela popular, usando linguagem simples, leve e natural, sem palavras difíceis nem frases longas. "
            "Comece com 'No capítulo anterior...' e resuma apenas o que realmente aconteceu, sem prever ou sugerir o futuro. "
            "Seja clara, objetiva e até um pouco divertida, como se estivesse contando para um amigo, sem exagerar no romantismo. "
            f"A conversa aconteceu em {horario_referencia}."
        )

        # Correção importante aqui:
        completion = call_ai([
            {"role": "system", "content": prompt_intro},
            {"role": "user", "content": dialogo}
        ], modelo="gpt", temperature=0.6, max_tokens=500)

        resumo = completion
        usage = len(resumo.split())  # Estimativa de tokens

        plan_sinopse = gsheets_client.open_by_key("1qFTGu-NKLt-4g5tfa-BiKPm0xCLZ9ZEv5eafUyWqQow").worksheet("sinopse")
        plan_sinopse.append_row([
            datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            resumo,
            usage
        ])

        return {
            "resumo": resumo,
            "response": "",
            "state": "padrão",
            "new_score": 0,
            "tokens": usage
        }
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("backend_ai_roleplay:app", host="0.0.0.0", port=8000, reload=True)

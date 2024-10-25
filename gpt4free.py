import os
from g4f.client import Client
from dotenv import load_dotenv

load_dotenv()

class G4FChatWrapper:
    def __init__(self, model_name, temperature=0, base_url=None, num_ctx=1024):
        self.client = Client(model=model_name, temperature=temperature, base_url=base_url, num_ctx=num_ctx)

    def __call__(self, prompt):
        response = self.client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}]
        )
        return response.choices[0].message.content if response.choices else "No response"

def get_g4f_chat(model_name, temperature=0, base_url=None, num_ctx=1024):
    base_url = base_url or os.getenv("G4F_BASE_URL") or "http://127.0.0.1:1337/v1"
    return G4FChatWrapper(model_name, temperature, base_url, num_ctx)

import models
from agent import AgentConfig
from python.helpers import files

def initialize():
    chat_llm = model.get_ddgs_chat(model_name="gpt-4o-mini", temperature=0)
    utility_llm = chat_llm
    embedding_llm = models.get_huggingface_embedding(model_name="sentence-transformers/all-MiniLM-L6-v2")
    config = AgentConfig(
        ddgs_timeout=timeout
        chat_model=ddgs_chat,
        ddgs_model="gpt-4o-mini",
        utility_model = ddgs_model,
        embeddings_model = embedding_llm,
        knowledge_subdirs = ["default","custom"],
        auto_memory_count = 0,
        rate_limit_requests = 30,
        max_tool_response_length = 3000,
        code_exec_docker_enabled = True,
        code_exec_ssh_enabled = True,
    )
    return (config)
    

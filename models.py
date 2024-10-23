import os
import asyncio
from duckduckgo_search import AsyncDDGS
from langchain_core.language_models.chat_models import BaseChatModel
from langchain_core.messages import AIMessage, BaseMessage
from typing import List, Optional, Any, Dict, Iterator
from python.helpers.dotenv import load_dotenv
from langchain_huggingface import HuggingFaceEmbeddings
from pydantic import BaseModel, Field

# environment variables
load_dotenv()

# Configuration
DEFAULT_TEMPERATURE = 0.0
timeout = 30

class AsyncDDGSChat(BaseChatModel):
    """
    Adapter class to make AsyncDDGS chat compatible with LangChain's BaseChatModel
    """
    model: str = Field(default="gpt-4o-mini")  # Define model as a field
    temperature: float = Field(default=DEFAULT_TEMPERATURE)  # Define temperature as a field
    timeout: int = Field(default=30)  # Define timeout as a field

    # Use a field default factory to initialize ddgs
    ddgs: AsyncDDGS = Field(default_factory=AsyncDDGS)

    def _combine_messages(self, messages: List[BaseMessage]) -> str:
        """Combine multiple messages into a single string for DDGS chat"""
        return "\n".join(msg.content for msg in messages)

    async def _agenerate(
        self, messages: List[BaseMessage], stop: Optional[List[str]] = None, **kwargs: Any
    ) -> AIMessage:
        """Async generation method required by BaseChatModel"""
        combined_message = self._combine_messages(messages)
        try:
            response = await self.ddgs.achat(
                combined_message,
                model=self.model,
                timeout=self.timeout
            )
            return AIMessage(content=response)
        except Exception as e:
            raise Exception(f"DDGS Chat Error: {str(e)}")

    def _generate(
        self, messages: List[BaseMessage], stop: Optional[List[str]] = None, **kwargs: Any
    ) -> AIMessage:
        """Sync generation method required by BaseChatModel"""
        return asyncio.run(self._agenerate(messages, stop=stop, **kwargs))

    async def _astream(
        self, messages: List[BaseMessage], stop: Optional[List[str]] = None, **kwargs: Any
    ) -> Iterator[AIMessage]:
        """
        Implement streaming interface. Since DDGS doesn't support native streaming,
        we'll simulate it by yielding the complete response.
        """
        response = await self._agenerate(messages, stop, **kwargs)
        yield response

    @property
    def _llm_type(self) -> str:
        return "ddgs_chat"


# Utility function to get API keys from environment variables
def get_api_key(service):
    return os.getenv(f"API_KEY_{service.upper()}") or os.getenv(f"{service.upper()}_API_KEY")

# ddgs
def get_ddgs_chat(model_name: str, temperature=DEFAULT_TEMPERATURE):
    return AsyncDDGSChat(model=model_name, temperature=temperature)

def get_huggingface_embedding(model_name: str):
    return HuggingFaceEmbeddings(model_name=model_name)

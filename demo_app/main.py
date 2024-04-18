"""Python file to serve as the frontend"""
import sys
import os
sys.path.append(os.path.abspath('.'))

import numpy as np
#import pandas as pd
import datetime as dt
import os
#import matplotlib.pyplot as plt
from langchain.embeddings.openai import OpenAIEmbeddings
#from langchain_openai import ChatOpenAI
from langchain.chains import ConversationalRetrievalChain
from langchain.document_loaders.csv_loader import CSVLoader
from langchain.memory import ConversationBufferMemory
from langchain.prompts import PromptTemplate, SystemMessagePromptTemplate, HumanMessagePromptTemplate,  ChatPromptTemplate
from langchain.retrievers import ContextualCompressionRetriever
from langchain.retrievers.document_compressors import EmbeddingsFilter
from langchain.retrievers.self_query.base import SelfQueryRetriever
from langchain.chains.query_constructor.base import AttributeInfo
from langchain.vectorstores import FAISS, Chroma
import csv
from typing import Dict, List, Optional
from langchain.document_loaders.base import BaseLoader
from langchain.docstore.document import Document
from langchain.chains.llm import LLMChain
#from google.colab import userdata
#import lark

from langchain.chat_models import ChatOpenAI
import chainlit as cl

from chainlit import user_session

user_env = user_session.get("env")

# os.environ["OPENAI_API_KEY"] = ""

template = """Question: {question}

Answer: Let's think step by step."""

@cl.langchain_factory(use_async=True)
def factory():
    user_env = cl.user_session.get("env")
    os.environ["OPENAI_API_KEY"] = user_env.get("OPENAI_API_KEY")
    prompt = PromptTemplate(template=template, input_variables=["question"])
    llm_chain = LLMChain(prompt=prompt, llm=ChatOpenAI(model_name="gpt-3.5-turbo-0125",temperature=0), verbose=True)

    return llm_chain

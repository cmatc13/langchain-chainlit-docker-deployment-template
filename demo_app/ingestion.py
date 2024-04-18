# ingestion.py - Module for data ingestion using Selenium


from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import Select
import os
import time

#Necessary import

import numpy as np
import pandas as pd
import datetime as dt
import os
import matplotlib.pyplot as plt
from langchain.embeddings.openai import OpenAIEmbeddings
from langchain_openai import ChatOpenAI
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
from google.colab import userdata
import lark



def ingest_data():
    # Initialize Selenium WebDriver
    driver = webdriver.Chrome()

    # Example: Scrape data from a website
    driver.get("https://example.com/data")

    # Extract data (replace this with your actual scraping logic)
    data = driver.find_element_by_css_selector("table").text

    # Close the WebDriver
    driver.quit()

    # Save data to a file or database (for demonstration, we print it)
    print("Data ingested:", data)
    #return data

def download_eplex_data(theme_value, file_name):
    # Set up Chrome options
    chrome_options = Options()
    chrome_options.add_argument('--headless')  # Run Chrome in headless mode
    chrome_options.add_argument('--no-sandbox')
    chrome_options.add_argument('--disable-dev-shm-usage')

    # Set up Chrome webdriver
    driver = webdriver.Chrome(options=chrome_options)

    # URL of the website
    url = "https://eplex.ilo.org/"

    # Open the website
    driver.get(url)

    try:
        # Click on the 'Download EPLex legal data' button
        button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, "/html/body/section[3]/div/div/div/div/p[2]/a"))
        )
        button.click()

        # Wait for the theme dropdown to be clickable
        theme_select = WebDriverWait(driver, 4).until(
            EC.element_to_be_clickable((By.XPATH, "/html/body/div[1]/div/div/div[2]/form/div[1]/div/select"))
        )

        # Click on the theme dropdown to open it
        theme_select.click()

        # Select the theme
        theme_option = WebDriverWait(driver, 4).until(
            EC.visibility_of_element_located((By.XPATH, f"//option[@value='{theme_value}']"))
        )
        theme_option.click()

        # Select year
        year_select = Select(driver.find_element(By.XPATH, "/html/body/div[1]/div/div/div[2]/form/div[2]/div/select"))
        year_select.select_by_value("latest")  # Change to the desired year

        # Select format
        format_select = Select(driver.find_element(By.XPATH, "/html/body/div[1]/div/div/div[2]/form/div[3]/div/select"))
        format_select.select_by_value("csv")  # Change to the desired format

        # Click the download button
        #download_button = driver.find_element(By.XPATH, "//button[contains(text(), 'Download')]")
        #download_button.click()
        # Wait for the download button to be clickable
        download_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, "/html/body/div[1]/div/div/div[2]/form/div[4]/button[2]"))
        )


        # Specify the download folder
        download_folder = "/content/downloads"  # Change this to the desired folder path

        # Create the download folder if it doesn't exist
        os.makedirs(download_folder, exist_ok=True)

        # Specify the file name
        file_path = os.path.join("/content", file_name)

        download_button.click()

        # Wait for the file to be downloaded
        while not os.path.exists(file_path):
            time.sleep(10)  # Wait for 10 seconds

        # Move the downloaded file to the specified folder
        os.rename(file_path, os.path.join(download_folder, file_name))

        print("Download completed. File saved to:", os.path.join(download_folder, file_name))

    finally:
        # Close the webdriver
        driver.quit()

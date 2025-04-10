# QuickStart Guide

This guide will help you set up and run the ReportCard RAG chatbot on your local machine.

## 🚀 Prerequisites

- Python 3.13.2 installed
- Anaconda or Miniconda (recommended for environment management)
- API keys:
  - OpenAI API key (for embeddings and LLM)
  - LlamaParse API key (for PDF parsing)
  - Tavily API key (for research capabilities)
- Report card PDFs for analysis

## 🛠️ Environment Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/zacharyvunguyen/reportcard-rag-chatbot.git
   cd reportcard-rag-chatbot
   ```

2. **Create and activate Conda environment**
   ```bash
   conda create -n reportcard-rag python=3.13
   conda activate reportcard-rag
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure environment variables**
   ```bash
   cp .env.example .env
   ```
   Edit `.env` with your API keys:
   ```
   OPENAI_API_KEY=your_openai_api_key
   LLAMA_PARSE_API_KEY=your_llamaparse_api_key
   TAVILY_API_KEY=your_tavily_api_key
   REDIS_URL=redis://localhost:6379
   ```

## 📚 Using the Report Card RAG Chatbot

### Running the Web Interface

1. **Start the Streamlit app**
   ```bash
   cd demo
   streamlit run test_agent_chain_04.py
   ```

2. **Access the interface**
   - Open your browser and navigate to `http://localhost:8501`
   - Upload your report card PDF
   - Start interacting with the chatbot

### Features Available

1. **Chat Interface**
   - Natural language queries
   - Context-aware responses
   - Multi-turn conversations
   - Clear chat history option

2. **Analysis Outputs**
   - Agent-specific outputs in dedicated tabs
   - Tool execution results
   - Analysis results
   - PDF report generation

3. **Student Information**
   - Basic information display
   - Quick summary insights
   - Performance metrics

4. **PDF Reports**
   - Professional report generation
   - Analysis summary downloads
   - Visual data representation

## 🔍 Example Queries

Try these example queries to test the system:

1. **Performance Analysis**
   ```
   "Analyze this student's overall performance"
   "What are the student's strengths?"
   "Show me areas needing improvement"
   ```

2. **Subject-Specific Analysis**
   ```
   "How is the student doing in mathematics?"
   "Analyze the reading comprehension scores"
   "What are the science assessment results?"
   ```

3. **Study Planning**
   ```
   "Create a study plan for improving math skills"
   "Suggest resources for reading practice"
   "Generate a learning strategy for science"
   ```

4. **Report Generation**
   ```
   "Generate a comprehensive report"
   "Create a performance summary"
   "Make a detailed analysis report"
   ```

## 🐛 Troubleshooting

### Common Issues

1. **API Connection Errors**
   - Verify API keys in `.env`
   - Check internet connection
   - Ensure API service status

2. **PDF Processing Issues**
   - Verify PDF format and readability
   - Check file permissions
   - Ensure sufficient disk space

3. **Vector Store Issues**
   - Verify LlamaIndex storage is working
   - Check index directory exists
   - Ensure proper permissions for storage

### Getting Help

1. **Check Logs**
   - View Streamlit logs in terminal
   - Check application logs
   - Review error messages

2. **Community Support**
   - GitHub Issues
   - Documentation
   - Community forums

## 📚 Additional Resources

- [LlamaIndex Documentation](https://docs.llamaindex.ai/)
- [OpenAI API Documentation](https://platform.openai.com/docs/api-reference)
- [LlamaParse Documentation](https://docs.llamaindex.ai/en/stable/examples/llm/llama_parse.html)
- [Streamlit Documentation](https://docs.streamlit.io/) 
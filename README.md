# AI Governance Assessment Tool

A Shiny application for continuous AI governance assessment based on the NIST AI Risk Management Framework (AI RMF). This app integrates with local LLM servers (llama.cpp or Ollama) to generate AI-powered governance recommendations.

## Features

- **8 Governance Domains**: Policies, Accountability, Human Oversight, Culture, External Feedback, Third-Party Risk, Lifecycle Management, Privacy & Security
- **Gap Analysis**: Visual comparison of current vs target maturity levels
- **Priority Matrix**: Benefit vs effort analysis for action planning
- **LLM Integration**: AI-powered recommendations using local llama.cpp server
- **Export Reports**: Excel exports for executive summaries and action plans

## Requirements

### R Packages

```r
install.packages(c(
  "shiny",
  "shinydashboard",
  "shinydashboardPlus",
  "DT",
  "plotly",
  "dplyr",
  "tidyr",
  "httr",
  "jsonlite",
  "openxlsx",
  "markdown"
))

# Optional: for Ollama/OpenAI support
install.packages("ellmer")
```

### LLM Server (Choose One)

#### Option 1: llama.cpp (Recommended)

llama.cpp provides a high-performance local inference server with an OpenAI-compatible API.

**Installation:**

1. **Clone and build llama.cpp:**
   ```bash
   git clone https://github.com/ggerganov/llama.cpp
   cd llama.cpp
   make -j
   ```

   For GPU acceleration, see the [llama.cpp build guide](https://github.com/ggerganov/llama.cpp#build).

2. **Download a GGUF model:**

   Popular options from [Hugging Face](https://huggingface.co/models?search=gguf):
   - [Llama 3.1 8B](https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF)
   - [Mistral 7B](https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF)
   - [Phi-3 Mini](https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf)

3. **Start the server:**
   ```bash
   ./llama-server -m /path/to/model.gguf --port 8080
   ```

   Common options:
   ```bash
   # With GPU layers (adjust based on VRAM)
   ./llama-server -m model.gguf --port 8080 -ngl 35

   # With context size
   ./llama-server -m model.gguf --port 8080 -c 4096

   # With multiple parallel requests
   ./llama-server -m model.gguf --port 8080 --parallel 4
   ```

4. **Verify the server:**
   ```bash
   curl http://localhost:8080/health
   ```

**Using project scripts:**

This project includes helper scripts for running llama.cpp:

```bash
# Set model path and start server
export LLAMA_MODEL_PATH=/path/to/model.gguf
./start_llama_rr.sh start

# Stop server
./start_llama_rr.sh stop
```

See the main project [README.md](../README.md) for full environment variable options.

#### Option 2: Ollama (Easy Setup)

Ollama provides a simpler installation experience with model management.

1. **Install Ollama:**
   - macOS/Linux: https://ollama.ai
   - Or via Homebrew: `brew install ollama`

2. **Start the server:**
   ```bash
   ollama serve
   ```

3. **Pull a model:**
   ```bash
   ollama pull llama3.1:8b
   ```

4. **Verify:**
   ```bash
   curl http://localhost:11434/api/tags
   ```

#### Option 3: OpenAI (Cloud)

For OpenAI, you need an API key:

1. Get an API key from [OpenAI Platform](https://platform.openai.com)
2. Either:
   - Set environment variable: `export OPENAI_API_KEY=sk-...`
   - Or enter the key in the app's settings panel

Note: Requires the `ellmer` R package.

## Running the App

1. **Start your LLM server** (see above)

2. **Launch the Shiny app:**
   ```bash
   cd app
   R -e "shiny::runApp()"
   ```

   Or from R:
   ```r
   setwd("app")
   shiny::runApp()
   ```

3. **Open in browser:** http://127.0.0.1:3838 (or the port shown in console)

## Using the App

### Assessment Workflow

1. **Dashboard**: View overall governance maturity scores
2. **Assessment (GOV 1-8)**: Rate current and target maturity for each governance area
3. **Gap Analysis**: Review gaps between current and target states
4. **Action Plan**: Generate AI recommendations and prioritize actions
5. **Reports**: Export results to Excel

### LLM Configuration

In the **Action Plan** tab under "AI-Generated Recommendations":

1. Select your LLM provider (llama.cpp, Ollama, or OpenAI)
2. Configure the server URL (default: `http://localhost:8080` for llama.cpp)
3. Click "Test Connection" to verify
4. Click "Generate AI Recommendations" to get governance insights

### Maturity Levels

| Level | Description |
|-------|-------------|
| 0 - Absent | No capability exists |
| 1 - Initial/Ad hoc | Informal, reactive processes |
| 2 - Defined | Documented policies and procedures |
| 3 - Repeatable | Consistent, measured processes |
| 4 - Managed/Optimized | Continuous improvement, metrics-driven |

## Troubleshooting

### llama.cpp Connection Issues

```
Cannot connect to llama.cpp server
```

- Verify server is running: `curl http://localhost:8080/health`
- Check the port matches your configuration
- Ensure no firewall is blocking the connection

### Server Busy (503)

```
llama.cpp server is busy (503)
```

- The server is processing another request
- Wait a moment and try again
- Consider starting the server with `--parallel N` for concurrent requests

### Timeout Errors

- Long prompts may take time to process
- Consider using a smaller/quantized model
- Increase context with `-c 4096` if model supports it

## Project Structure

```
app/
├── app.R           # Main Shiny application
└── README.md       # This file
```

## References

- [NIST AI Risk Management Framework](https://www.nist.gov/itl/ai-risk-management-framework)
- [llama.cpp GitHub](https://github.com/ggerganov/llama.cpp)
- [llama.cpp Server Documentation](https://github.com/ggerganov/llama.cpp/tree/master/examples/server)
- [Ollama](https://ollama.ai)
- [Hugging Face GGUF Models](https://huggingface.co/models?search=gguf)

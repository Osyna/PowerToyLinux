#!/bin/bash

# Shell command assistant using Ollama
HISTORY_FILE="$HOME/.shell_assist_history"
MODEL="yi-coder"

# Create history file if it doesn't exist
touch "$HISTORY_FILE"

explain_command() {
    local cmd="$1"
    echo "🤔 Analyzing command..."
    ollama run $MODEL "Explain this shell command in detail: $cmd"
}

suggest_command() {
    local desc="$1"
    echo "🔍 Generating command..."
    ollama run $MODEL "Generate a shell command for this task. Only output the command itself without explanation: $desc"
}

review_command() {
    local cmd="$1"
    echo "🔍 Reviewing command for safety..."
    ollama run $MODEL "Review this shell command for safety and potential issues. Be brief and focus on risks: $cmd"
}

# Main menu
while true; do
    echo -e "\n🛠️  Shell Assistant Menu:"
    echo "1) Explain a command"
    echo "2) Generate a command from description"
    echo "3) Review command safety"
    echo "4) View command history"
    echo "q) Quit"

    read -p "Choose an option: " choice

    case $choice in
        1)
            read -p "Enter command to explain: " cmd
            explain_command "$cmd" | tee -a "$HISTORY_FILE"
            ;;
        2)
            read -p "Describe what you want to do: " desc
            suggest_command "$desc" | tee -a "$HISTORY_FILE"
            ;;
        3)
            read -p "Enter command to review: " cmd
            review_command "$cmd" | tee -a "$HISTORY_FILE"
            ;;
        4)
            echo -e "\n📜 Command History:"
            cat "$HISTORY_FILE"
            ;;
        q)
            exit 0
            ;;
    esac
done

#!/bin/bash

#!/bin/bash
if command -v nvidia-smi &> /dev/null; then
    # For NVIDIA GPUs
    gpu_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)
    gpu_memory=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
    gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)
    total_memory=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits)

    # Calculate memory usage percentage
    memory_percentage=$((gpu_memory * 100 / total_memory))

    # Format output as "GPU_USAGE%/MEM_USAGE%"
    echo "${memory_percentage}% | ${gpu_temp}°C"
else
    # For AMD GPUs (requires radeontop)
    if command -v radeontop &> /dev/null; then
        gpu_usage=$(radeontop -d- -l1 | grep -o 'gpu [0-9.]*' | awk '{print $2}')
        echo "$gpu_usage/N/A"
    else
        echo "N/A"
    fi
fi

#!/usr/bin/env python3

# Copyright Majestic Labs ai
# 
# Used in this repo: https://github.com/mlcommons/inference_results_v5.1

"""Extract specific fields from NVIDIA config files and output as JSON."""

import ast
import glob
import json
import os
import re
import sys

# Token statistics by model substring
# Source: https://mlcommons.org/2025/04/llm-inference-v5/
TOKEN_STATS = {
    "405b": {
        "input_tokens_mean": 9428.64,
        "output_tokens_mean": 684.68,
    },
    # Source: https://mlcommons.org/2025/09/deepseek-inference-5-1/
    "deepseek": {
        "input_tokens_mean": 800,
        "output_tokens_mean": 3880,
    },
    # Source: https://mlcommons.org/2025/09/small-llm-inference-5-1/
    "llama3_1-8b": {
        "input_tokens_mean": 870.73,
        "output_tokens_mean": 72.04,
    },
    # Source: https://mlcommons.org/2024/03/mlperf-llama2-70b/
    # Source: Claudionor for output
    "llama2-70b": {
        "input_tokens_mean": 300,
        "output_tokens_mean": 300,
    },
}


def extract_value(node):
    """Convert an AST node to its Python value."""
    if isinstance(node, ast.Constant):
        return node.value
    elif isinstance(node, ast.Dict):
        return {
            extract_value(k): extract_value(v)
            for k, v in zip(node.keys, node.values)
            if k is not None
        }
    elif isinstance(node, ast.List):
        return [extract_value(elem) for elem in node.elts]
    elif isinstance(node, ast.Tuple):
        return tuple(extract_value(elem) for elem in node.elts)
    elif isinstance(node, ast.Name):
        return node.id
    elif isinstance(node, ast.UnaryOp) and isinstance(node.op, ast.USub):
        return -extract_value(node.operand)
    else:
        return None


def get_key_name(node):
    """Get the string representation of a dictionary key (e.g., 'model_fields.precision')."""
    if isinstance(node, ast.Attribute):
        value = get_key_name(node.value)
        return f"{value}.{node.attr}" if value else node.attr
    elif isinstance(node, ast.Name):
        return node.id
    return None


def config_path_to_results_path(config_path):
    """Transform config path to results path.

    Example:
    closed/NVIDIA/configs/GB200-NVL72_GB200-186GB_aarch64x72/Offline/llama3_1-405b.py
    -> closed/NVIDIA/results/GB200-NVL72_GB200-186GB_aarch64x72_TRT/llama3.1-405b/Offline/performance/run_1/mlperf_log_detail.txt
    """
    # Parse the config path
    # Format: closed/NVIDIA/configs/{system}/{scenario}/{model}.py
    parts = config_path.split('/')
    system = parts[3]  # e.g., GB200-NVL72_GB200-186GB_aarch64x72
    scenario = parts[4]  # e.g., Offline
    model = parts[5].replace('.py', '')  # e.g., llama3_1-405b

    # Transform model name: replace underscores with dots (e.g., llama3_1 -> llama3.1)
    model = model.replace('_', '.')

    # Build results path with _TRT suffix on system name
    results_path = f"closed/NVIDIA/results/{system}_TRT/{model}/{scenario}/performance/run_1/mlperf_log_detail.txt"

    return results_path


def extract_mlperf_results(results_path):
    """Extract result_max_latency_ns and result_tokens_per_second from mlperf_log_detail.txt."""
    result = {
        "result_max_latency_ns": None,
        "result_tokens_per_second": None,
    }

    # Try different model name variants (with -99 suffix for some models)
    paths_to_try = [results_path]

    # Also try with -99 and -99.9 suffixes for models like llama2-70b
    if '/llama2-70b/' in results_path:
        paths_to_try.append(results_path.replace('/llama2-70b/', '/llama2-70b-99/'))
        paths_to_try.append(results_path.replace('/llama2-70b/', '/llama2-70b-99.9/'))

    for path in paths_to_try:
        if os.path.exists(path):
            with open(path, 'r') as f:
                for line in f:
                    if ':::MLLOG' in line:
                        # Extract the JSON part
                        json_str = line.split(':::MLLOG ', 1)[1]
                        try:
                            data = json.loads(json_str)
                            key = data.get('key')
                            if key == 'result_max_latency_ns':
                                result['result_max_latency_ns'] = data.get('value')
                            elif key == 'result_tokens_per_second':
                                result['result_tokens_per_second'] = data.get('value')
                        except json.JSONDecodeError:
                            pass
            break

    return result


def extract_fields_from_file(filepath, include_results=True):
    """Parse the config file and extract the requested fields."""
    with open(filepath, 'r') as f:
        source = f.read()

    tree = ast.parse(source)

    # Find all top-level variable assignments (including 'base' and 'EXPORTS')
    variables = {}
    exports_dict = None
    for node in ast.walk(tree):
        if isinstance(node, ast.Assign):
            for target in node.targets:
                if isinstance(target, ast.Name):
                    variables[target.id] = node.value
                    if target.id == 'EXPORTS':
                        exports_dict = node.value

    if exports_dict is None or not isinstance(exports_dict, ast.Dict):
        raise ValueError("Could not find EXPORTS dictionary")

    # The EXPORTS dict has WorkloadSetting keys, we want the first one's values
    if not exports_dict.values:
        raise ValueError("EXPORTS dictionary is empty")

    # Get the first workload setting's config dict
    first_config = exports_dict.values[0]

    # If it's a variable reference (e.g., 'base'), look it up
    if isinstance(first_config, ast.Name) and first_config.id in variables:
        first_config = variables[first_config.id]

    if not isinstance(first_config, ast.Dict):
        raise ValueError("First config is not a dictionary")

    # Build a mapping of key names to values
    config_map = {}
    for key_node, value_node in zip(first_config.keys, first_config.values):
        key_name = get_key_name(key_node)
        if key_name:
            config_map[key_name] = extract_value(value_node)

    # Extract the requested fields
    result = {
        "model_fields.precision": config_map.get("model_fields.precision"),
        "llm_fields.tensor_parallelism": config_map.get("llm_fields.tensor_parallelism"),
        "llm_fields.pipeline_parallelism": config_map.get("llm_fields.pipeline_parallelism"),
        "llm_fields.moe_expert_parallelism": config_map.get("llm_fields.moe_expert_parallelism", -1),
        "llm_fields.trtllm_checkpoint_flags.kv_cache_dtype": None,
        "model_fields.gpu_batch_size": None,
    }

    # Handle nested field for checkpoint flags
    checkpoint_flags = config_map.get("llm_fields.trtllm_checkpoint_flags")
    if isinstance(checkpoint_flags, dict):
        result["llm_fields.trtllm_checkpoint_flags.kv_cache_dtype"] = checkpoint_flags.get("kv_cache_dtype")

    # Handle gpu_batch_size - extract just the value from the dict
    gpu_batch_size = config_map.get("model_fields.gpu_batch_size")
    if isinstance(gpu_batch_size, dict) and gpu_batch_size:
        result["model_fields.gpu_batch_size"] = next(iter(gpu_batch_size.values()))

    # Extract results from mlperf_log_detail.txt
    if include_results:
        results_path = config_path_to_results_path(filepath)
        mlperf_results = extract_mlperf_results(results_path)
        result.update(mlperf_results)

    # Add token statistics if the filepath matches a known model substring
    for substring, stats in TOKEN_STATS.items():
        if substring in filepath:
            result["input_tokens_mean"] = stats["input_tokens_mean"]
            result["output_tokens_mean"] = stats["output_tokens_mean"]
            break

    return result


def main():
    if len(sys.argv) < 2:
        print("Usage: python extract_json.py <search_pattern>", file=sys.stderr)
        print("Example: python extract_json.py B200", file=sys.stderr)
        sys.exit(1)

    pattern = sys.argv[1]
    config_dir = "closed/NVIDIA/configs"

    # Find all .py files and filter by pattern in full path
    # Exclude /Interactive/ and /Server/ directories
    all_files = glob.glob(f"{config_dir}/**/*.py", recursive=True)
    matching_files = sorted([
        f for f in all_files
        if pattern in f and "/Interactive/" not in f and "/Server/" not in f
    ])

    if not matching_files:
        print(f"No files found matching pattern: {pattern}", file=sys.stderr)
        sys.exit(1)

    results = {}
    for filepath in matching_files:
        try:
            results[filepath] = extract_fields_from_file(filepath)
        except (ValueError, SyntaxError) as e:
            results[filepath] = {"error": str(e)}

    print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()

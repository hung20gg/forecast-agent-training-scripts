import re
import math
from datetime import datetime, timedelta
import json

# Extract <answer> ... </answer> from the response
def extract_answer(response: str) -> str:
    match = re.search(r"<answer>(.*?)</answer>", response, re.DOTALL)
    if match:
        return match.group(1).strip()
    return ""


# Extract <tool_call> ... </tool_call> from the response
def extract_tool_call(response: str) -> list[str]:     
    matches = re.findall(r"<tool_call>(.*?)</tool_call>", response, re.DOTALL)
    return [m.strip() for m in matches]
    
def extract_numerical_answer(response: str) -> tuple[float, float]:
    pattern = r"\\boxed\{([^}]*)\}\s*\\pm\s*\\boxed\{([^}]*)\}"

    match = re.search(pattern, response)

    if match:
        try:
            mean = float(match.group(1).replace(',', ''))
            std = float(match.group(2).replace(',', ''))
        
            return mean, std
        except ValueError:
            return None, None
    else:
        return None, None


def chi2_pdf(x, df=15):
    if x < 0:
        return 0.0
    
    coef = 1.0 / ( (2 ** (df / 2.0)) * math.gamma(df / 2.0) )
    return coef * (x ** (df / 2.0 - 1.0)) * math.exp(-x / 2.0)


def nll_exclude_min(pred_mean, pred_std, true_mean, true_std = 0):

    if true_std == 0:
        true_std = true_mean * 0.1

    return math.log(pred_std/true_std) + 0.5 * (true_std ** 2 + (pred_mean - true_mean) ** 2) / true_std ** 2 - 0.5


def compute_score(data_source, solution_str, ground_truth, extra_info, alpha = 0.5):

    # Extra infos:
    # {
    #     "split": "train",
    #     "index": 0,
    #     "time_asked": "2023-12-31 00:00:00",
    #     "gap": 1,
    #     "question_type": "stock_stats",
    #     "std": 355.12,
    #     "id": "c16c4a04-5501-491c-a127-3a9a2fe951cb"
    # }

    max_date_time = datetime.strptime(extra_info['time_asked'], '%Y-%m-%d %H:%M:%S')
    tool_calls = []

    # tool_calls = extract_tool_call(solution_str)
    # for tool_call in tool_calls:
    #     tool_call = json.loads(tool_call)
    #     for key, value in tool_call.get('arguments').items():
    #         if 'date' in key:
    #             try:
    #                 date_time = datetime.strptime(value, '%Y-%m-%d')
    #             except ValueError:
    #                 date_time = datetime.strptime(value, '%Y-%m-%d %H:%M:%S')
    #             if date_time > max_date_time + timedelta(days=1):
    #                 return -1
    
    # answer = extract_answer(solution_str)
    answer = solution_str.split("</think>")[-1].strip()
    
    mean, std = extract_numerical_answer(answer)
    
    if mean is None or std is None:
        return - 1
    
    gt_mean = ground_truth['mean']
    gt_std = ground_truth['std']

    print(f"### Extracted answer: mean={mean}, std={std}, ground_truth_mean={gt_mean}, ground_truth_std={gt_std}, reward={max( - alpha * nll_exclude_min(mean, std, gt_mean, gt_std) + 1, -1)}")
    
    print('### Reward:', nll_exclude_min(mean, std, gt_mean, gt_std))

    return chi2_pdf(len(tool_calls)) + max( - alpha * nll_exclude_min(mean, std, gt_mean, gt_std) + 1, -1)
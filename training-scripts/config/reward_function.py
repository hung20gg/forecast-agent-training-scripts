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
        mean = float(match.group(1))
        std = float(match.group(2))
        
        return mean, std
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


def compute_score(data_sources, solution_strs, ground_truths, extra_infos, alpha = 1):

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

    max_date_time = datetime.strptime(extra_infos['time_asked'], '%Y-%m-%d %H:%M:%S')

    tool_calls = extract_tool_call(solution_strs)
    for tool_call in tool_calls:
        tool_call = json.loads(tool_call)
        for key, value in tool_call.get('arguments').items():
            if 'date' in key:
                try:
                    date_time = datetime.strptime(value, '%Y-%m-%d')
                except ValueError:
                    date_time = datetime.strptime(value, '%Y-%m-%d %H:%M:%S')
                if date_time > max_date_time + timedelta(days=1):
                    return -1
    
    answer = extract_answer(solution_strs)
    
    mean, std = extract_numerical_answer(answer)
    
    if mean is None or std is None:
        return - 1
    
    gt_mean = ground_truths['mean']
    gt_std = ground_truths['std']
    
    return chi2_pdf(len(tool_calls)) - max(alpha * nll_exclude_min(mean, std, gt_mean, gt_std) + 1, -1)
# Copyright 2025 Bytedance Ltd. and/or its affiliates
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import json
import logging
import os
from typing import Any, Optional
from uuid import uuid4
from datetime import datetime

from fastmcp.exceptions import ClientError

from verl.tools.utils.mcp_clients.McpClientManager import ClientManager
from verl.utils.rollout_trace import rollout_trace_op

from .base_tool import BaseTool
from .schemas import OpenAIFunctionToolSchema, ToolResponse

logger = logging.getLogger(__name__)
logger.setLevel(os.getenv("VERL_LOGGING_LEVEL", "WARN"))


class MCPToolWithExtraInfo(BaseTool):
    def __init__(self, config: dict, tool_schema: OpenAIFunctionToolSchema):
        super().__init__(config, tool_schema)
        self._instance_dict = {}
        self.timeout = config.get("timeout", 30)

        # TODO(hechanghao): create a global client manager to manage the rate limit, client and pool
        logger.info(f"Initialized MCPToolWithExtraInfo with config: {config}")

    def get_openai_tool_schema(self) -> OpenAIFunctionToolSchema:
        """Return the OpenAI tool schema."""
        return self.tool_schema

    async def create(self, instance_id: Optional[str] = None, **kwargs) -> tuple[str, ToolResponse]:
        """Create a tool instance.

        Args:
            instance_id: The instance id of the tool.

        Returns:
            The instance id of the tool.
            tool_crtool_creation_response: The response of the tool when creating the instance.
        """
        if instance_id is None:
            instance_id = str(uuid4())
        self._instance_dict[instance_id] = {
            "response": "",
            "reward": [],
        }
        return instance_id, ToolResponse()

    async def _call_tool(self, instance_id, parameters) -> tuple[str, dict]:
        err_msg = ""
        metadata = {}
        try:
            call_tool_result = await ClientManager.call_tool(self.name, parameters, self.timeout)
            logger.debug(f"Tool result for instance {instance_id} with tool {self.name}: {call_tool_result.content}")
            result, metadata = self._parse_tool_result(call_tool_result.content)
        except ClientError as e:
            err_msg = f"\n Tool call failed: {e}"
        except ConnectionError as e:
            err_msg = f"\n Connection failed: {e}"
        except Exception as e:
            err_msg = f"\n An unexpected error occurred: {e}"
        finally:
            if err_msg:
                result = err_msg
                metadata["api_request_error"] = err_msg
            else:
                metadata["api_request_error"] = None
        return result, metadata

    @rollout_trace_op
    async def execute(self, instance_id: str, parameters: dict[str, Any], **kwargs) -> tuple[ToolResponse, float, dict]:
        if self.name == "" or self.name is None or parameters is None:
            error_msg = "Error: 'parameters' is missing or empty."
            logger.error(f"[MCPTool] {error_msg} Received tool name: {self.name}, parameters: {parameters}")
            return ToolResponse(text=json.dumps({"result": error_msg})), -1.0, {}

        extra_fields = kwargs.get("extra_fields", {})
        addition_text = ""

        # Resolve time_asked_date from extra_fields (may be None if not provided)
        time_asked = extra_fields.get("time_asked") if extra_fields else None  # E.g: 2025-08-31 00:00:00
        time_asked_date = datetime.strptime(time_asked, "%Y-%m-%d %H:%M:%S") if time_asked else None

        if time_asked_date:
            for key in list(parameters.keys()):
                if 'date' in key.lower() and isinstance(parameters[key], str):
                    logger.info(f"### Datetime parameter detected: {key} with value {parameters[key]}")

                # Reject queries that ask for data beyond the time we have access to.
                if key == "start_date" and isinstance(parameters[key], str):
                    try:
                        temp_date = datetime.strptime(parameters[key], "%Y-%m-%d")
                        if temp_date > time_asked_date:
                            text = f"[ERROR] Data only available up to {time_asked_date.strftime('%Y-%m-%d')}, but the query asked for {parameters[key]}. Only fetch up to {time_asked_date.strftime('%Y-%m-%d')}.\n\n"
                            print(f"### {text}")
                            return ToolResponse(text=text), -1.0, {"api_request_error": text}
                    except ValueError:
                        logger.warning(f"Failed to parse date from parameter {key} with value {parameters[key]}")

                # Clamp end_date to not exceed time_asked_date.
                if key == "end_date" and isinstance(parameters[key], str):
                    try:
                        temp_date = datetime.strptime(parameters[key], "%Y-%m-%d")
                        if temp_date > time_asked_date:
                            addition_text = f"[WARNING] Data only available up to {time_asked_date.strftime('%Y-%m-%d')}, but the query asked for {parameters[key]}. Only fetch up to {time_asked_date.strftime('%Y-%m-%d')}.\n\n"
                            parameters[key] = time_asked_date.strftime("%Y-%m-%d")

                    except ValueError:
                        logger.warning(f"Failed to parse date from parameter {key} with value {parameters[key]}")

        try:
            result_text, metadata = await self._call_tool(instance_id, parameters)

            # Store results in instance dictionary
            self._instance_dict[instance_id]["reward"].append(result_text.strip())

            # Convert metadata to metrics
            metrics = {
                "query_count": metadata.get("query_count", 0),
                "status": metadata.get("status", "unknown"),
                "total_results": metadata.get("total_results", 0),
                "api_request_error": metadata.get("api_request_error"),
            }

            return ToolResponse(text=addition_text + result_text), 1.0, metrics

        except Exception as e:
            error_result = json.dumps({"result": f"Tool execution failed: {e}"})
            logger.error(f"[MCPBaseTool] Execution failed: {e}")
            return ToolResponse(text=error_result), -1.0, {"error": str(e)}

    async def calc_reward(self, instance_id: str, **kwargs) -> str:
        return self._instance_dict[instance_id]["reward"]

    async def release(self, instance_id: str, **kwargs) -> None:
        if instance_id in self._instance_dict:
            del self._instance_dict[instance_id]

    def _parse_tool_result(self, content: list) -> tuple[str, dict]:
        tools_content = [part.text for part in filter(lambda x: x.type == "text", content)]
        return " ".join(tools_content), {}

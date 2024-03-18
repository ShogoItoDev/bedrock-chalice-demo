from chalice import Chalice

app = Chalice(app_name='demo-app')

import boto3
import json

bedrock_runtime = boto3.client('bedrock-runtime')

@app.route('/{prompt}', methods=['POST'])
def generate(prompt):
  body = json.dumps({
    "prompt": "\n\nHuman:" + prompt + "\n\nAssistant:",
    "max_tokens_to_sample": 300
  })
  
  modelId = 'anthropic.claude-v2:1'
  accept = 'application/json'
  contentType = 'application/json'
  
  response = bedrock_runtime.invoke_model(body=body, modelId=modelId, accept=accept, contentType=contentType)
  response_body = json.loads(response.get('body').read())
  
  return(response_body.get('completion'))
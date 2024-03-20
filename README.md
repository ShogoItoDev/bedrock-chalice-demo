# はじめに
- 本レポジトリの内容は作成者が個人的に考案・作成したものであり、所属組織等を代表するものではありません。
- 本レポジトリは検証目的であり、利用による損害等の発生には対応致しかねます。

# このレポジトリの目的
AWS Bedrockの導入において、以下を実現したいケースを想定する
- セキュリティ上の理由から、特定のVPCからのみアクセス可能なクローズドのAPIとしたい
- ガバナンス上の理由から、モデルに対する入力および応答内容を長期ログ保管したい

こうしたケースを想定し、以下のアーキテクチャパターンを検討してみる
- 共通基盤となるVPCを1つ作成し、APIの呼び出し口となるVPCエンドポイントを設置する。API Gatewayのリソースポリシーで、このVPCエンドポイントを経由したアクセスのみを許可する
- API GatewayからLambdaを発火し、入力内容（プロンプト）をBedrockに受け渡す。
- Bedrock（今回はClaude V2）が応答を返す。この入力内容と応答内容をセットで、CloudWatch LogsおよびS3に保管する。

## 構成図

## 使い方

### infra/variables.tfで、以下の値を必要に応じて変更

  - system_name（システム名）
  - environment（環境種別）
  - vpc_cidr（VPCのアドレス範囲）

### terraform applyを実行

```
cd infra
terraform apply
```
  
  
### demo-app/.chalice/config.jsonで、以下の箇所を変更

  - api_gateway_endpoint_vpce: 上で作成されたVPCエンドポイントのIDを入力

### chalice deployを実行後、作成されたAPI GatewayのURLに対し、プロンプトを入力

#### 入力例
```
curl -X https://xxxxxxx.execute-api.ap-northeast-1.amazonaws.com/api/generate/Hello
```
## ポイント
  - API Gatewayのタイプが「プライベート」のため、インターネットからはアクセスできない。
  - 指定のVPCエンドポイントからのみアクセスを許可するAPIGWのリソースポリシーがChaliceにより設定され、指定以外のVPCエンドポイント経由でもアクセスできない
    - 単に「API GWのタイプがプライベートである」だけでは、他AWSアカウントのVPCエンドポイント経由でもアクセスできてしまうので、必ずaws:SourceVpceの指定が必要。
    - 参考：https://dev.classmethod.jp/articles/private-api-is-not-private-for-you/

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "execute-api:Invoke",
      "Resource": "arn:*:execute-api:*:*:*",
      "Condition": {
        "StringEquals": {
          "aws:SourceVpce": "vpce-xxxxxxxxxxxxxxx"
        }
      }
    }
  ]
}
```

### 出力されるログのスキーマ
- infra/bedrock-logging.tfで作成したS3バケットおよびCW Logsグループに、プロンプトの入出力内容が保管されるので、保管期間等は転送先で必要に応じ変更する
   - 入力したテキスト（Claude V2の場合）: input > inputBodyJson > prompt
   - 出力されたテキスト（Claude V2の場合）: output > outputBodyJson > completion

```
{
    "schemaType": "ModelInvocationLog",
    "schemaVersion": "1.0",
    "timestamp": "xxxxxxxxxxxxxxxxxxxxxxx",
    "accountId": "xxxxxxxxxxxxxxxxxxxxxxx",
    "identity": {
        "arn": "xxxxxxxxxxxxxxxxxxxxxxx"
    },
    "region": "ap-northeast-1",
    "requestId": "xxxxxxxxxxxxxxxxxxxxxxx",
    "operation": "InvokeModelWithResponseStream",
    "modelId": "anthropic.claude-v2:1",
    "input": {
        "inputContentType": "application/json",
        "inputBodyJson": {
            "prompt": "\n\nHuman: Hello\n\nAssistant:",
            "max_tokens_to_sample": 300,
            "temperature": 1,
            "top_k": 250,
            "top_p": 0.999,
            "stop_sequences": [
                "\n\nHuman:"
            ],
            "anthropic_version": "bedrock-2023-05-31"
        },
        "inputTokenCount": 10
    },
    "output": {
        "outputContentType": "application/json",
        "outputBodyJson": [
            {
                "completion": " Hello",
                "stop_reason": null,
                "stop": null
            },
            {
                "completion": "!",
                "stop_reason": null,
                "stop": null
            },
            {
                "completion": "",
                "stop_reason": "stop_sequence",
                "stop": "\n\nHuman:",
                "amazon-bedrock-invocationMetrics": {
                    "inputTokenCount": 10,
                    "outputTokenCount": 6,
                    "invocationLatency": 765,
                    "firstByteLatency": 690
                }
            }
        ],
        "outputTokenCount": 6
    }
}
```

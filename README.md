![Github Created At](https://img.shields.io/github/created-at/ShogoItoDev/bedrock-chalice-demo)


# はじめに
- 本レポジトリは作成者が個人的に考案・作成したものであり、所属組織等を代表するものではありません。
- 本レポジトリは検証目的であり、利用による損害等の発生には対応致しかねます。
- 参考にした文献・Webサイトは脚注に記載しています（2024/3閲覧）

# 本レポジトリの目的
AWS Bedrockの導入において、以下を実現したいケースを想定する
- セキュリティ上の理由から、特定のVPCからのみアクセス可能なクローズドのAPIとしたい
- ガバナンス上の理由から、モデルに対する入力および応答内容を長期ログ保管したい

こうしたケースを想定し、以下のアーキテクチャパターンを検討してみる
- 共通基盤となるVPCを1つ作成し、APIの呼び出し口となるVPCエンドポイントを設置する。API Gatewayのリソースポリシーで、このVPCエンドポイントを経由したアクセスのみを許可する
- API GatewayからLambdaを発火し、入力内容（プロンプト）をBedrockに受け渡す（今回はここのロジックの作り込みは必要最小限）
- Bedrock（今回はClaude V2.1）が応答を返す。この入力内容と応答内容をセットで、CloudWatch LogsおよびS3に保管する。

# 構成図
![diagram](https://github.com/ShogoItoDev/bedrock-chalice-demo/assets/30908643/b7052ce6-56f6-40c3-8b85-130dfcc1a771)



# 使い方

## 前提条件
- Terraformがインストールされていること
- AWS Chaliceがインストールされていること[^1]

## infra/variables.tfで、以下の値を必要に応じて変更

  - system_name（システム名）
  - environment（環境種別）
  - vpc_cidr（VPCのアドレス範囲）

## terraform applyを実行

```
cd infra
terraform init
terraform apply

<Output>
private_api_gateway_vpce_id = "vpce-xxxxxxxxxxxx"
```

  
  
## demo-app/.chalice/config.jsonで、以下の箇所を変更

  - api_gateway_endpoint_vpce: Outputで出力されたVPCエンドポイントのIDを入力

## chalice deployを実行

```
cd demo-app
chalice deploy

<OutPut>
Rest API URL: https://xxxxxxx.execute-api.ap-northeast-1.amazonaws.com/api/
```

## 同じVPCに作成された「ec2-bedrock-api-client」にセッションマネージャーでログインし、プロンプトを入力

### 入力例
```
curl -X POST https://xxxxxxx.execute-api.ap-northeast-1.amazonaws.com/api/generate/Hello
```
# ポイント
  - API Gatewayのタイプが「プライベート」のため、インターネットからはアクセスできない。
  - VPCエンドポイントのセキュリティグループで以下のインバウンドルールを許可する。
    - タイプ：HTTPS
    - ソース：許可したいIPアドレス等。今回は、アクセス元となるEC2と同一のセキュリティグループを指定
  - 指定のVPCエンドポイントからのみアクセスを許可するAPIGWのリソースポリシーがChaliceにより設定され、指定以外のVPCエンドポイント経由でもアクセスできない
    - 単に「API GWのタイプがプライベートである」だけでは、他AWSアカウントのVPCエンドポイント経由でもアクセスできてしまうので、必ずaws:SourceVpceの指定が必要[^2]。
    
<details>

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
</details>

## 基盤モデルの利用に必要なIAMポリシー

- Bedrockの基盤モデルでの推論には以下のアクションの許可が必要[^3]

<details>
      
```
  {
    "Version": "2012-10-17",
    "Statement": {
        "Effect": "Allow",
        "Action": [
            "bedrock:InvokeModel",
            "bedrock:InvokeModelWithResponseStream"
         ],
        "Resource": "arn:aws:bedrock:<region>::foundation-model/<model-id>"
    }
}        
```

- アクセスを許可する対象の基盤モデルのARNおよびモデルIDは、以下のコマンドで取得できる。
  
```
aws bedrock list-foundation-models
```

- 例えば、Anthropic Claude V2.1のモデルARN・IDは下記になる（東京リージョンの場合）
  
```
"modelArn": "arn:aws:bedrock:ap-northeast-1::foundation-model/anthropic.claude-v2:1"
"modelId" : "anthropic.claude-v2:1"
```
</details>

## ロギングに必要なIAMポリシー・バケットポリシー

- AWSマネジメントコンソールでは[設定]から変更する
- マネジメントコンソールでは少々分かりづらいが、CloudWatch Logsに対する権限はサービスロールを、S3に対する権限はバケットポリシーを利用する

![bedrock-logging](https://github.com/ShogoItoDev/bedrock-chalice-demo/assets/30908643/2a78c5ed-0a8d-41cc-8a1b-b9b597f114d9)


## CloudWatch Logsへのロギングを許可するIAMポリシーの記載例[^4]

<details>

- 信頼ポリシー

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "bedrock.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "<accountId>" 
        },
        "ArnLike": {
          "aws:SourceArn": "arn:aws:bedrock:<region>:<accountId>:*"
        }
      }
    }
  ]
}
```

- 許可内容
```
{
    "Version": "2012-10-17", 
    "Statement": [ 
        {
            "Effect": "Allow", 
            "Action": [ 
                "logs:CreateLogStream", 
                "logs:PutLogEvents" 
            ], 
            "Resource": "arn:aws:logs:region:<accountId>:log-group:<logGroupName>:log-stream:aws/bedrock/modelinvocations" 
         } 
    ]
}
```
</details>

## S3へのロギングを許可するバケットポリシーの記載例[^5]

<details>

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AmazonBedrockLogsWrite",
      "Effect": "Allow",
      "Principal": {
        "Service": "bedrock.amazonaws.com"
      },
      "Action": [
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::<bucketName>/<prefix>/AWSLogs/<accountId>/BedrockModelInvocationLogs/*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "<accountId>" 
        },
        "ArnLike": {
           "aws:SourceArn": "arn:aws:bedrock:<region>:<accountId>:*"
        }
      }
    }
  ]
}
```
</details>

## 出力されるログのスキーマ
- infra/bedrock-logging.tfで作成したS3バケットおよびCW Logsグループに、プロンプトの入出力内容が保管されるので、保管期間等は転送先で必要に応じ変更する
   - 入力したテキスト（Claude V2の場合）: input > inputBodyJson > prompt
   - 出力されたテキスト（Claude V2の場合）: output > outputBodyJson > completion

<details>

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
</details>

# 改善点

## Bedrock側のリソースポリシーで、より厳密にアクセス制御できないか
- 例として「指定したLambda関数のARNからのみ基盤モデルの実行を許可する（それ以外はDenyする）」ようなリソースポリシーが掛けられないかと考えた。本記事の執筆時点（2024/3）では、Bedrockはリソースベースのポリシーに未対応[^6]

## Lambda関数自体をVPC内部に配置できないか
- Bedrock特有というよりAPI Gateway+Lambdaのアーキテクチャの観点になるが、API GatewayがプライベートであってもLambda関数自体が非VPCであるのが懸念となる場合。今回は検証外としたが、API GatewayのVPCリンクを採用すればVPC Lambdaも併用可能と考えられるので追加検証したい。
- ただし、VPCリンクのターゲットとなるのはNLBで、ALBは利用できない。かつ、NLBのターゲットとしてLambda関数は登録できない（2024/3時点）。そのため、まず「ALBのターゲットグループにLambda関数を登録」し「そのALBをNLBのターゲットグループとして登録」、最後に「そのNLBとAPI GatewayでVPCリンクを作成」となると考えられる[^7][^8]

[^1]:https://aws.github.io/chalice/quickstart.html
[^2]:https://dev.classmethod.jp/articles/private-api-is-not-private-for-you/
[^3]:https://docs.aws.amazon.com/ja_jp/bedrock/latest/userguide/security_iam_id-based-policy-examples.html#security_iam_id-based-policy-examples-deny
[^4]:https://docs.aws.amazon.com/ja_jp/bedrock/latest/userguide/model-invocation-logging.html#setup-cloudwatch-logs-destination
[^5]:https://docs.aws.amazon.com/ja_jp/bedrock/latest/userguide/model-invocation-logging.html#setup-s3-destination
[^6]:https://docs.aws.amazon.com/ja_jp/bedrock/latest/userguide/security-iam.html
[^7]:https://qiita.com/fkooo/items/577831abd9803eb91b16
[^8]:https://dev.classmethod.jp/articles/alb-type-target-group-for-nlb/

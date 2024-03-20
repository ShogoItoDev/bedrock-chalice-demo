# このレポジトリの目的
AWS Bedrockの導入において、以下を実現したいケースを想定する
- セキュリティ上の理由から、特定のVPCからのみアクセス可能なクローズドのAPIとしたい
- ガバナンス上の理由から、モデルに対する入力および応答内容を長期ログ保管したい

こうしたケースを想定し、以下のアーキテクチャパターンを検討してみる
- 共通基盤となるVPCを1つ作成し、APIの呼び出し口となるVPCエンドポイントを設置する。API Gatewayのリソースポリシーで、このVPCエンドポイントを経由したアクセスのみを許可する
- API GatewayからLambdaを発火し、入力内容（プロンプト）をBedrockに受け渡す。
- Bedrock（今回はClaude V2）が応答を返す。この入力内容と応答内容をセットで、CloudWatchおよびS3に保管する。
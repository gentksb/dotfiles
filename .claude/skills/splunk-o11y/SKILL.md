---
name: splunk-o11y
description: Splunk Observability Cloud APM APIを使用してサービストポロジーとトレースを取得・分析するためのスキル。デバッグ時の問題特定、サービス依存関係の調査、環境別のサービス比較に使用。トレースID、サービス名、APM、依存関係、トポロジーなどのキーワードで起動。
---

# Splunk Observability Cloud APM

Splunk Observability CloudのAPM APIを使用してサービストポロジーとトレースを取得する。

## 環境設定

以下の環境変数を設定:

```bash
export SF_TOKEN="your-api-token"    # 必須: Organization Access Token
export SF_REALM="us1"               # オプション: realm (デフォルト: us1)
```

REALMが未設定の場合、スクリプト実行時に確認する。

## サービストポロジー取得

`--environment` にはアプリケーションで設定している環境名（`deployment.environment` 属性の値）を指定する。以下の `production` は例であり、実際の環境名に置き換えること。

### 全サービスのトポロジー

```bash
python scripts/get_topology.py --environment production
```

### 特定サービスの依存関係

```bash
python scripts/get_topology.py --environment production --service my-service
```

### 時間範囲を指定

```bash
python scripts/get_topology.py --environment production \
    --start-time 2024-01-01T00:00:00Z \
    --end-time 2024-01-01T12:00:00Z
```

## トレース取得

### トレースIDから最新スパンを取得

```bash
python scripts/get_trace.py <trace-id>
```

### セグメント一覧を取得

```bash
python scripts/get_trace.py <trace-id> --segments
```

### 特定セグメントのスパンを取得

```bash
python scripts/get_trace.py <trace-id> --segment-timestamp 1704067200000000
```

## デバッグワークフロー

1. **問題のトレースを特定**: トレースIDを取得
2. **トレース詳細を取得**: `get_trace.py` でスパン一覧を確認
3. **関連サービスを特定**: スパンの `serviceName` を確認
4. **サービス依存関係を調査**: `get_topology.py --service <name>` で上流・下流を確認
5. **環境比較**: 異なる `--environment` で結果を比較

## APIリファレンス

- 概要・使用例: [references/api_reference.md](references/api_reference.md)
- OpenAPI定義（詳細）:
  - [references/apm_service_topology-latest.json](references/apm_service_topology-latest.json)
  - [references/trace_id-latest.json](references/trace_id-latest.json)

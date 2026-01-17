# PostgreSQL Backup to S3

PostgreSQL データベースのバックアップを取得し、Amazon S3 にアップロードする Docker イメージです。

## タグ命名規則

- `ghcr.io/<repo>/pg-dump-to-s3:v1.2.0-pg14` - PostgreSQL 14 版
- `ghcr.io/<repo>/pg-dump-to-s3:v1.2.0-pg15` - PostgreSQL 15 版
- `ghcr.io/<repo>/pg-dump-to-s3:v1.2.0-pg16` - PostgreSQL 16 版
- `ghcr.io/<repo>/pg-dump-to-s3:v1.2.0-pg17` - PostgreSQL 17 版
- `ghcr.io/<repo>/pg-dump-to-s3:latest-pg16` - 最新版 (PostgreSQL 16)

## 環境変数

| 変数名 | 必須 | デフォルト値 | 説明 |
|--------|------|-------------|------|
| `DB_HOST` | Yes | - | データベースのホスト名 |
| `DB_PORT` | Yes | 5432 | データベースのポート |
| `DB_USER` | Yes | - | データベースのユーザー名 |
| `DB_PASSWORD` | Yes | - | データベースのパスワード |
| `DB_NAME` | Yes | - | バックアップするデータベース名 |
| `BACKUP_NAME` | Yes | - | バックアップファイル名（拡張子なし、例: `daily_backup`） |
| `BUCKET_NAME` | Yes* | - | S3 バケット名（`SKIP_S3_UPLOAD=false`時は必須） |
| `BUCKET_DIR` | Yes* | - | S3 バケット内のディレクトリ/プレフィックス（`SKIP_S3_UPLOAD=false`時は必須） |
| `SKIP_S3_UPLOAD` | No | false | S3 アップロードをスキップするかどうか |
| `AWS_ACCESS_KEY_ID` | No | - | AWS アクセスキー |
| `AWS_SECRET_ACCESS_KEY` | No | - | AWS シークレットキー |
| `AWS_REGION` | No | - | AWS リージョン |
| `BUCKET_URL` | No | - | カスタム S3 エンドポイント URL (MinIOなど) |

## 使用例

### 基本的な使用方法

```bash
docker run --rm \
  -e DB_HOST=db.example.com \
  -e DB_PORT=5432 \
  -e DB_USER=postgres \
  -e DB_PASSWORD=secret \
  -e DB_NAME=mydb \
  -e BACKUP_NAME=daily_backup \
  -e BUCKET_NAME=my-backup-bucket \
  -e BUCKET_DIR=postgres/ \
  -e AWS_ACCESS_KEY_ID=AKIA... \
  -e AWS_SECRET_ACCESS_KEY=secret \
  -e AWS_REGION=us-east-1 \
  ghcr.io/<repo>/pg-dump-to-s3:v1.2.0-pg16
```

### IAM ロールを使用 (AWS EC2 / ECS / EKS)

```bash
docker run --rm \
  -e DB_HOST=db.example.com \
  -e DB_PORT=5432 \
  -e DB_USER=postgres \
  -e DB_PASSWORD=secret \
  -e DB_NAME=mydb \
  -e BACKUP_NAME=daily_backup \
  -e BUCKET_NAME=my-backup-bucket \
  -e BUCKET_DIR=postgres/ \
  -e AWS_REGION=us-east-1 \
  --network host \
  ghcr.io/<repo>/pg-dump-to-s3:v1.2.0-pg16
```

### MinIO などの互換 S3 を使用

```bash
docker run --rm \
  -e DB_HOST=db.example.com \
  -e DB_PORT=5432 \
  -e DB_USER=postgres \
  -e DB_PASSWORD=secret \
  -e DB_NAME=mydb \
  -e BACKUP_NAME=daily_backup \
  -e BUCKET_NAME=my-backup-bucket \
  -e BUCKET_DIR=postgres/ \
  -e BUCKET_URL=http://minio:9000 \
  -e AWS_ACCESS_KEY_ID=minioadmin \
  -e AWS_SECRET_ACCESS_KEY=minioadmin \
  ghcr.io/<repo>/pg-dump-to-s3:v1.2.0-pg16
```

## バックアップ検証

このイメージは、S3 にアップロードする前に以下の検証を行います：

1. **ファイルサイズチェック**: バックアップファイルのサイズを確認
2. **署名チェック**: ファイルが有効な PostgreSQL ダンプであることを確認（`PostgreSQL database dump` 文字列のチェック）
3. **SQL ステートメントチェック**: ダンプに有効な SQL ステートメント（`SET` コマンドなど）が含まれていることを確認

## 開発とテスト

```bash
# テスト環境を構築
docker compose -f docker-compose.test.yml up -d

# テスト実行（S3 アップロードをスキップ）
docker build -t pg-dump-to-s3:test .
docker run --rm \
  --network container:test-postgres \
  -e DB_HOST=localhost \
  -e DB_PORT=5432 \
  -e DB_USER=postgres \
  -e DB_PASSWORD=testpass \
  -e DB_NAME=testdb \
  -e BACKUP_NAME=test_backup \
  -e SKIP_S3_UPLOAD=true \
  pg-dump-to-s3:test

# 後片付け
docker compose -f docker-compose.test.yml down -v
```

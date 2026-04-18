@echo off
REM 本番（Fly）でユーザーを管理者にし、そのユーザー配下のプリセット／バージョン／リポジトリを official に一括更新します。
REM 第1引数に、サイトに登録済みのメールアドレスを必ず指定してください（リポジトリにメールを書き込まないため）。
set "EMAIL=%~1"
if "%EMAIL%"=="" (
  echo 使い方: %~nx0 ^<登録済みユーザーのメールアドレス^>
  echo 例: %~nx0 user@example.com
  exit /b 1
)
echo Fly app promptlore: %EMAIL% を昇格します ...
call "%~dp0fly.cmd" ssh console -a promptlore --pty=false -C "/bin/sh -c \"cd /rails; EMAIL=%EMAIL% bin/rake ops:promote_official_user\""

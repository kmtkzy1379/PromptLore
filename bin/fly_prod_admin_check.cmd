@echo off
REM Ruby avoids "(" after where/pluck so cmd.exe does not mangle the -C string.
REM Exit code 1 + "The handle is invalid" on Windows is a known fly ssh quirk; read the printed lines.
echo === Production DB snapshot ===
call "%~dp0fly.cmd" ssh console -a promptlore --pty=false -C "/bin/sh -c \"cd /rails; bin/rails runner \\\"r=User.where 'admin = ?', true; puts :admins; p r.pluck 'id', 'email', 'username'; r2=Preset.where 'official = ?', true; puts :official_presets; p r2.pluck 'id', 'name', 'user_id'\\\"\""

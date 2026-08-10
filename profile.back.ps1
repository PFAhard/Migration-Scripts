# Instead of Path
function cl {
  & "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Tools\MSVC\14.51.36231\bin\Hostx64\x64\cl.exe" @args
}

# ssh array
function germany {
 ssh root@5.104.75.131
}
function pihole {
 ssh pfapostol@pi.hole
}

# goto array
function slcode {
 param([string]$subdir)

 if ($subdir) {
 Set-Location (Join-Path "Z:\code" $subdir)
 } else {
 Set-Location "Z:\code"
 }
}
function work {
 param([string]$subdir)

 if ($subdir) {
 Set-Location (Join-Path "Z:\work" $subdir)
 } else {
 Set-Location "Z:\work"
 }
}

Register-ArgumentCompleter -CommandName slcode -ParameterName subdir -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)
    $base = "Z:\code"
    Get-ChildItem -Path "$base\$wordToComplete*" -Directory -ErrorAction SilentlyContinue |
        ForEach-Object {
            $_.Name
        }
}

Register-ArgumentCompleter -CommandName work -ParameterName subdir -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)
    $base = "Z:\work"
    Get-ChildItem -Path "$base\$wordToComplete*" -Directory -ErrorAction SilentlyContinue |
        ForEach-Object {
            $_.Name
        }
}


function slpiper {
 Set-Location Z:\piper_home
}
function slwhisper {
 Set-Location Z:\whisper_home
}
function slllama{
 Set-Location Z:\llama_home
}
function slgames {
 Set-Location C:\Games
}
function sllocal {
 Set-Location C:\Users\pfapostol\AppData\Local
}
function slroaming {
 Set-Location C:\Users\pfapostol\AppData\Roaming
}

# Docker Array
function foundry-docker {
 docker run --rm -v ${PWD}:/project -it foundry-image:latest $args
}


# AI ARRAY
function ullama.cpp.Qwen3.5 {
 llama-cli.exe -hf unsloth/Qwen3.5-9B-GGUF:Q4_K_M -ngl 999 -fa on -t 8 -tb 8 --prio 2 -ctk q8_0 -ctv q8_0 -c 4096 -fit on -fitt 512 --temp 0.7 --min-p 0.05 --top-k 40 --top-p 0.95 --repeat-penalty 1.15 -cnv
}
function ullama-server.cpp.Qwen3.5 {
 llama-server.exe -hf unsloth/Qwen3.5-9B-GGUF:Q4_K_M -ngl 999 -fa on -t 8 -tb 8 --prio 2 -ctk q8_0 -ctv q8_0 -fit on -fitt 512 --temp 0.7 --min-p 0.05 --top-k 40 --top-p 0.95 --repeat-penalty 1.15 --jinja -c 0 --host 127.0.0.1 --port 8033 --ctx-size 8192 --parallel 1 --cache-type-k q4_0 --cache-type-v q4_0 --ubatch-size 256
}

function ullama-server.cpp.Qwen3.5Pi {
 llama-server.exe -hf unsloth/Qwen3.5-9B-GGUF:Q4_K_M -ngl 999 -fa on -t 8 -tb 8 --prio 2 -ctk q8_0 -ctv q8_0 -fit on -fitt 512 --temp 0.7 --min-p 0.05 --top-k 40 --top-p 0.95 --repeat-penalty 1.15 --jinja -c 0 --host 127.0.0.1 --port 8033 --ctx-size 16384 --parallel 1 --cache-type-k q4_0 --cache-type-v q4_0 --ubatch-size 256
}

function ullama-server.cpp.Qwen3.5.BigC {
 llama-server.exe -hf unsloth/Qwen3.5-9B-GGUF:Q4_K_M -ngl 999 -fa on -t 8 -tb 8 --prio 2 -ctk q8_0 -ctv q8_0 -fit on -fitt 512 --temp 0.7 --min-p 0.05 --top-k 40 --top-p 0.95 --repeat-penalty 1.15 --jinja -c 0 --host 127.0.0.1 --port 8033 --ctx-size 32768 --parallel 1 --cache-type-k q4_0 --cache-type-v q4_0 --ubatch-size 256
}
function ullama-server.cpp.Qwen3.5.BigCx4 {
 llama-server.exe -hf unsloth/Qwen3.5-9B-GGUF:Q4_K_M -ngl 999 -fa on -t 8 -tb 8 --prio 2 -ctk q8_0 -ctv q8_0 -fit on -fitt 512 --temp 0.7 --min-p 0.05 --top-k 40 --top-p 0.95 --repeat-penalty 1.15 --jinja -c 0 --host 127.0.0.1 --port 8033 --ctx-size 131072 --parallel 1 --cache-type-k q4_0 --cache-type-v q4_0 --ubatch-size 256
}
function ullama-server.cpp.Qwen2.5-Coder {
  llama-server.exe -hf Qwen/Qwen2.5-Coder-7B-Instruct-GGUF:Q5_K_M -ngl 28 -t 8 -tb 8 --prio 2 -ctk q8_0 -ctv q8_0 --temp 0.1 --min-p 0.05 --top-k 40 --top-p 0.9 --repeat-penalty 1.1 --host 127.0.0.1 --port 8033 --ctx-size 8192 --parallel 1 --ubatch-size 512
}
function ullama-server.cpp.SolidityAuditor {
  llama-server.exe -hf mradermacher/solidity-vuln-auditor-7b-GGUF:Q4_K_M -ngl 28 -t 8 -tb 8 --prio 2 -ctk q8_0 -ctv q8_0 --temp 0.1 --min-p 0.05 --top-k 40 --top-p 0.9 --repeat-penalty 1.1 --host 127.0.0.1 --port 8033 --ctx-size 8192 --parallel 1 --ubatch-size 512
}
function TTS-8Q {
 llama-server.exe -hf unsloth/orpheus-3b-0.1-ft-GGUF:UD-Q8_K_XL --ctx-size 16384 --n-predict 4096 --rope-scaling linear -ngl 99 --host 127.0.0.1 --port 8080
}

function TTS {
  llama-server.exe -hf unsloth/orpheus-3b-0.1-ft-GGUF:Q4_0 --ctx-size 4096 --n-predict 2048 -fa auto --cache-type-k q8_0 --cache-type-v q8_0 --batch-size 512 --ubatch-size 512 --rope-scaling linear -ngl 99 --host 127.0.0.1 --port 8080
}

function ullama-server.cpp.Qwen2.5-Coder.FIM {
  llama-server.exe `
    -hf ggml-org/Qwen2.5-Coder-3B-Q8_0-GGUF `
    -ngl 999 `
    -t 8 -tb 8 `
    --prio 2 `
    --temp 0.0 `
    --repeat-penalty 1.0 `
    --host 127.0.0.1 `
    --port 8034 `
    --ctx-size 4096 `
    --parallel 1 `
    --ubatch-size 512 `
    --n-predict 256
}


function apktool { java -jar "C:\Users\pfapostol\Desktop\AndroidReverse\tools\apktool_3.0.2.jar" @args }


[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null



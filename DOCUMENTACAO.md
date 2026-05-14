<!--
Copyright (c) 2025 Rafael
License: RMR Module License (see LICENSE_RMR)
-->

# Documentação do repositório BLAKE3 (fork distribuído)

## Introdução

Este repositório é uma **distribuição de um fork** do projeto **BLAKE3**
upstream oficial. O nome do projeto permanece **BLAKE3**, e o núcleo
criptográfico é tratado como **referência absoluta** do upstream. Este
repositório **não é afiliado** ao time oficial do BLAKE3; ele apenas
redistribui o código e adiciona uma camada externa isolada para fins
locais de organização e experimentação.

> **Resumo de escopo**
> - **Núcleo BLAKE3**: código upstream original (C, ASM, Rust, vetores
>   de teste e documentação oficial).
> - **Camada externa**: conteúdo adicional isolado em `rmr/` e documentos
>   autorais fora de `rmr/` (ex.: `DOCUMENTACAO.md`, `RELATORIO*.md`).
>   Essa camada **não modifica** o núcleo.

## Camadas e fronteiras

### Núcleo BLAKE3 (upstream)

Componentes que devem permanecer semanticamente idênticos ao upstream:

- `c/` (somente arquivos `blake3*`, `README.md`, `CMakeLists.txt`, etc.).
- `src/` (todos os arquivos Rust do BLAKE3 oficial).
- `reference_impl/` (implementação de referência).
- `test_vectors/` (vetores oficiais e utilitários).
- `README.md` e `LICENSE_*` (documentação e licenças oficiais).
- `b3sum/`, `tools/`, `benches/`, `media/` (conteúdo upstream do projeto).

### Camada externa (autoral / isolada)

Componentes que **não** fazem parte do núcleo BLAKE3 e devem permanecer
separados:

- `rmr/` (documentação, licença e código experimental isolado).
  - `rmr/include/`: headers auxiliares do módulo externo.
  - `rmr/rust/`: módulos Rust externos (não integrados ao crate `blake3`).
  - `rmr/benchmark_framework/`: blueprint do framework de benchmark industrial
    (isolado do core).
- Scripts ou automações específicos (quando existirem) devem evitar
  tocar no núcleo.
- Documentos autorais em raiz (como `DOCUMENTACAO.md`, `RELATORIO.md`,
  `RELATORIO_AUDITORIA.md`, `MANIFESTO*.md`, `FORK_NOTES.md`, `AGENTS.md`)
  também compõem a camada externa e seguem licença RMR.

> **Regra:** código externo **pode usar** o BLAKE3 como biblioteca, mas
> **nunca** deve modificar ou invadir o núcleo.

## Estrutura de diretórios (visão geral)

- `README.md`: README oficial do BLAKE3 upstream.
- `LICENSE_*`: licenças oficiais do upstream.
- `src/`: crate Rust `blake3` (núcleo upstream).
- `b3sum/`: CLI oficial para hashing.
- `c/`: implementação C oficial (SIMD/ASM/dispatch).
- `reference_impl/`: implementação de referência (Rust).
- `test_vectors/`: vetores e utilitários oficiais.
- `benches/`, `tools/`, `media/`: conteúdo upstream.
- `rmr/`: camada externa isolada (ver `rmr/docs/ARCHITECTURE.md`).
- `rmr/benchmark_framework/`: blueprint do framework de benchmark (RMR).
- `rmr/ui/`: camada de front controller (`mode_router`) para modos de execução (`cli`, `helper`, `bbs`) com backend em `pai_main`.
- `rmr/core/validate.c`: validação determinística de invariantes RMR (alpha, atratores, capacidade geométrica e coprimalidade de passos) para uso em runtime sem tocar no núcleo BLAKE3.


## Mapa de identidade de conceitos (estrutura × lógica)

Para evitar a leitura de que o código é “óbvio” sem contexto, este mapa
relaciona **caminhos reais** com o **papel lógico** de cada parte do sistema.
A meta é tornar explícito o que é coletivo no programa (núcleo + interfaces +
camada externa), sem misturar fronteiras.

### 1) Núcleo algorítmico (imutável em relação ao upstream)

- `src/portable.rs`: compressão/rounds portáveis e base sem SIMD específico.
- `src/guts.rs`: regras internas de composição do hash em Rust.
- `src/lib.rs`: API pública do crate `blake3` e composição dos modos.
- `c/blake3.c` e `c/blake3.h`: núcleo C oficial (API/estado/rotinas base).
- `reference_impl/reference_impl.rs`: referência didática mínima do algoritmo.

**Identidade do conceito:** “motor criptográfico” (determinístico, estável,
compatível com vetores oficiais).

### 2) Aceleração por arquitetura (mesma semântica, execução distinta)

- Rust SIMD/FFI: `src/ffi_sse2.rs`, `src/ffi_sse41.rs`, `src/ffi_avx2.rs`,
  `src/ffi_avx512.rs`, `src/ffi_neon.rs`, `src/wasm32_simd.rs`.
- Rust nativo especializado: `src/rust_sse41.rs`, `src/rust_avx2.rs`.
- Detecção/plataforma: `src/platform.rs`.
- C/ASM especializado em `c/` (SSE/AVX/NEON e dispatch).

**Identidade do conceito:** “caminhos de execução equivalentes” (otimização de
hardware sem alterar resultado criptográfico).

### 3) Interface de uso e integração

- `b3sum/src/main.rs`: CLI oficial (uso operacional por arquivo/STDIN).
- `src/io.rs`: suporte de IO para uso incremental.
- `src/traits.rs`: contratos/traits de integração na API Rust.

**Identidade do conceito:** “superfície de consumo” (como o usuário/sistema
acessa o mesmo núcleo).

### 4) Validação, benchmark e garantia de coerência

- `src/test.rs`, `b3sum/tests/cli_tests.rs`: testes de regressão/integração.
- `benches/bench.rs`: medição de desempenho.
- `test_vectors/`: vetores oficiais para conferir equivalência.

**Identidade do conceito:** “prova de coerência” (mesma saída entre caminhos,
plataformas e modos).

### 5) Camada externa RMR (separação explícita)

- `rmr/`: módulos/documentos autorais externos.
- `rmr/PROVENIENCE.md`: fronteira upstream vs externo.
- `tools/check_rmr_headers.py`: verificação de política documental RMR.

**Identidade do conceito:** “governança externa” (organização/auditoria sem
invadir o motor criptográfico).

### Regra prática de leitura do repositório

1. Primeiro identificar a camada: **núcleo**, **aceleração**, **interface**,
   **validação** ou **externa RMR**.
2. Depois avaliar mudança pela pergunta: “altera semântica criptográfica ou
   só forma de execução/organização?”
3. Se tocar semântica do núcleo upstream, a mudança deve ser bloqueada neste
   fork; se for externa, manter isolamento em `rmr/` ou documentação.

## Build e testes (alinhado ao README oficial)

> Os comandos abaixo seguem o README upstream. Consulte `README.md` e
> `c/README.md` para detalhes completos.

### Rust (crate `blake3` e CLI `b3sum`)

```bash
cargo build
cargo test
cargo build -p b3sum
```

### C (implementação oficial)

Siga as instruções em `c/README.md` para compilar e testar.

## Benchmarking (camada RMR, sem tocar no core)

O framework de benchmark **não** altera o núcleo do BLAKE3. Ele fica isolado em
`rmr/benchmark_framework/` e deve consumir o BLAKE3 somente como biblioteca ou
CLI externa. O desenho prevê **duas interfaces obrigatórias**:

- **CLI** (`rmr-bench`): execução automática por parâmetros.
- **BBS/TUI**: interface textual interativa (menus/teclado).

Exemplo de uso esperado (não executado nesta documentação):

```bash
rmr-bench --profile ram --size 4GiB --runs 5 --seed 123
rmr-bench --profile io --file ./big.dat --runs 5 --threads 1
rmr-bench --profile pipeline --runs 5 --save report.json
```

Saídas previstas: JSON, CSV e Markdown, com registro de seed, tamanho, threads,
flags, commit e timestamp.

Armazenamento operacional padrão em `rmr/benchmark_framework/output/`: `run_manifest.json`, `metrics.jsonl` e `summary.json`, incluindo cadeia de custódia (`snapshot_hash`, `output_artifacts`, `prev_run_hash`).



### Fronteira HWIF: fallback compile-time vs detecção runtime

Na camada externa RMR, a fronteira de responsabilidades é explícita:

- **Fallback compile-time**: `rmr/include/rmr_dispatch.h` mantém as
  definições estáticas para ambientes sem sinalização dinâmica.
- **Detecção runtime**: `rmr_get_cpu_caps` / `rmr_detect_cpu_caps`, com
  implementação em `rmr/hwif/detect/detect_x86.c`,
  `rmr/hwif/detect/detect_aarch64.c` e
  `rmr/hwif/detect/detect_fallback.c`, consolidadas pelo contrato
  `rmr/hwif/include/rmr_detect.h`.

Essa divisão preserva a compatibilidade operacional sem alterar o núcleo
criptográfico upstream.

## Política de licença no módulo RMR

No módulo `rmr/`, o arquivo `rmr/LICENSE_RMR` contém **somente** o texto legal
da licença. Conteúdos não jurídicos (manifestos, notas conceituais e blocos
técnicos ilustrativos) ficam separados em `rmr/MANIFESTO_RAFAELIA.md`.

## Proveniência e autoria

Este repositório separa explicitamente o upstream BLAKE3 da camada
externa. O mapa de proveniência oficial está em `rmr/PROVENIENCE.md`.
Qualquer novo arquivo autoral deve ser registrado nesse documento com
origem, licença e finalidade. Itens autorais fora de `rmr/` também são
permitidos quando explicitamente catalogados na seção
"Itens fora de `rmr/` sob autoria externa".


### Licenças por fronteira

- **Upstream BLAKE3** (`src/`, `c/`, `b3sum/`, `reference_impl/`, `test_vectors/`,
  `tools/`, `benches/`, `media/` e metadados oficiais):
  **CC0 1.0 / Apache 2.0 / Apache 2.0 LLVM-exceptions** (conforme `LICENSE_*`).
- **Camada externa autoral** (`rmr/` + documentos autorais fora de `rmr/`):
  **RMR Module License** (`rmr/LICENSE_RMR`).

Esse recorte de fronteira/licença deve permanecer idêntico ao descrito em
`rmr/PROVENIENCE.md`.

As regras para exceções de cabeçalho de licença inline (critérios,
registro obrigatório e fallback documental) estão definidas em
`rmr/docs/ARCHITECTURE.md`, na seção **"Exceções explícitas de cabeçalho inline"**.

## Política de artefatos de build (RMR)

Artefatos de build e arquivos temporários do módulo `rmr/` (por exemplo,
`*.o`, `*.bak` e variantes temporárias) devem ser gerados **apenas localmente**
durante compilação/depuração.

- Esses arquivos **não** fazem parte do código-fonte.
- Esses arquivos **não** devem ser versionados no Git.
- O repositório mantém regras em `.gitignore` para impedir novo versionamento
  acidental desses artefatos.

## Política de cabeçalhos de licença em `rmr/`

Esta política define como declarar copyright/licença em arquivos autorais da
camada externa `rmr/`. As fontes normativas são:

- `rmr/LICENSE_RMR` (texto legal aplicável ao módulo RMR).
- `rmr/PROVENIENCE.md` (classificação upstream vs externo e escopo de autoria).

### Escopo

- Obrigatória para **novos arquivos autorais** dentro de `rmr/`.
- Obrigatória para arquivos existentes em `rmr/` quando forem alterados de forma
  substancial.
- Não se aplica a arquivos upstream fora de `rmr/`.

### Tipos suportados (texto canônico único por extensão)

Em caso de conflito entre exemplos antigos, variações históricas ou comentários
locais, **este texto canônico prevalece**.

Referência cruzada obrigatória de classificação/licença:
`rmr/PROVENIENCE.md`.

#### Campos canônicos obrigatórios

- Autor: `Rafael Melo Reis`
- Intervalo de anos: `2024–2026`
- Frase de licença: `Licensed under LICENSE_RMR.`

#### Templates exatos por extensão suportada

- `*.c`, `*.h`, `*.rs`, `*.s`, `*.S`, `*.inc`, `*.ld`:

  ```text
  /*
   * Copyright (c) 2024–2026 Rafael Melo Reis
   * Licensed under LICENSE_RMR.
   */
  ```

- `*.sh`, `*.bash`, `*.py`, `*.rb`, `*.pl`, `Makefile`, `*.mk`:

  ```text
  # Copyright (c) 2024–2026 Rafael Melo Reis
  # Licensed under LICENSE_RMR.
  ```

- `*.md`, `*.txt`, `*.yaml`, `*.yml`, `*.toml`, `*.json`:

  ```text
  <!--
  Copyright (c) 2024–2026 Rafael Melo Reis
  Licensed under LICENSE_RMR.
  -->
  ```

### Exceções formais

Exceções só são válidas quando documentadas em `rmr/PROVENIENCE.md` com
justificativa explícita:

1. Arquivos de terceiros importados para `rmr/` com licença própria.
2. Arquivos gerados automaticamente cujo formato quebra com comentário de topo.
3. Casos legais/comerciais onde o cabeçalho precisa de texto adicional aprovado.

### Processo de revisão

- Em cada commit/PR que tocar `rmr/`, verificar se o cabeçalho segue o padrão
  por extensão.
- Confirmar que exceções estão registradas em `rmr/PROVENIENCE.md`.
- Reforçar que `rmr/LICENSE_RMR` e `rmr/PROVENIENCE.md` são a referência
  normativa para dúvidas de classificação e licença.
- Executar verificação estática periódica para detectar ausência/inconsistência
  de cabeçalhos no escopo `rmr/`.

### Verificação automática de cabeçalhos RMR

Para contexto de atualização de cabeçalhos/licença e para evitar mudanças fora
de `rmr/`, use o checker abaixo:

- Execução padrão:

  ```bash
  python3 tools/check_rmr_headers.py
  ```

- Execução com whitelist explícita para arquivo fora de `rmr/`:

  ```bash
  python3 tools/check_rmr_headers.py --allow-outside DOCUMENTACAO.md
  ```

Critério de falha: o checker encerra com **exit code não-zero** quando encontra
qualquer violação. As categorias de violação são:

- **OUTSIDE_RMR**: arquivo alterado fora de `rmr/` sem estar na whitelist
  (`--allow-outside`).
- **MISSING_HEADER**: arquivo autoral no escopo `rmr/` sem cabeçalho obrigatório
  de copyright/licença.
- **INVALID_HEADER**: cabeçalho presente, mas fora do padrão aceito por tipo de
  arquivo (comentário/forma/linhas esperadas).
- **PROVENIENCE_GAP**: exceção de cabeçalho/licença não documentada em
  `rmr/PROVENIENCE.md` quando exigido pela política.

## Diferenças vs upstream (revisão atual)

- Adicionado `rmr/include/rmr_governance.h` como contrato de governança
  externo ao core.
- Atualizações de documentação em `DOCUMENTACAO.md`, `rmr/docs/ARCHITECTURE.md` e
  material não jurídico segregado em `rmr/MANIFESTO_RAFAELIA.md`.
- Limpeza organizacional no módulo externo `rmr/`: remoção de artefatos de
  build/backup do versionamento e reforço das regras de ignore.
- Adicionados `tools/check_rmr_headers.py` e `tools/check_rmr_headers.sh`
  como automação externa para validar `LICENSE_RMR`, shebang e escopo de
  mudanças permitidas (sem alterar o núcleo criptográfico).

## Matriz de detecção e despacho por arquitetura/SO (RMR)

**Campos de validação objetivos** usados nesta matriz:

- `evidenciado por código`: há implementação/condição explícita em arquivo do repositório.
- `evidenciado por teste`: há teste automatizado explícito cobrindo o ponto.
- `não evidenciado`: não foi encontrado código ou teste que comprove o ponto.

| Arquitetura / SO alvo | Detector | Backend ativo esperado | Fallback | Requisitos de compilação | Riscos conhecidos | Validação (detector) | Validação (backend/fallback) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| x86_64 ou x86_32 (Linux, Windows, Darwin, BSD) | `rmr/hwif/detect/detect_x86.c` (`cpuid` + `xgetbv`) | Caminho x86 (flags `RMR_HAS_SSE2`, `RMR_HAS_SSE41`, `RMR_HAS_AVX2`, `RMR_HAS_AVX512` via `rmr/include/rmr_dispatch.h`) | Fallback compile-time (`RMR_COMPILETIME_HAS_*`) quando `RMR_DISABLE_RUNTIME_DETECT` ou sem `caps` | Macros de arquitetura em `rmr/include/rmr_arch.h`; compilador com inline asm x86 para `cpuid/xgetbv` | `AVX2/AVX512` dependem de `OSXSAVE + XCR0`; se o SO não habilitar contexto estendido, extensão não ativa | evidenciado por código | evidenciado por código |
| AArch64 (Linux/Android/Darwin/BSD) | `rmr/hwif/detect/detect_aarch64.c` | Caminho ARM (`RMR_HAS_NEON` via `rmr/include/rmr_dispatch.h`) | Sem `RMR_AARCH64_ASSUME_PRIVILEGED`: usa apenas macro compile-time `__ARM_NEON`; com macro desligada mantém `execution_mode=user` | Arquitetura `RMR_ARCH_AARCH64`; para modo privilegiado, build com `RMR_AARCH64_ASSUME_PRIVILEGED` | Leitura de `ID_AA64ISAR0_EL1`/`CurrentEL` via `MRS` pode falhar em userland; modo padrão evita isso | evidenciado por código | evidenciado por código |
| ARM/RISC-V/PPC e demais arquiteturas | `rmr/hwif/detect/detect_fallback.c` | Sem backend SIMD dedicado no detector; usa máscara mínima | `simd_extensions=0` (exceto `__ARM_NEON`) e largura de registrador por `sizeof(void*)` | Qualquer alvo não coberto por `RMR_ARCH_X86_*` e `RMR_ARCH_AARCH64` | Cobertura limitada de extensões SIMD (detecção conservadora) | evidenciado por código | evidenciado por código |
| Todas as combinações acima | Cobertura de validação automatizada para matriz de dispatch/detector | N/A | N/A | N/A | Sem suíte dedicada documentada para validar a matriz por arquitetura/SO nesta árvore | não evidenciado | não evidenciado |

### Limitações atuais consolidadas (detector/dispatch)

1. **AArch64 privilegiado vs userland:** o modo detalhado de detecção (`RMR_AARCH64_ASSUME_PRIVILEGED`) depende de acesso a registradores EL1; em userland, o caminho seguro não consulta esses registradores.
2. **Dependência de `XCR0` no x86:** `AVX2` e `AVX512` só são habilitados quando CPU e SO indicam suporte conjunto (`OSXSAVE` + bits necessários em `XCR0`).
3. **Cobertura conservadora fora de x86/AArch64:** `rmr/hwif/detect/detect_fallback.c` não faz enumeração avançada de SIMD para RISC-V/PPC/outros.
4. **Detecção de SO Android em `rmr/include/rmr_arch.h`:** a ordem atual verifica `__linux__` antes de `__ANDROID__`; em toolchains onde ambos são definidos, o alvo pode ser classificado como Linux.

### Checklist de atualização da matriz (obrigatório em mudanças de dispatch)

Atualizar esta matriz sempre que houver mudanças em:

- `rmr/hwif/detect/`
- `rmr/asm/`
- `rmr/include/rmr_dispatch.h`

Checklist de revisão:

- [ ] Revalidar linhas afetadas de arquitetura/SO na matriz (detector, backend, fallback).
- [ ] Marcar cada campo de validação como `evidenciado por código`, `evidenciado por teste` ou `não evidenciado`.
- [ ] Consolidar novas limitações na seção única **Limitações atuais consolidadas (detector/dispatch)**.
- [ ] Atualizar `rmr/docs/ARCHITECTURE.md` e `rmr/PROVENIENCE.md` se houver impacto de organização/autoria.

## Observação final

Esta árvore **não cria um novo hash** e **não renomeia** o BLAKE3. Ela
apenas redistribui o upstream com uma camada externa isolada e
claramente documentada.

### Registro de mudança organizacional (UI de modos RMR)

- **Data:** 2026-05-02
- **Escopo:** adição de `rmr/ui/mode_router.[ch]` e roteamento de `rmr/core/main.c` para front controller.
- **Impacto no upstream BLAKE3:** nenhum (sem alterações em `src/`, `c/`, `b3sum/` ou ASM upstream).
- **Backend preservado:** `pai_main` permanece como backend de operações, chamado pelo modo `cli`.


## Perfis centrais de build (RMR)

A camada externa RMR passou a centralizar perfis de compilação em `rmr/build/profiles.mk`, consumido pelos scripts de `rmr/build/*.sh`.

Perfis suportados:

- `latency`
- `throughput`
- `deterministic`
- `debug`

Os artefatos de benchmark agora registram perfil e flags finais efetivas para auditoria e comparabilidade entre runs.

## Atualização de governança de telemetria (2026-05-02)

- O contrato `rmr/include/rmr_governance.h` foi estendido com política de telemetria controlada (`ntp_enabled`, `icmp_probe_enabled`, `jitter_sampling_enabled`), modo `offline_deterministic`, limites de timeout/janela e rate limit por minuto.
- Foram adicionados callbacks abstratos de telemetria (`read_clock_sync`, `icmp_probe`, `jitter_sample`) sem acoplamento a stack específica de rede/clock.
- O armazenamento de benchmark (`rmr/core/bench.c`) passa a persistir estado efetivo dessas políticas e metadados de clock/rede no `run_manifest.json` para correlação de desempenho com estabilidade de rede/clock.
- Todo o escopo permanece isolado em `rmr/`, preservando o núcleo criptográfico upstream inalterado.

## Trilha externa `rmr/pathcutter` (2026-05-02)

- Foi criado o subdiretório `rmr/pathcutter/` para concentrar utilidades experimentais de redução de fricção operacional fora do núcleo upstream.
- A interface pública consumida por `rmr/core` permanece estável (`pai_die`, `pai_mkdir_p`, `pai_xmalloc`, `pai_xfree`), com adaptação interna por `rmr/core/util.c` para símbolos `rmr_pc_*`.
- Não há dependências externas adicionais; o módulo usa apenas C/POSIX e infraestrutura já existente no repositório.
- Auditoria estática dedicada: `rmr/tools/audit_pathcutter_static.py` valida includes proibidos, heap em loops quentes e uso indevido de símbolos fora do contrato do módulo.
- Classificação de autoria: trilha explicitamente marcada como **código autoral externo ao upstream BLAKE3**.

### 12) Reprodutor local do job `cmake_c_tests`

Para validar o diretório `c/` com CMake e comparar com a matriz declarada em
`.github/workflows/ci.yml`, foi adicionado o helper `tools/cmake_ci_compare.sh`.

- Execução rápida (início): `tools/cmake_ci_compare.sh`
  - roda a trilha mínima (`SIMD=x86-intrinsics`, `TBB=OFF`) com as mesmas flags
    de fallback de SIMD usadas no CI.
- Execução completa: `tools/cmake_ci_compare.sh --full`
  - percorre toda a matriz de `SIMD` e `TBB` do job `cmake_c_tests`.

Esse fluxo não altera o núcleo criptográfico; apenas automatiza validação e
comparação estrutural com a fonte de verdade do CI.

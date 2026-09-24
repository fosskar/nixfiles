# local llama.cpp model selection

nixbox runs `llama.cpp` on an NVIDIA RTX PRO 4000 Blackwell SFF Edition (24467 MiB VRAM), a Ryzen 7 5700X (8 cores, PCIe 4.0) and 64 GB RAM. the workload is two hermes instances (`hermes`, `hermina`) doing assistant work: tool calls, calendar, email sorting, morning reports, root-cause research. no coding. latency per request matters more than maximum quality.

## decision

default model: `unsloth/Qwen3.6-35B-A3B-MTP-GGUF:Q4_K_XL` (alias `qwen3.6-35b-a3b-mtp`, `load-on-startup`), with:

- `spec-type = "draft-mtp"`, `spec-draft-n-max = 2`
- `parallel = 2`: one slot per hermes instance, 122880 tokens each
- `ctx-size = 245760`
- `ubatch-size = 2048`
- no `n-gpu-layers`/`n-cpu-moe`: `--fit` (default on) moves expert tensors to system RAM until the model fits, 12 layers at this context
- `load-mode = "none"` for all presets, so offloaded experts live in process memory instead of evictable page cache
- `mmproj` stays on the GPU
- `q8_0` KV cache

kept as secondary presets:

- `UD-Q6_K` (alias `qwen3.6-35b-a3b-q6k-mtp`): higher quality, ~30% slower
- `qwen3.6-27b-mtp`: dense 27B with MTP, pinned to `n-gpu-layers = 999` because fit's margin would move 3 of 66 layers to CPU although everything fits

this replaces the earlier default of `UD-IQ4_XS` without MTP and without offload.

## why Q4_K_XL over IQ4_XS

unsloth's KLD benchmark for 35B-A3B (mean KLD vs BF16, lower is better):

| quant      | file size | mean KLD |
| ---------- | --------: | -------: |
| UD-IQ4_XS  |   18.2 GB |   ~0.032 |
| UD-Q4_K_S  |   21.4 GB |   ~0.015 |
| UD-Q4_K_XL |   22.9 GB |   ~0.012 |
| UD-Q5_K_S  |   25.5 GB |  ~0.0077 |
| UD-Q5_K_XL |   27.2 GB |  ~0.0068 |
| UD-Q6_K    |   30.0 GB |  ~0.0052 |

IQ4_XS → Q4_K_XL is the largest quality step per GB. with MTP plus expert offload, Q4_K_XL runs at about the speed IQ4_XS had fully on the GPU without MTP.

## measurements

all runs except the last row: `ctx-size = 163840`, `parallel = 2`, MTP n-max 2, `q8_0` KV, `mmproj` on GPU. peak VRAM includes a 3840×2160 image request. decode is the mean of three 768-token answers at temp 1.0; run-to-run noise is about ±5%.

| config                                   | peak VRAM | decode t/s | prompt t/s | process RAM |
| ---------------------------------------- | --------: | ---------: | ---------: | ----------: |
| IQ4_XS, no MTP, no offload (old default) | 20518 MiB |       99.4 |       2154 |           — |
| Q4_K_XL `n-cpu-moe 4`                    |       OOM |          — |          — |           — |
| Q4_K_XL `n-cpu-moe 6`, ubatch 512        | 23462 MiB |       97.4 |       1290 |           — |
| Q4_K_XL `n-cpu-moe 8`, ubatch 512        | 22536 MiB |       92.1 |       1147 |           — |
| Q4_K_XL `n-cpu-moe 12`, ubatch 512       | 20680 MiB |       81.3 |        944 |           — |
| Q4_K_XL `n-cpu-moe 8`, ubatch 2048       | 23278 MiB |       87.1 |       2046 |     5.8 GiB |
| Q4_K_XL fit (9 layers), ubatch 2048      | 23182 MiB |       86.2 |       1887 |     5.9 GiB |
| Q6_K `n-cpu-moe 16`, ubatch 2048         | 23780 MiB |       61.8 |       1484 |    12.2 GiB |
| Q6_K fit (18 layers), ubatch 2048        | 23068 MiB |       60.8 |       1318 |    12.8 GiB |
| Q4_K_XL fit (12 layers), ctx 245760      | 23136 MiB |       82.6 |       1736 |     7.5 GiB |

other findings:

- `ubatch-size` 512 → 2048 raised prompt speed 68% for ~730 MiB VRAM. with offloaded experts, llama.cpp copies those weights over PCIe once per ubatch; larger ubatches mean fewer copies. decode is unaffected.
- MTP on the MoE model: +23% decode fully on GPU (unsloth reports 1.15–1.25x for MoE). with 4 offloaded layers it still recovered the offload cost (106 vs 87 t/s without MTP). n-max 3 was slower than 2.
- MTP on the dense 27B: 22.9 → 41.4 t/s (+81%), draft acceptance ~84%.
- `load-mode none` vs mmap: same speed within noise.
- `--fit` picks the same offload as manual tuning and adapts when `ctx-size` changes. it only adjusts options that are not set, so a global `n-gpu-layers` disables it.
- KV cache costs ~15 MiB per 1k tokens of `ctx-size`.
- with `parallel` set, KV is not unified: each slot gets `ctx-size / parallel`, and `/v1/models` reports the per-slot `n_ctx`, which hermes uses for its window. unified KV (`parallel` auto) shares one pool; VRAM is the same either way.
- `--cache-ram` (default 8192 MiB) saves slot state to RAM and restores matching prefixes: a 13k-token prompt evicted from both slots came back in 0.1 s instead of 11.4 s. three conversations on two slots all kept their cache.
- `mmproj` on CPU frees ~1.5 GB VRAM but a 4k image takes ~106 s to encode instead of ~10 s. rejected.

## accepted tradeoffs

- at `ctx-size = 245760`, prompt speed is ~20% below the old IQ4_XS default and decode ~17% below. 163840 would recover ~5% decode and ~10% prompt speed but caps each slot at 81920.
- VRAM headroom during an image request is ~1.3 GiB; fit keeps the margin when context changes.
- offloaded experts use ~7.5 GiB of system RAM.
- Q6_K would cost ~30% decode and ~27% prompt speed; its quality gain shows mostly in exact long outputs, which the assistant workload rarely needs.
- hermes sends `reasoning_effort: medium`, which llama-server ignores (only `none` is handled), so thinking length is left to the model. observed requests generate 57–1067 tokens including the answer, so a reasoning budget was not worth adding.

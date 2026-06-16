# local llama.cpp model selection

nixbox runs `llama.cpp` on an NVIDIA RTX PRO 4000 Blackwell SFF Edition with 24 GB VRAM. the local assistant workload is pi-chat/tool use: calendar, messages, location, web search, Deutsche Bahn, and similar short interactive tasks. default model selection prioritizes low latency, stable tool/chat behavior, and enough VRAM headroom over maximum dense-model quality.

## service settings used for comparison

current server presets use:

- `n-gpu-layers = 999`
- `models-max = 1`
- `flash-attn = "on"`
- `cache-type-k = "q8_0"`
- `cache-type-v = "q8_0"`
- default `ctx-size = 32768`

MTP presets additionally use:

- `spec-type = "draft-mtp"`
- `cache-type-k-draft = "q4_0"`
- `cache-type-v-draft = "q4_0"`

`qwen3_6-35b-a3b-mtp` was tested manually but is not a configured default because it leaves too little VRAM headroom.

## raw llama-bench throughput

`llama-bench` was run on nixbox against downloaded GGUFs with:

- prompt sizes: `512,2048`
- generation sizes: `128,512`
- repetitions: `5`
- `flash-attn = on`
- `cache-type-k/v = q8_0`
- `n-gpu-layers = 999`

| model                  | prompt 512 t/s | prompt 2048 t/s | gen 128 t/s | gen 512 t/s |
| ---------------------- | -------------: | --------------: | ----------: | ----------: |
| `gemma4-e4b`           |         5015.7 |          5042.5 |        90.4 |        87.9 |
| `gemma4-12b`           |         2060.7 |          1985.2 |        43.2 |        42.3 |
| `qwen3_6-27b`          |          827.7 |           812.5 |        19.6 |        19.4 |
| `qwen3_6-27b-mtp`      |          829.2 |           825.6 |        19.7 |        19.5 |
| `qwopus3_6-27b-v2-mtp` |          831.7 |           826.3 |        20.8 |        20.4 |
| `qwen3_6-35b-a3b`      |         2425.7 |          2358.4 |        98.0 |        94.9 |

`llama-bench` does not exercise server speculative decoding behavior from `spec-type = draft-mtp`; it measures raw GGUF throughput.

## server latency and MTP behavior

server benchmark used the live `llama.cpp` server path with one loaded model at a time, fixed prompt, `max_tokens = 128`, and 3 requests per model.

| model                  | avg latency | avg generation t/s | avg output tokens | finish reason |
| ---------------------- | ----------: | -----------------: | ----------------: | ------------- |
| `gemma4-e4b`           |       0.70s |              90.96 |              48.7 | `stop`        |
| `gemma4-12b`           |       1.15s |              44.23 |              45.7 | `stop`        |
| `qwen3_6-35b-a3b`      |       1.19s |              93.17 |              91.3 | `stop`        |
| `qwen3_6-27b-mtp`      |       3.27s |              26.24 |              76.0 | `stop`        |
| `qwen3_6-27b`          |       4.45s |              20.08 |              82.3 | `stop`        |
| `qwopus3_6-27b-v2-mtp` |       4.49s |              30.78 |             128.0 | `length`      |

MTP helped the dense Qwen 27B server path:

- `qwen3_6-27b`: 20.08 t/s, 4.45s average latency
- `qwen3_6-27b-mtp`: 26.24 t/s, 3.27s average latency

`qwopus3_6-27b-v2-mtp` generated fastest among the 27B dense variants but hit `max_tokens` on every run. it is kept for coding/reasoning experiments, not as the default low-latency assistant model.

## VRAM usage at ctx-size 32768

measured with the live server after loading each model and after one short request. idle VRAM was 4 MiB used / 23984 MiB free.

| model                  | loaded VRAM | after request | free after request |
| ---------------------- | ----------: | ------------: | -----------------: |
| `gemma4-e4b`           |    6208 MiB |      6224 MiB |          17765 MiB |
| `gemma4-12b`           |    8588 MiB |      8598 MiB |          15391 MiB |
| `qwen3_6-27b`          |   19444 MiB |     19464 MiB |           4525 MiB |
| `qwen3_6-27b-mtp`      |   21800 MiB |     21860 MiB |           2129 MiB |
| `qwopus3_6-27b-v2-mtp` |   18958 MiB |     18976 MiB |           5013 MiB |
| `qwen3_6-35b-a3b`      |   22706 MiB |     22722 MiB |           1267 MiB |
| `qwen3_6-35b-a3b-mtp`  |   23908 MiB |     23958 MiB |             31 MiB |

MTP cost for Qwen 35B-A3B at `ctx-size = 32768` was about 1242 MiB over non-MTP. that leaves only 31 MiB free after a short request, so it is technically loadable but not operationally safe.

## Qwen 35B-A3B context stress test

non-MTP `qwen3_6-35b-a3b` was stress-tested with `q8_0` KV and server auto parallelism (`n_parallel = 4`).

| ctx-size | loaded VRAM | after request | free after request | result    |
| -------: | ----------: | ------------: | -----------------: | --------- |
|    32768 |   22706 MiB |     22716 MiB |           1273 MiB | ok        |
|    49152 |   22924 MiB |     22934 MiB |           1055 MiB | ok        |
|    65536 |   23142 MiB |     23152 MiB |            837 MiB | ok        |
|    81920 |   23360 MiB |     23370 MiB |            619 MiB | ok        |
|    98304 |   23578 MiB |     23588 MiB |            401 MiB | ok        |
|   114688 |   23796 MiB |     23806 MiB |            183 MiB | ok, tight |
|   131072 |   23764 MiB |     23774 MiB |            215 MiB | ok, tight |
|   163840 |           — |             — |                  — | OOM       |

OOM at `ctx-size = 163840` included:

```text
cudaMalloc failed: out of memory
failed to allocate CUDA0 buffer of size 902804096
GGML_ASSERT(buffer) failed
```

MTP `qwen3_6-35b-a3b-mtp` was tested with the same base settings plus draft KV `q4_0`:

| ctx-size | loaded VRAM | after request | free after request | result        |
| -------: | ----------: | ------------: | -----------------: | ------------- |
|    32768 |   23908 MiB |     23958 MiB |             31 MiB | ok, too tight |
|    49152 |           — |             — |                  — | OOM           |

## decision

use `qwen3_6-35b-a3b` as the default local assistant model.

reasons:

- server latency is close to `gemma4-e4b` while using a larger Qwen MoE model.
- generation speed is the best among configured non-MTP candidates: about 93 t/s in server testing.
- output stops normally under the fixed short assistant prompt.
- at `ctx-size = 32768` with `q8_0` KV it leaves about 1.27 GiB free after a short request.

keep these secondary models:

- `gemma4-e4b`: ultra-low-latency fallback.
- `gemma4-12b`: small dense comparison model.
- `qwen3_6-27b-mtp`: dense Qwen MTP comparison; MTP improves server latency over non-MTP 27B.
- `qwopus3_6-27b-v2-mtp`: coding/reasoning experiment, not default assistant, because it tends to fill `max_tokens`.

reject `qwen3_6-35b-a3b-mtp` as default for now. it is too close to the VRAM limit with the current `q8_0` KV policy and `ctx-size = 32768`, and OOMs at `ctx-size = 49152`.

## accepted tradeoffs

- `qwen3_6-35b-a3b` has less VRAM headroom than Gemma or 27B models, so only one large model should be loaded at a time.
- `ctx-size = 32768` is the safe default. `65536` works for Qwen 35B-A3B but reduces free VRAM to about 837 MiB after a short request.
- MTP is not universally better. it can improve t/s, but wall-clock latency still depends on output length and VRAM headroom.

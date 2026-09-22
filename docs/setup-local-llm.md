# Setup: local LLM (llama.cpp)

**Run this first, on every machine.** Everything else in this repo — `/handoff`, the Librarian,
the Archivist, OpenCode's background titles — talks to `llama-server` on `127.0.0.1:8080`. If it
isn't up, you get a raw connection error from the openai-compatible provider rather than a useful
message.

Takes about 20 minutes, most of it waiting on a download.

**Prerequisites:** Apple Silicon Mac with 32 GB unified memory (the GPU limit below assumes it),
and Homebrew.

---

## 1. Install llama.cpp

```bash
brew install llama.cpp
llama-server --version
```

Homebrew's build has Metal enabled, which is what you want. Building from source is only worth it
if you need a specific commit — and if you do, record why as a handoff, since llama.cpp version
behaviour is exactly what this wiki exists to track.

---

## 2. Raise the GPU wired-memory limit

**Do this before loading a model.** macOS caps how much unified memory the GPU may wire down. The
default is well under what a 27B needs, and exceeding it silently falls back to slow paths instead
of failing loudly.

```bash
stow llm fish
llm-gpu-persist
```

That copies `local.iogpu.wired-limit.plist` to `/Library/LaunchDaemons/` and loads it — it asks for
sudo, and it's four lines, so read `fish/.config/fish/functions/llm-gpu-persist.fish` first if
you'd rather see what it does.

Verify:

```bash
sysctl iogpu.wired_limit_mb
```

Expect `iogpu.wired_limit_mb: 24576` (24 GB). Open a **new** shell and confirm the startup guard is
silent — no `⚠️ GPU wired limit=...` warning. If it doesn't survive a reboot:

```bash
sudo launchctl print system/local.iogpu.wired-limit
```

---

## 3. Get the model

The default is **Qwen3.8-27B** at `Q4_K_M` — about 17 GB on disk, which fits the 24 GB budget with
room for context. It's dense, so it's the better writer; that matters because `/handoff` must copy
error strings verbatim.

You don't download it separately. `llama-server`'s `-hf` flag fetches from Hugging Face on first
run and caches it (`~/Library/Caches/llama.cpp`). Start it by hand once, to watch it work:

```bash
llama-server -hf unsloth/Qwen3.8-27B-GGUF:Q4_K_M \
  -c 65536 -ngl all --host 127.0.0.1 --port 8080 -np 1
```

The first run downloads ~17 GB. Subsequent runs start in seconds.

> **`-c 65536` is not optional.** It must match `limit.context` for this model in
> `opencode/.config/opencode/opencode.jsonc`. If they disagree, OpenCode will send prompts longer
> than the server's window and they get truncated **silently** — no error, just a model that seems
> to forget the middle of your handoff.

> **`-np 1` is deliberate.** Metal runs out of memory under the default auto-parallelism. One slot
> is also all this setup needs — nothing here issues concurrent requests.

In another shell, confirm it answers:

```bash
curl -sf http://127.0.0.1:8080/v1/models
```

Then `Ctrl-C` it. The next step makes it permanent.

---

## 4. Start it automatically at login

```fish
llm-serve-persist
```

Copies `local.llama-server.plist` into `~/Library/LaunchAgents/` and loads it. A LaunchAgent, not a
Daemon — it runs as you, needs no root, and starts at login rather than at boot.

Check it:

```fish
llm-status          # → "up — <model id>"
```

Logs, if it doesn't come up:

```bash
tail -f /tmp/llama-server.err.log
```

---

## 5. Manual control

The agent handles the common case. These are for when you want something else:

| Command | Does |
| --- | --- |
| `llm-status` | Up or down, and which model is loaded |
| `llm-down` | Stop it — frees ~17 GB when you need the RAM |
| `llm-up` | Start it again |
| `llm-fast` | Swap to the faster MoE model on the same port |
| `llm-serve-persist` | (Re)install the agent after changing the plist |

`llm-fast` loads **Qwen3.6-35B-A3B**, a mixture-of-experts model: 35B total but only ~3B active per
token, so it reads many pages much faster. Good for the Archivist answering questions, weaker for
careful writing. You don't need to change any OpenCode config to use it — the `llamacpp` provider
pins the *endpoint*, not the model name, so whatever is loaded on `:8080` is what answers. `llm-up`
returns you to the default.

---

## Known caveats

Record anything you hit here as a handoff — this is precisely the content the wiki is built to
hold.

**Don't use the MTP build of the MoE on Apple Silicon.** `Qwen3.6-35B-A3B-MTP` with self-MTP
speculative decoding measures **~13.6× slower** than baseline on Metal — 1.93 tok/s against
26.23 tok/s — despite a 95.6% token acceptance rate. Metal also reports
`warning: current allocated size is greater than the recommended max working set size`. Affects
llama.cpp build `b9117-ebe4fca4b`. Fix: use the plain (non-MTP) build, which is what `llm-fast`
points at, and omit `--spec-type mtp`. Verify: `llm-status` names a repo without `MTP` in it.
Source: [llama.cpp#23011](https://github.com/ggml-org/llama.cpp/issues/23011)

**Both models can't be resident at once.** 17 GB + ~20 GB exceeds the 24 GB wired limit. `llm-fast`
stops the running server before starting the other one, deliberately.

**GGUF quantizations are third-party.** Only BF16 and FP8 checkpoints are official from Qwen; the
`unsloth/` and `bartowski/` GGUF repos are community conversions. That's normal and fine, but it
means a quant can be re-uploaded and change under you — if behaviour shifts after a re-pull, that's
a real caveat worth a handoff.

---

## What could not be verified here

Written on Linux with no macOS, Homebrew, `fish`, or Apple GPU. Flag syntax was checked against the
llama.cpp server documentation and the model repositories were confirmed to exist, but **no command
on this page has been run**. The LaunchAgent plist and `llm.fish` are unexercised.

Run this once after `stow fish`, since it's the one check that can't be done from here:

```bash
fish -n ~/.config/fish/conf.d/llm.fish
fish -n ~/.config/fish/conf.d/zk.fish
```

Sizing figures (Q4_K_M ≈ 17.1 GB, MoE ≈ 22 GB) come from published model documentation, not from
measurement on your machine.

---

**Next:** [setup-zettelkasten.md](setup-zettelkasten.md)

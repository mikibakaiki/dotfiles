# Setup: local LLM (llama.cpp)

**Run this first, on every machine.** Everything else in this repo — `/handoff`, the Librarian,
the Archivist, OpenCode's background titles — talks to `llama-server` on `127.0.0.1:8080`. If it
isn't up, you get a raw connection error from the openai-compatible provider rather than a useful
message.

Takes about 20 minutes, most of it waiting on a download.

**Prerequisites:** Apple Silicon Mac with 32 GB unified memory (the GPU limit below assumes it),
and Homebrew. If you ran `bootstrap.sh`, step 0 is already done.

---

## 0. Tools and the repo

```bash
brew install stow fish llama.cpp
llama-server --version

git clone https://github.com/mikibakaiki/dotfiles.git ~/dotfiles   # if not already cloned
cd ~/dotfiles
```

HTTPS rather than the `github-personal` SSH alias: that alias lives in `ssh/config`, which does not
exist until this repo is cloned and stowed. The README's *Fresh machine setup* switches the remote
afterwards.

**Already had this repo stowed on this machine?** Check it isn't on the old folded layout before
stowing anything below:

```bash
./migrate-to-no-folding.sh    # "Nothing stranded" means carry on; otherwise follow its instructions
```

Every command below that starts with a `zk-` or `llm-` name is a **fish function**, so run them
from a fish shell:

```bash
exec fish
```

---

## 1. Verify llama.cpp

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
exec fish          # conf.d/ functions only load in a NEW fish shell
```

On a machine that already had fish configured, stow may refuse with a conflict list and change
nothing — that's it protecting your existing files, not a failure. See **Conflicts** in the
README before reaching for `--adopt`, which overwrites the repo's copy with the machine's.

```fish
llm-gpu-persist
```

That copies `local.iogpu.wired-limit.plist` to `/Library/LaunchDaemons/` and loads it — it asks for
sudo, and it's a handful of lines, so read `fish/.config/fish/functions/llm-gpu-persist.fish`
first if you'd rather see what it does.

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

The default is **Qwen3.8-27B**, dense, which makes it the better writer — and that matters, because
`/handoff` has to copy error strings verbatim.

**Check the quant name before you run this.** Unsloth publishes Unsloth-Dynamic builds, so the file
is named `UD-Q4_K_M` (≈16.5 GB) or `UD-Q4_K_XL` (≈17.6 GB) rather than a plain `Q4_K_M`. This
matters more than it looks: when the quant you name doesn't exist, `-hf` **falls back to the first
file in the repo**, which could be an IQ1 or a Q8_0 — it will download something, and it won't tell
you it wasn't what you asked for. Open
[the repo's file list](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/tree/main) and use a name
you can actually see there.

`llama-server`'s `-hf` flag fetches from Hugging Face on first run and caches it
(`~/Library/Caches/llama.cpp`). Start it by hand once, to watch it work:

```bash
llama-server -hf unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_M \
  -c 65536 -ngl all --host 127.0.0.1 --port 8080 -np 1 -a qwen3.8-27b-local
```

First run pulls ~17 GB, plus a ~0.9 GB `mmproj` file — this is a vision model, and `-hf` fetches
the projector too unless you pass `--no-mmproj`. Later runs start in seconds.

> **`-c 65536` must match `limit.context`** for this model in
> `opencode/.config/opencode/opencode.jsonc`. If the server's window is smaller, an over-long
> request fails with **HTTP 400** — `the request exceeds the available context size` — because
> `--context-shift` is off by default. It's a loud failure, not a silent truncation, so if you see
> that 400 the two numbers have drifted apart.

> **`-np 1` is deliberate.** `-c` sizes one shared KV pool that is split across slots, so a single
> slot is what gives you the full 65536 tokens. It also avoids the Metal out-of-memory reported
> under default parallelism in the MTP issue below.

> **`-a` sets the model's reported name.** Without it, `/v1/models` reports the full cache path, so
> `llm-status` prints a long filename instead of a name.

In another shell, confirm it answers:

```bash
curl -sf http://127.0.0.1:8080/v1/models
```

Then `Ctrl-C` it. The next step makes it permanent. (If you are redoing this on a machine where the
LaunchAgent is already installed, run `llm-down` first — otherwise port 8080 is taken and this
fails to bind.)

---

## 4. Start it automatically at login

```fish
llm-serve-persist
```

Copies `local.llama-server.plist` into `~/Library/LaunchAgents/` and loads it. A LaunchAgent, not a
Daemon — it runs as you, needs no root, and starts at login rather than at boot.

**Give it a minute before checking** — it has to load ~17 GB before it answers. Then:

```fish
llm-status          # → "up — qwen3.8-27b-local"
```

If it says `down` after a couple of minutes, ask launchd what happened first — the log file only
exists if the process actually started:

```bash
launchctl print gui/$(id -u)/local.llama-server
tail -f /tmp/llama-server.err.log
```

A wrong binary path in the plist shows up here as launchd respawn-throttling the job every ~10
seconds rather than as a clean failure.

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
pins the *endpoint*, not the model name, so whatever is loaded on `:8080` is what answers.

Two things to know before you reach for it:

- **It holds the terminal.** It runs in the foreground, and Ctrl-C leaves you with *no* server —
  run `llm-up` afterwards to get the default back.
- **It runs at 32K context, not 64K.** At ~22.3 GB this quant nearly fills the 24 GB wired limit on
  its own, so a 64K KV cache will not fit. `llm-fast` starts it at 32768 with a `q8_0` KV cache,
  and `opencode.jsonc` declares the same 32768 for this model so the two stay in step. If it still
  runs out of memory, move to a smaller quant rather than raising the context. This combination is
  **unverified on real hardware** — see the note at the end.

---

## Known caveats

Record anything you hit here as a handoff — this is precisely the content the wiki is built to
hold.

**Don't use the MTP build of the MoE on Apple Silicon.** `Qwen3.6-35B-A3B-MTP` with self-MTP
speculative decoding measured **~13.6× slower** than baseline on Metal — 1.93 tok/s against
26.23 tok/s — despite a 95.6% token acceptance rate, with Metal reporting
`warning: current allocated size is greater than the recommended max working set size`. Those
figures are from build `b9117-ebe4fca4b`, and that issue is now **closed** — but the advice still
holds: [#23752](https://github.com/ggml-org/llama.cpp/issues/23752) reports MTP still net-negative
on Metal on a later build. Use the plain (non-MTP) build, which is what `llm-fast` points at.
Note the flag has also been renamed — it is `--spec-type draft-mtp` now, not `mtp`.
Verify: `llm-status` names a model without `MTP` in it.
Source: [llama.cpp#23011](https://github.com/ggml-org/llama.cpp/issues/23011)

**Both models can't be resident at once.** ~16.5 GB + ~22.3 GB far exceeds the 24 GB wired limit.
`llm-fast` stops the running server before starting the other one, deliberately.

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

Sizing figures (UD-Q4_K_M ≈ 16.5 GB, UD-Q4_K_XL ≈ 17.6 GB, MoE Q4_K_M ≈ 22.3 GB) come from the
published repository file listings, not from measurement on your machine. The `llm-fast` settings
in particular — 32K context with a `q8_0` KV cache on a 22.3 GB model against a 24 GB wired limit —
are a calculation, not an observation. If it fails to load, that is the first thing to adjust, and
worth a handoff.

---

**Next:** [setup-zettelkasten.md](setup-zettelkasten.md)

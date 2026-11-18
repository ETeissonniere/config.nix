# Straylight

Ryzen 9 9900X / RTX 4080 SUPER host, reachable at `straylight.local` via DHCP
and mDNS.

Straylight is the main lab compute server for experiments and
isolated work and personal environments. It also serves as a remote Nix builder
for our Macs.

It has two SSDs, with the larger one holding AI models and other
data. Secure Boot uses our own keys, with TPM-backed disk decryption :smile:!

## Containers

Containers use native NixOS containers. Manage them through systemd, for example
`sudo systemctl restart container@slopcannon`.

| Service | Purpose | Access and storage | Startup |
| --- | --- | --- | --- |
| `container@slopcannon` | Remote development in a native NixOS container. | Own LAN address and mDNS name: `ssh slopcannon.local`. Home, SSH host keys, and credentials persist under `/data/slopcannon`. | Automatic |
| `container@slopkiddy` | Local AI: Open WebUI, llama.cpp, and ComfyUI behind Caddy, signed in through Pocket ID. | `openwebui.teiss.org` and `comfy.teiss.org`. State and manually downloaded models persist under `/data/slopkiddy`. | Automatic |

## Cyberfrost

`cyberfrost-gguf` uses llama.cpp with the Q2_K quant. `cyberfrost-exl3` uses
TabbyAPI with Vic's SAGE 3.35 bpw quant. Each has one 262,144-token slot for
prompt and output combined. Both stream n-gram weights from the SSD. EXL3
offloads most routed experts to the CPU and promotes frequently used experts
to GPU memory. llama-swap runs one GPU backend at a time, including the
existing text and image backends, and unloads either Cyberfrost backend after
two idle minutes.

Before activating this configuration, download the models on Straylight as a
user with write access to the persistent model directory. The two downloads
need about 177 GB together.

```fish
hf download Shaeh/CYBER-FROST-3.8-GGUF CYBER-FROST-3.8-Q2_K.gguf \
  --revision 2d5a10f4154cc21b315b9692ffa637f9862fefd1 \
  --local-dir /data/slopkiddy/models/text/CYBER-FROST-3.8-GGUF
hf download vcruz305/CYBER-FROST-3.8-EXL3-SAGE-3.35bpw \
  --revision 60a9f7250c8cb37f973bd393a4862037477f2329 \
  --local-dir /data/slopkiddy/models/text/CYBER-FROST-3.8-EXL3-SAGE-3.35bpw
```

From a laptop, keep the SSH tunnel open while the agent uses the model.

```fish
ssh -N -o ExitOnForwardFailure=yes \
  -L 127.0.0.1:8082:/run/slopkiddy-inference/api.sock straylight.local
```

Use `http://127.0.0.1:8082/v1` as the OpenAI-compatible base URL. The same URL
works directly in Slopcannon. Agents that require a non-empty API key can use
`local`. Both backends support Chat Completions. The GGUF backend also serves
the Responses API.

```fish
curl -fsS http://127.0.0.1:8082/v1/models
for model in cyberfrost-gguf cyberfrost-exl3
    curl -fsS http://127.0.0.1:8082/v1/chat/completions \
      -H 'Content-Type: application/json' \
      -d "{\"model\":\"$model\",\"messages\":[{\"role\":\"user\",\"content\":\"Name the capital of France.\"}],\"max_tokens\":128}"
end
```

Check `nvidia-smi` on Straylight after two idle minutes to confirm VRAM is
released. A long-context check should send a prompt close to 262,144 tokens,
with room for output, and verify retrieval from the start and end of that prompt.

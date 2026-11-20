{ pkgs }:
let
  python = pkgs.python312;
  pythonPackages = python.pkgs;
  cudaPackages = pkgs.cudaPackages_13_0;
  torch = pythonPackages.torch-bin.override {
    inherit cudaPackages;
    stdenv = cudaPackages.backendStdenv;
  };
  # Vic's model card pairs this quant with a specific ExLlamaV3 fork.
  exllamav3 =
    (pythonPackages.exllamav3.override { inherit cudaPackages torch; }).overridePythonAttrs
      (old: {
        version = "1.6.5.post1";
        src = pkgs.fetchFromGitHub {
          owner = "vcruz305";
          repo = "exllamav3";
          rev = "bccada041d3236c5b710f8154ad9e3bf669d99f3";
          hash = "sha256-pyEMVmknpVS3r2djXYA5bbHp9Gp8RSkfRJQx6rGBfNE=";
        };
        build-system = old.build-system ++ [ pythonPackages.wheel ];
        env = old.env // {
          TORCH_CUDA_ARCH_LIST = "8.9";
        };
      });
in
{
  src = pkgs.fetchFromGitHub {
    owner = "vcruz305";
    repo = "tabbyAPI";
    rev = "880e6b8bbdeda83090eb6cb5eabdbf8623fc4426";
    hash = "sha256-GkDf2iqyiwFIEzE7CjLUri2EUuaRb4cVUJLBUo2hQ9Q=";
  };
  python = python.withPackages (ps: [
    exllamav3
    ps.aiofiles
    ps.aiohttp
    ps.async-lru
    ps.fastapi
    ps.httptools
    ps.huggingface-hub
    ps.jinja2
    ps.loguru
    ps.packaging
    ps.psutil
    ps.requests
    ps.ruamel-yaml
    ps.sse-starlette
    ps.uvicorn
    ps.uvloop
  ]);
}

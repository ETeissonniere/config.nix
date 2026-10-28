{ lib, pkgs, ... }:
{
  services.docling-serve = {
    enable = true;
    # Nixpkgs supplies websockets 17; the service still declares a <17 bound.
    package = (pkgs.docling-serve.override { withTesserocr = true; }).overridePythonAttrs (old: {
      pythonRelaxDeps = old.pythonRelaxDeps ++ [ "websockets" ];
    });
    environment = {
      DOCLING_DEVICE = "cpu";
      DOCLING_NUM_THREADS = "4";
      DOCLING_SERVE_ENG_LOC_NUM_WORKERS = "1";
      DOCLING_SERVE_MAX_SYNC_WAIT = "600";
      DOCLING_SERVE_LOAD_MODELS_AT_BOOT = "False";
      DOCLING_SERVE_ENABLE_UI = "False";
      TESSDATA_PREFIX = "${pkgs.tesseract}/share/tessdata";
      HF_HUB_DISABLE_TELEMETRY = "1";
    };
  };
  users.groups.docling-serve = { };
  users.users.docling-serve = {
    isSystemUser = true;
    group = "docling-serve";
  };
  systemd.services.docling-serve.serviceConfig = {
    # Keep the state directory at its persistent bind mount.
    DynamicUser = lib.mkForce false;
    User = "docling-serve";
    Group = "docling-serve";
    CPUQuota = "400%";
    MemoryMax = "8G";
    Restart = "on-failure";
    RestartSec = 5;
  };

  services.open-webui.managedSettings = {
    "rag.content_extraction_engine" = "docling";
    "rag.docling_server_url" = "http://127.0.0.1:5001";
    "rag.docling_params" = {
      do_ocr = true;
      ocr_preset = "tesserocr";
      do_table_structure = true;
    };
  };
  systemd.services.open-webui = {
    wants = [ "docling-serve.service" ];
    after = [ "docling-serve.service" ];
  };
}

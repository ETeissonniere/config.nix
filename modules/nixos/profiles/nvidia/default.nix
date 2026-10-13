{
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware = {
    nvidia = {
      open = true;
      modesetting.enable = true;
      nvidiaSettings = false;
    };
    nvidia-container-toolkit.enable = true;
  };
}

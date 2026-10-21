# How to set up this project
1. Copy the pynq-z1 file into your Vivado installation. It should be in \<VivadoInstallationDirectory\>/data/xhub/boards/XilinxBoardStore/boards/Xilinx.
2. Open Vivado and don't open a project! Instead, go to Tools->Run TCL-script and run regenerate_projects.tcl. Give it a couple of minutes, and then three projects should appear in Vivado.
3. RSA_soc shouldn't be touched. RSA_accelerator contains the logic which communicates with the outside world. Exponentiation contains the math.

# zynq_sha256

IP Core of SHA256 algorithm, support AXI4-Lite, AXI4-Full, AXI4-Stream interface.
* Test passed with ZYNQ7020@120MHz - DMA and AXI-Stream mode
* Test passed with KINTEX325t@125MHz - PCIE2.0x2 mode

## FOR ZYNQ
### Block diagram
![zynq](bench/zynq_linux_driver/zynq_sha256_block.png)

### Test
![bench](bench/zynq_linux_driver/bench.png)

## FOR KINTEX WITH PCIE

### Block diagram
![pcie](bench/pcie_linux_driver/pcie_sha256_block.png)

### Test (platform: intel i5-10400, **page aligned memory required!**)
![bench](bench/pcie_linux_driver/bench.png)


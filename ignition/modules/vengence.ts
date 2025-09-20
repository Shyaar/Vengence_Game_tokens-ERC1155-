import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("Vengencemodule", (m) => {

  const Vengence = m.contract("Vengence");


  m.call(Vengence, "mint", [2, 1n, "ipfs://QmaZeqnzihdSPSKkrDufPoBW3QVuYvSC6a5NCi9eVK5jhr"],{ id: "mintBatman" });
  


  return { Vengence };
});

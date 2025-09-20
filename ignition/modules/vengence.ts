import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("Vengencemodule", (m) => {

  const Vengence = m.contract("Vengence");



  return { Vengence };
});

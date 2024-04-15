/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Interface, type ContractRunner } from "ethers";
import type {
  IEddsaValidationModule,
  IEddsaValidationModuleInterface,
} from "../../../contracts/AccessRegistry.sol/IEddsaValidationModule";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "smartAccount",
        type: "address",
      },
    ],
    name: "getEddsaVirtualAddress",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;

export class IEddsaValidationModule__factory {
  static readonly abi = _abi;
  static createInterface(): IEddsaValidationModuleInterface {
    return new Interface(_abi) as IEddsaValidationModuleInterface;
  }
  static connect(
    address: string,
    runner?: ContractRunner | null
  ): IEddsaValidationModule {
    return new Contract(
      address,
      _abi,
      runner
    ) as unknown as IEddsaValidationModule;
  }
}

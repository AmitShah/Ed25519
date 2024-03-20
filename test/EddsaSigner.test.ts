import { Provider, TransactionRequest, BlockTag, TransactionResponse, FeeData } from "@ethersproject/abstract-provider";
import { Signer } from "@ethersproject/abstract-signer";
import { Bytes } from "@ethersproject/bytes";
import { Deferrable } from "@ethersproject/properties";

export class EddsaSigner extends Signer{
    provider?: Provider | undefined;
    getAddress(): Promise<string> {
        throw new Error("Method not implemented.");
    }
    signMessage(message: string | Bytes): Promise<string> {
        throw new Error("Method not implemented.");
    }
    signTransaction(transaction: Deferrable<TransactionRequest>): Promise<string> {
        throw new Error("Method not implemented.");
    }
    connect(provider: Provider): Signer {
        throw new Error("Method not implemented.");
    }
   
    getTransactionCount(blockTag?: BlockTag): Promise<number> {
        throw new Error("Method not implemented.");
    }
    call(transaction: Deferrable<TransactionRequest>, blockTag?: BlockTag): Promise<string> {
        throw new Error("Method not implemented.");
    }
    sendTransaction(transaction: Deferrable<TransactionRequest>): Promise<TransactionResponse> {
        throw new Error("Method not implemented.");
    }
    getChainId(): Promise<number> {
        throw new Error("Method not implemented.");
    }
    getFeeData(): Promise<FeeData> {
        throw new Error("Method not implemented.");
    }
    resolveName(name: string): Promise<string> {
        throw new Error("Method not implemented.");
    }
    checkTransaction(transaction: Deferrable<TransactionRequest>): Deferrable<TransactionRequest> {
        throw new Error("Method not implemented.");
    }
    populateTransaction(transaction: Deferrable<TransactionRequest>): Promise<TransactionRequest> {
        throw new Error("Method not implemented.");
    }
    _checkProvider(operation?: string): void {
        throw new Error("Method not implemented.");
    }
    
}